module MVK
  module Core
    
    module Bool
      def type
        Bool
      end
      module_function :type
      
      def target_type
        LLVM::Int1.type
      end
      module_function :target_type
      
      def Bool.const(value)
        Const.new(value)
      end
      
      def Bool.true
        const(1)
      end
      
      def Bool.false
        const(0)
      end
      
      def Bool.data(data)
        Data.new(data)
      end
      
      def Bool.apply(proto, args)
        Application.new(proto, args)
      end
      
      def coerce(value)
        case value
        when Bool then [value, self]
        else [Bool.const(value), self]
        end
      end
      
      include Primitive
      include Storable
      
      def and(rhs)
        type.apply(Prototype.new(:and, [type, type], type), [self, rhs])
      end
      
      def or(rhs)
        type.apply(Prototype.new(:or, [type, type], type), [self, rhs])
      end
      
      def xor(rhs)
        type.apply(Prototype.new(:xor, [type, type], type), [self, rhs])
      end
      
      def not
        type.apply(Prototype.new(:xor, [type], type), [self])
      end
      
      class Const
        include Bool
        
        def initialize(value)
          @value = case value
                   when 0, false, nil then 0
                   else 1
                   end
        end
        
        def compile(context)
          LLVM::Int1.from_i(@value)
        end
      end
      
      class Data < MVK::Data
        include Bool
      end
      
      class Cond < MVK::Cond
        include Bool
      end
      
      class Application < MVK::Application
        include Bool
      end
    end
    
    op :and, [Bool, Bool], Bool do |lhs, rhs|
      builder.and(lhs, rhs)
    end
    
    op :or, [Bool, Bool], Bool do |lhs, rhs|
      builder.or(lhs, rhs)
    end
    
    op :xor, [Bool, Bool], Bool do |lhs, rhs|
      builder.xor(lhs, rhs)
    end
    
    op :not, [Bool], Bool do |arg|
      builder.not(arg)
    end
  end
end
