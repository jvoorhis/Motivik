module MVK
  module Core
    class Action
      def initialize(&compile_proc)
        @compile_proc = compile_proc
      end
      
      def compile(context)
        @compile_proc.call(context)
      end
      
      def bind
        Action.new { |context|
          val = self.compile(context)
          yield(val).compile(context)
        }
      end
      
      def seq(rhs)
        bind { rhs }
      end
    end
  end
end
