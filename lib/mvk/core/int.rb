require 'mvk/core/expression'

module MVK
  module Core
    
    # Signed, native integers
    module Int
      def type
        Int
      end
      module_function :type
      
      def target_type
        LLVM::Int.type
      end
      module_function :target_type
      
      def Int.const(val)
        Const.new(val)
      end
      
      def Int.data(data)
        Data.new(data)
      end
      
      def Int.apply(proto, args)
        Primitive.new(proto, args)
      end
      
      def coerce(val)
        case val
        when type then [val, self]
        else [type.const(val), self]
        end
      end
      
      def +(rhs)
        Int.apply(Prototype.new(:+, [type, type], type), [self, rhs])
      end
      
      def -(rhs)
        Int.apply(Prototype.new(:-, [type, type], type), [self, rhs])
      end
      
      def -@(rhs)
        Int.apply(Prototype.new(:-@, [type], type), [self, rhs])
      end
      
      def *(rhs)
        Int.apply(Prototype.new(:*, [type, type], type), [self, rhs])
      end
      
      def /(rhs)
        Int.apply(Prototype.new(:/, [type, type], type), [self, rhs])
      end
      
      def to_float
        MVK::Core::Float.apply(
          Prototype.new(:to_float, [type], MVK::Core::Float),
          [self]
        )
      end
      
      def to_double
        MVK::Core::Double.apply(
          Prototype.new(:to_double, [type], MVK::Core::Double),
          [self]
        )
      end
      
      class Const
        include Int
        
        def initialize(value)
          @value = value.to_i
        end
        
        def compile(context)
          LLVM::Int(@value)
        end
      end
      
      class Data < MVK::Data
        include Int
      end
      
      class Cond < MVK::Cond
        include Int
      end
      
      class Primitive < MVK::Primitive
        include Int
      end
    end
    
    op :+, [Int, Int], Int do |lhs, rhs|
      builder.add(lhs, rhs)
    end
    
    op :-, [Int, Int], Int do |lhs, rhs|
      builder.sub(lhs, rhs)
    end
    
    op :-@, [Int], Int do |arg|
      builder.sub(LLVM::Int(0), arg)
    end
    
    op :*, [Int, Int], Int do |lhs, rhs|
      builder.mul(lhs, rhs)
    end
    
    op :/, [Int, Int], Int do |lhs, rhs|
      builder.sdiv(lhs, rhs)
    end
    
    op :to_double, [Int], Double do |arg|
      builder.si2fp(arg, Core::Double.target_type)
    end
    
    op :to_float, [Int], Float do |arg|
      builder.si2fp(arg, Core::Float.target_type)
    end
  end
end
