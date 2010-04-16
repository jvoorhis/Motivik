module MVK
  module Core
    module Storable
      def poke(addr_expr)
        Action.new { |context|
          value = compile(context)
          addr_int = addr_expr.compile(context)
          addr = context.builder.int2ptr(addr_int, LLVM::Pointer(type.target_type))
          context.builder.store(value, addr)
          nil
        }
      end
    end
  end
end
