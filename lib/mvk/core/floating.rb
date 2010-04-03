module MVK
  module Core
    
    # Defines the public interface to floating point expressions
    module Floating
      def sin
        type.apply(Prototype.new(:sin, [type], type), [self])
      end
      
      def cos
        type.apply(Prototype.new(:cos, [type], type), [self])
      end
      
      def tan
        type.apply(Prototype.new(:tan, [type], type), [self])
      end
      
      def coerce(val)
        case val
        when type then [val, self]
        else [type.const(val), self]
        end
      end
      
      def -@
        type.apply(Prototype.new(:-@, [type], type), [self])
      end
      
      def +(rhs)
        type.apply(Prototype.new(:+, [type, type], type), [self, rhs])
      end
      
      def -(rhs)
        type.apply(Prototype.new(:-, [type, type], type), [self, rhs])
      end
      
      def *(rhs)
        type.apply(Prototype.new(:*, [type, type], type), [self, rhs])
      end
      
      def /(rhs)
        type.apply(Prototype.new(:/, [type, type], type), [self, rhs])
      end
      
      def %(rhs)
        type.apply(Prototype.new(:%, [type, type], type), [self, rhs])
      end
      
      def **(rhs)
        type.apply(Prototype.new(:**, [type, type], type), [self, rhs])
      end
    end
  end
end
