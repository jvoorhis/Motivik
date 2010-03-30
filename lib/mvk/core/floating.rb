module MVK
  module Core
    
    # Defines the public interface to floating point expressions
    class Floating
      def self.sin(x)
        apply(Prototype.new(:sin, [type], type), [x])
      end
      
      def self.cos(x)
        apply(Prototype.new(:cos, [type], type), [x])
      end
      
      def self.tan(x)
        apply(Prototype.new(:tan, [type], type), [x])
      end
      
      def coerce(val)
        case val
        when self.class then [val, self]
        else [self.class.literal(val), self]
        end
      end
      
      def -@
        apply(Prototype.new(:-@, [type], type), [self])
      end
      
      def +(rhs)
        apply(Prototype.new(:+, [type, type], type), [self, rhs])
      end
      
      def -(rhs)
        apply(Prototype.new(:-, [type, type], type), [self, rhs])
      end
      
      def *(rhs)
        apply(Prototype.new(:*, [type, type], type), [self, rhs])
      end
      
      def /(rhs)
        apply(Prototype.new(:/, [type, type], type), [self, rhs])
      end
      
      def %(rhs)
        apply(Prototype.new(:%, [type, type], type), [self, rhs])
      end
      
      def **(rhs)
        apply(Prototype.new(:**, [type, type], type), [self, rhs])
      end
    end
  end
end
