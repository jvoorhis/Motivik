module MVK
  module Core
    
    class Action
      def initialize(&compile_proc)
        @compile_proc = compile_proc
      end
      
      def compile(context)
        @compile_proc.call(context)
      end
      
      def seq(rhs)
        self.class.new { |context|
          self.call(context)
          rhs.call(context)
        }
      end
      
      def self.store_sample(floating_expr, buffer, frame, channel, channel_count)
        new { |context|
          sampled      = floating_expr.compile(context)
          samplef      = context.builder.fp_trunc(sampled, LLVM::Float)
          sample_width = LLVM::Int(4)
          frame_width  = context.builder.mul(sample_width, LLVM::Int(channel_count))
          sample_index = context.builder.add(
                           context.builder.mul(LLVM::Int(channel), sample_width),
                           context.builder.mul(frame, frame_width))
          context.builder.store(
            samplef,
            context.builder.int2ptr(
              context.builder.add(
                context.builder.ptr2int(buffer, LLVM::Int),
                sample_index),
              LLVM::Pointer(LLVM::Float)))
        }
      end
    end
  end
end
