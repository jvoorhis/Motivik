require 'mvk/core/floating'

module MVK
  module Core
    
    module Float
      def type
        Float
      end
      module_function :type
      
      def target_type
        LLVM::Float.type
      end
      module_function :target_type
      
      def Float.const(value)
        Const.new(value)
      end
      
      def Float.data(data)
        Data.new(data)
      end
      
      def Float.apply(proto, args)
        Application.new(proto, args)
      end
      
      include Primitive
      include Floating
      
      def to_float
        self
      end
      
      def to_double
        MVK::Core::Double.apply(
          Prototype.new(:to_double, [Float], Double),
          [self]
        )
      end
      
      class Const
        include Float
        
        def initialize(value)
          @value = value.to_f
        end
        
        def compile(context)
          LLVM::Float(@value)
        end
      end
      
      class Data < MVK::Data
        include Float
      end
      
      class Cond < MVK::Cond
        include Float
      end
      
      class Application < MVK::Application
        include Float
      end
    end
    
    op :+, [Float, Float], Float do |lhs, rhs|
      builder.fadd(lhs, rhs)
    end
    
    op :-, [Float, Float], Float do |lhs, rhs|
      builder.fadd(lhs, rhs)
    end
    
    op :-@, [Float], Float do |arg|
      builder.fsub(LLVM::Float(0), arg)
    end
    
    op :*, [Float], Float do |lhs, rhs|
      builder.fmul(lhs, rhs)
    end
    
    op :/, [Float], Float do |lhs, rhs|
      builder.fdiv(lhs, rhs)
    end
    
    op :%, [Float], Float do |lhs, rhs|
      builder.call(self.module.functions[:fmodf], lhs, rhs)
    end
    
    op :**, [Float], Float do |lhs, rhs|
      builder.call(self.module.functions[:powf])
    end
    
    op :sin, [Float], Float do |arg|
      builder.call(self.module.functions[:sinf], arg)
    end
    
    op :cos, [Float], Float do |arg|
      builder.call(self.module.functions[:cosf], arg)
    end
    
    op :tan, [Float], Float do |arg|
      builder.call(self.module.functions[:tanf], arg)
    end
    
    op :to_double, [Float], Double do |arg|
      builder.fp_ext(arg, Core::Double.target_type)
    end
  end
end
