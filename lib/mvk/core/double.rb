require 'mvk/core/floating'

module MVK
  module Core
    
    class Double < Floating
      def Double.type
        :double
      end
      
      def type
        Double.type
      end
      
      def Double.literal(val)
        DoubleLit.new(val)
      end
      
      def Double.data(data)
        DoubleData.new(data)
      end
      
      def Double.apply(proto, args)
        DoublePrimitive.new(proto, args)
      end
      
      def apply(proto, args)
        Double.apply(proto, args)
      end
    end
    
    def Double(val)
      Double.literal(0).coerce(val)[0]
    end
    module_function :Double
    
    class DoubleLit < Double
      def initialize(value)
        @value = value.to_f
      end
      
      def compile(context)
        LLVM::Double(@value)
      end
    end
    
    class DoubleData < Double
      def initialize(data)
        @data = data
      end
      
      def compile(context)
        @data
      end
    end
    
    class DoublePrimitive < Double
      def initialize(proto, args)
        @proto = proto
        @args = args.map { |arg|
          Double === arg ? arg : MVK::Core::Double(arg)
        }
      end
      
      def compile(context)
        if impl = Core.primitives[@proto]
          impl.call(context, *@args)
        else
          raise NotImplementedError, "#{@proto} is undefined."
        end
      end
    end
    
    define_primitive :+, [:double, :double], :double do |c, lhs, rhs|
      c.builder.fadd(lhs.compile(c), rhs.compile(c))
    end
    
    define_primitive :-, [:double, :double], :double do |c, lhs, rhs|
      c.builder.fsub(lhs.compile(c), rhs.compile(c))
    end
    
    define_primitive :-@, [:double], :double do |c, arg|
      c.builder.fsub(LLVM::Double(0), arg.compile(c))
    end
    
    define_primitive :*, [:double, :double], :double do |c, lhs, rhs|
      c.builder.fmul(lhs.compile(c), rhs.compile(c))
    end
    
    define_primitive :/, [:double, :double], :double do |c, lhs, rhs|
      c.builder.fdiv(lhs.compile(c), rhs.compile(c))
    end
    
    define_primitive :%, [:double, :double], :double do |c, lhs, rhs|
      c.builder.call(c.module.functions[:fmod], lhs.compile(c), rhs.compile(c))
    end
    
    define_primitive :**, [:double, :double], :double do |c, lhs, rhs|
      c.call(c.module.functions[:pow], lhs.compile(c), rhs.compile(c))
    end
    
    define_primitive :sin, [:double], :double do |c, arg|
      c.builder.call(c.module.functions[:sin], arg.compile(c))
    end
    
    define_primitive :cos, [:double], :double do |c, arg|
      c.builder.call(c.module.functions[:cos], arg.compile(c))
    end
    
    define_primitive :tan, [:double], :double do |c, arg|
      c.builder.call(c.module.functions[:tan], arg.compile(c))
    end
  end
end
