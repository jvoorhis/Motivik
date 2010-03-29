module MVK
  module Core
    
    # A side effecting action
    module Action
      def seq(rhs)
        Seq.new(self, rhs)
      end
    end
    
    # A compound action that executes its first action and then its second
    class Seq < Struct.new(:lhs, :rhs)
      include Action
      
      def compile(context)
        lhs.compile(context)
        rhs.compile(context)
      end
    end
    
    # Store a value in the sample buffer
    class StoreSample < Struct.new(:floating_expr, :buffer, :frame, :channel, :channel_count)
      include Action
      
      def compile(context)
        sample64     = floating_expr.compile(context)
        sample32     = context.builder.fp_trunc(
                         sample64,
                         LLVM::Float)
        sample_width = LLVM::Int(4)
        frame_width  = context.builder.mul(
                         sample_width,
                         LLVM::Int(channel_count))
        sample_index = context.builder.add(
                         context.builder.mul(
                           LLVM::Int(channel),
                           sample_width),
                         context.builder.mul(
                           frame,
                           frame_width))
        context.builder.store(
          sample32,
          context.builder.int2ptr(
            context.builder.add(
              context.builder.ptr2int(
                buffer,
                LLVM::Int),
              sample_index),
            LLVM::Pointer(LLVM::Float)))
      end
    end
  end
end
