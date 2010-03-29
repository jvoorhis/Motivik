module MVK
  module Core
    CompilationContext = Struct.new(:module, :function, :builder)
    
    # Takes a list of pairs of [type, any_value] to a list of 
    # values matching their given type.
    def coercing(arguments)
      yield arguments.map { |(type, expr)|
        case type
        when :float then Core::FloatingExpr(expr)
        else raise "Unknown type #{type}"
        end
      }
    end
    module_function :coercing
    
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
    
    # A side effecting action
    module Action
      def seq(rhs)
        Seq.new(self, rhs)
      end
    end
    
    # A compound action that executes its first action and then its second
    class Seq < Struct.new(:lhs, :rhs)
      include Action
      
      def compile(context)
        lhs.compile(context)
        rhs.compile(context)
      end
    end
    
    # Store a value in the sample buffer
    class StoreSample < Struct.new(:floating_expr, :buffer, :frame, :channel, :channel_count)
      include Action
      
      def compile(context)
        sample64     = floating_expr.compile(context)
        sample32     = context.builder.fp_trunc(
                         sample64,
                         LLVM::Float)
        sample_width = LLVM::Int(4)
        frame_width  = context.builder.mul(
                         sample_width,
                         LLVM::Int(channel_count))
        sample_index = context.builder.add(
                         context.builder.mul(
                           LLVM::Int(channel),
                           sample_width),
                         context.builder.mul(
                           frame,
                           frame_width))
        context.builder.store(
          sample32,
          context.builder.int2ptr(
            context.builder.add(
              context.builder.ptr2int(
                buffer,
                LLVM::Int),
              sample_index),
            LLVM::Pointer(LLVM::Float)))
      end
    end
  end # Core
end # MVK
