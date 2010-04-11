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
          self.compile(context)
          rhs.compile(context)
        }
      end
      
      def self.store(v_expr, l_expr, type)
        new { |context|
          value    = v_expr.compile(context)
          location = l_expr.compile(context)
          context.builder.store(
            value,
            context.builder.int2ptr(
              location,
              LLVM::Pointer(type)))
        }
      end
    end
  end
end
