module MVK
  module Core
    
    # Defines the public interface to floating point expressions
    module FloatingExpr
      def self.const(val)
        FloatingConst.new(val)
      end
      
      def self.sin(x)
        FloatingApplication.new(
          FloatingPrimitive.new(:sin, [:float]),
          [x]
        )
      end
      
      def self.cos(x)
        FloatingApplication.new(
          FloatingPrimitive.new(:cos, [:float]),
          [x]
        )
      end
      
      def self.tan(x)
        FloatingApplication.new(
          FloatingPrimitive.new(:tan, [:float]),
          [x]
        )
      end
      
      def type
        :float
      end
      
      def coerce(val)
        case val
        when FloatingExpr then [val, self]
        else [FloatingExpr.const(val), self]
        end
      end
      
      def -@
        FloatingApplication.new(
          FloatingPrimitive.new(:-@, [:float]),
          [self]
        )
      end
      
      def +(rhs)
        FloatingApplication.new(
          FloatingPrimitive.new(:+, [:float, :float]),
          [self, rhs]
        )
      end
      
      def -(rhs)
        FloatingApplication.new(
          FloatingPrimitive.new(:-, [:float, :float]),
          [self, rhs]
        )
      end
      
      def *(rhs)
        FloatingApplication.new(
          FloatingPrimitive.new(:*, [:float, :float]),
          [self, rhs]
        )
      end
      
      def /(rhs)
        FloatingApplication.new(
          FloatingPrimitive.new(:/, [:float, :float]),
          [self, rhs]
        )
      end
      
      def %(rhs)
        FloatingApplication.new(
          FloatingPrimitive.new(:fmod, [:float, :float]),
          [self, rhs]
        )
      end
      
      def **(rhs)
        FloatingApplication.new(
          FloatingPrimitive.new(:pow, [:float, :float]),
          [self, rhs]
        )
      end
    end
    
    # Coerce a value to be a FloatingExpr. Interface is analagous to Kernel#Array.
    def FloatingExpr(expr)
      FloatingExpr.const(0).coerce(expr)[0]
    end
    module_function :FloatingExpr
    
    # A floating value containing opaque data
    class FloatingData < Struct.new(:data)
      include FloatingExpr
      
      def compile(context)
        data
      end
    end
    
    # A literal floating point constant
    class FloatingConst < Struct.new(:value)
      include FloatingExpr
      
      def initialize(n)
        super n.to_f
      end
      
      def compile(context)
        LLVM::Double(value)
      end
    end
    
    # An application of a function yielding a floating point value
    class FloatingApplication < Struct.new(:function, :args)
      include FloatingExpr
      
      def compile(context)
        Core.coercing(function.arg_types.zip(args)) do |args|
          function.apply(
            context,
            args.map { |arg| arg.compile(context) }
          )
        end
      end
    end
    
    # A function yielding a floating point value
    class FloatingPrimitive < Struct.new(:name, :arg_types)
      def apply(context, args)
        case name
        when :-@
          context.builder.neg(*args)
        when :+
          context.builder.fadd(*args)
        when :-
          context.builder.fsub(*args)
        when :*
          context.builder.fmul(*args)
        when :/
          context.builder.fdiv(*args)
        else
          if function = context.module.functions[name]
            context.builder.call(function, *args)
          else
            raise "Undefined function #{name}"
          end
        end
      end
    end
  end
end
