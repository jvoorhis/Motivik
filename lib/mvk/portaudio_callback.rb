require 'mvk/signal'
require 'mvk/core'

require 'llvm/core'
require 'llvm/execution_engine'
require 'llvm/transforms/scalar'
require 'mvk/module_factory'

module MVK
  class PortAudioCallback
    attr_reader :sample_rate, :sample_format
    
    def initialize(dsp, options = {})
      @sample_rate = options[:sample_rate]
      @sample_format = :float32
      @module = options.fetch(:module) { ModuleFactory.build }
      @execution_engine = options.fetch(:execution_engine) do
        provider = LLVM::ModuleProvider.for_existing_module(@module)
        LLVM::ExecutionEngine.create_jit_compiler(provider)
      end
      compile_callback!(dsp)
      verify!
      optimize!
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
    
    private
      def compile_callback!(outs)
        @function = @module.functions.add(
          "mvk_portaudio_callback",
          @module.types[:pa_stream_callback]
        ) do |cback, input, output, frame_count, time_info, status_flags, user_data|
          builder = LLVM::Builder.create
          context = Core::CompilationContext.new(@module, cback, builder)
          entry   = cback.basic_blocks.append("entry")
          
          builder.position_at_end(entry)
          phase_ptr    = builder.struct_gep(user_data, 0)
          phase        = Core::Int.data(builder.load(phase_ptr))
          buffer       = Core::Int.data(builder.ptr2int(output, LLVM::Int))
          sample_width = 4
          frame_width  = sample_width * outs.size
          Core::Action.step(Core::Int.data(frame_count)) { |frame|
            time = (phase + frame).to_double / sample_rate
            outs.map.with_index { |sig, channel|
              expr            = sig.call(time).to_float
              sample_index    = channel * sample_width + frame * frame_width
              sample_location = buffer + sample_index
              Core::Action.store(expr, sample_location, LLVM::Float)
            }.reduce(:seq)
          }.compile(context)
          next_phase = builder.add(phase.compile(context), frame_count)
          builder.store(next_phase, phase_ptr)
          builder.ret(LLVM::Int(0))
        end
      end
      
      def verify!
        @module.verify!
      end
      
      def optimize!
        # Pass selection is a black art. Provisional passes are modelled after Rubinius.
        # See http://github.com/evanphx/rubinius/blob/master/vm/llvm/jit.cpp#L466
        LLVM::PassManager.new(@execution_engine) do |pass|
          pass << :mem2reg <<
                  :instcombine <<
                  :reassociate <<
                  :gvn <<
                  :dse <<
                  :instcombine <<
                  :simplifycfg <<
                  :gvn <<
                  :dse <<
                  :scalarrepl <<
                  :simplifycfg <<
                  :instcombine <<
                  :simplifycfg <<
                  :dse <<
                  :simplifycfg <<
                  :instcombine
          pass.run(@module)
        end
      end
  end # PortAudioCallback
end # MVK
