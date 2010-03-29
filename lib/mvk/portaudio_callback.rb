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
        LLVM::NATIVE_INT_SIZE/8, # *phase
        LLVM::NATIVE_INT_SIZE/8  # *score
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
          # Basic blocks
          entry = cback.basic_blocks.append("entry")
          loop  = cback.basic_blocks.append("loop")
          exit  = cback.basic_blocks.append("exit")
          
          # Locals
          phase_ptr = nil
          phase     = nil
          frame_ptr = nil # loop induction variable
          
          entry.build do |b|
            phase_ptr = b.struct_gep(user_data, 0)
            phase     = b.load(phase_ptr)
            frame_ptr = b.alloca(LLVM::Int)
            b.store(LLVM::Int(0), frame_ptr)
            b.br(loop)
          end
          
          loop.build do |b|
            frame  = b.load(frame_ptr)
            phase_ = b.add(phase, frame)
            now    = Core::FloatingData.new(
                       b.fdiv(
                         b.si2fp(phase_, LLVM::Double),
                         LLVM::Double(@sample_rate),
                         "now"))
            
            action = outs.map.with_index { |sig, channel|
              expr = sig.call(now) # sample signal at current time
              Core::Action.store_sample(expr, output, frame, channel, outs.size)
            }.reduce(:seq)
            
            context = Core::CompilationContext.new(@module, cback, b)
            action.call(context)
            
            b.store(
              b.add(frame, LLVM::Int(1)),
              frame_ptr)
            
            b.cond(
              b.icmp(:sgt, frame_count, frame),
              loop, exit)
          end
          
          exit.build do |b|
            b.store(
              b.add(phase, frame_count),
              phase_ptr)
            b.ret(LLVM::Int(0))
          end
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
