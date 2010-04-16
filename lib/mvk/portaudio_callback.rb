require 'mvk/signal'
require 'mvk/core'

require 'llvm/core'
require 'llvm/execution_engine'
require 'llvm/transforms/scalar'
require 'mvk/module_factory'

module MVK
  class PortAudioCallback
    attr_reader :sample_rate, :sample_format
    
    def initialize(outs, options = {})
      @sample_rate = options[:sample_rate]
      @sample_format = :float32
      @module = options.fetch(:module) { ModuleFactory.build }
      @execution_engine = options.fetch(:execution_engine) do
        provider = LLVM::ModuleProvider.for_existing_module(@module)
        LLVM::ExecutionEngine.create_jit_compiler(provider)
      end
      @function = compile_callback!(@module, outs)
      @module.verify!
      @pass_manager = LLVM::PassManager.new(@execution_engine)
      passes.reduce(@pass_manager, :<<)
      @pass_manager.run(@module)
      @module.dump if options[:debug] || $DEBUG
    end
    
    def to_ptr
      @execution_engine.pointer_to_global(@function)
    end
    
    def alloc_user_data
      FFI::MemoryPointer.new(
        LLVM::NATIVE_INT_SIZE/8
      )
    end
    
    def write_initial_user_data(pointer)
      pointer.write_int(0)
    end
    
    def dispose
      @pass_manager.dispose
    end
    
    private
      def compile_callback!(mod, outs)
        @function = mod.functions.add(
          "mvk_portaudio_callback",
          mod.types[:pa_stream_callback]
        ) do |func, input, output, frame_count, time_info, status_flags, user_data|
          entry   = func.basic_blocks.append("entry")
          builder = LLVM::Builder.create.position_at_end(entry)
          context = Core::CompilationContext.new(mod, func, builder)
          
          phase_ptr   = builder.struct_gep(user_data, 0)
          phase_addr  = Core::Int.data(builder.ptr2int(phase_ptr, LLVM::Int))
          phase       = Core::Int.data(builder.load(phase_ptr))
          frame_count = Core::Int.data(frame_count)
          buffer      = Core::Int.data(builder.ptr2int(output, LLVM::Int))
          sample_size = Core::Int.const(4)
          frame_size  = sample_size * outs.size
          status      = Core::Int.const(0) # instruct PortAudio to continue 
          
          Core::Action.step(frame_count) { |frame|
            time = (phase + frame).to_double / self.sample_rate
            outs.map.with_index { |sig, channel|
              expr         = sig.call(time)
              sample_index = channel * sample_size + frame * frame_size
              sample_addr  = buffer + sample_index
              Core::Action.store(expr.to_float, sample_addr, Core::Float)
            }.reduce(:seq)
          }.seq(
            Core::Action.store(phase + frame_count, phase_addr, Core::Int)
          ).compile(context)
          
          builder.ret(status.compile(context))
        end
      end
      
      def passes
        [
         :mem2reg,
         :instcombine,
         :reassociate,
         :gvn,
         :dse,
         :instcombine,
         :simplifycfg,
         :gvn,
         :dse,
         :scalarrepl,
         :simplifycfg,
         :instcombine,
         :simplifycfg,
         :dse,
         :simplifycfg,
         :instcombine
        ]
      end
  end # PortAudioCallback
end # MVK
