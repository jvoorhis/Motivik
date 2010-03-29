module MVK
  module Core
    
    module IntExpr
      def self.const(val)
        ConstInt.new(val)
      end
      
      def type
        :int
      end
      
      def coerce(val)
        case val
        when IntExpr then [val, self]
        else [IntExpr.const(val), self]
        end
      end
    end
    
    def IntExpr(expr)
      IntExpr.const(0).coerce(expr)[0]
    end
    module_function :FloatingExpr      
    
    class ConstInt < Struct.new(:value)
      include IntExpr
      
      def initialize(val)
        super val.to_i
      end
    end
    
    class IntApplication < Struct.new(:function, :args)
      include IntExpr
    end
    
    class IntPrimitive < Struct.new(:name, :arg_types)
      include IntExpr
    end
  end
end
