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
      
      def self.store(value_expr, location_expr, type)
        new { |context|
          value        = value_expr.compile(context)
          location_int = location_expr.compile(context)
          location     = context.builder.int2ptr(location_int, LLVM::Pointer(type))
          context.builder.store(value, location)
        }
      end
      
      def self.step(bound_expr)
        new { |context|
          bound = bound_expr.compile(context)
          body  = context.function.basic_blocks.append("body")
          exit  = context.function.basic_blocks.append("exit")
          
          induction_var = context.builder.alloca(LLVM::Int)
          context.builder.store(LLVM::Int(0), induction_var)
          context.builder.br(body)
          
          context.builder.position_at_end(body)
          induction_val = context.builder.load(induction_var)
          yield(Core::Int.data(induction_val)).compile(context)
          induction_val = context.builder.add(LLVM::Int(1), induction_val)
          context.builder.store(induction_val, induction_var)
          continue = context.builder.icmp(:slt, induction_val, bound)
          context.builder.cond(continue, body, exit)
          context.builder.position_at_end(exit)
          nil
        }
      end
    end
  end
end
