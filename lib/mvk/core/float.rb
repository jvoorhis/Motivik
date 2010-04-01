require 'mvk/core/floating'

module MVK
  module Core
    
    class Float < Floating
      def Float.type
        :float
      end
      
      def Float.type
        :float
      end
      
      def Float.literal(val)
        FloatLit.new(val)
      end
      
      def Float.data(data)
        FloatData.new(data)
      end
      
      def Float.apply(proto, args)
        FloatPrimitive.new(proto, args)
      end
      
      def apply(proto, args)
        Float.apply(proto, args)
      end
    end
    
    def Float(val)
      Float.literal(0).coerce(val)[0]
    end
    
    class FloatLit < Float
      def initialize(value)
        @value = value.to_f
      end
      
      def compile(context)
        LLVM::Float(@value)
      end
    end
    
    class FloatData < Float
      def initialize(data)
        @data = data
      end
      
      def compile(context)
        @data
      end
    end
    
    class FloatPrimitive < Float
      def initialize(proto, args)
        @proto = proto
        @args = args.map { |arg|
          Float === arg ? arg : MVK::Core::Float(arg)
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
    
    define_primitive :+, [:float, :float], :float do |c, lhs, rhs|
      c.builder.fadd(lhs.compile(c), rhs.compile(c))
    end
    
    define_primitive :-, [:float, :float], :float do |c, lhs, rhs|
      c.builder.fadd(lhs.compile(c), rhs.compile(c))
    end
    
    define_primitive :-@, [:float], :float do |c, arg|
      c.builder.fsub(LLVM::Float(0), arg.compile(c))
    end
    
    define_primitive :*, [:float], :float do |c, lhs, rhs|
      c.builder.fmul(lhs.compile(c), rhs.compile(c))
    end
    
    define_primitive :/, [:float], :float do |c, lhs, rhs|
      c.builder.fdiv(lhs.compile(c), rhs.compile(c))
    end
    
    define_primitive :%, [:float], :float do |c, lhs, rhs|
      c.builder.call(c.module.functions[:fmodf], lhs.compile(c), rhs.compile(c))
    end
    
    define_primitive :**, [:float], :float do |c, lhs, rhs|
      c.builder.call(c.module.functions[:powf])
    end
    
    define_primitive :sin, [:float], :float do |c, arg|
      c.builder.call(c.module.functions[:sinf], arg.compile(c))
    end
    
    define_primitive :cos, [:float], :float do |c, arg|
      c.builder.call(c.module.functions[:cosf], arg.compile(c))
    end
    
    define_primitive :tan, [:float], :float do |c, arg|
      c.builder.call(c.module.functions[:tanf], arg.compile(c))
    end
  end
end
