require 'mvk/core/floating'

module MVK
  module Core
    
    module Double
      def type
        Double
      end
      module_function :type
      
      def target_type
        LLVM::Double.type
      end
      module_function :target_type
      
      def Double.const(value)
        Const.new(value)
      end
      
      def Double.data(data)
        Data.new(data)
      end
      
      def Double.apply(proto, args)
        Primitive.new(proto, args)
      end
      
      include Floating
      
      def to_f
        MVK::Core::Float.apply(
          Prototype.new(:to_f, [Double], Float),
          [self]
        )
      end
      
      class Const
        include Double
        
        def initialize(value)
          @value = value.to_f
        end
        
        def compile(context)
          LLVM::Double(@value)
        end
      end
      
      class Data < MVK::Data
        include Double
      end
      
      class Cond < MVK::Cond
        include Double
      end
      
      class Primitive < MVK::Primitive
        include Double
      end
    end
    
    op :+, [Double, Double], Double do |lhs, rhs|
      builder.fadd(lhs, rhs)
    end
    
    op :-, [Double, Double], Double do |lhs, rhs|
      builder.fsub(lhs, rhs)
    end
    
    op :-@, [Double], Double do |arg|
      builder.fsub(LLVM::Double(0), arg)
    end
    
    op :*, [Double, Double], Double do |lhs, rhs|
      builder.fmul(lhs, rhs)
    end
    
    op :/, [Double, Double], Double do |lhs, rhs|
      builder.fdiv(lhs, rhs)
    end
    
    op :%, [Double, Double], Double do |lhs, rhs|
      builder.call(self.module.functions[:fmod], lhs, rhs)
    end
    
    op :**, [Double, Double], Double do |lhs, rhs|
      builder.call(self.module.functions[:pow], lhs, rhs)
    end
    
    op :sin, [Double], Double do |arg|
      builder.call(self.module.functions[:sin], arg)
    end
    
    op :cos, [Double], Double do |arg|
      builder.call(self.module.functions[:cos], arg)
    end
    
    op :tan, [Double], Double do |arg|
      builder.call(self.module.functions[:tan], arg)
    end
    
    op :to_f, [Double], Float do |arg|
      builder.fp_trunc(arg, LLVM::Float)
    end
  end
end
