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
      
      def Double.apply(prototype, args)
        DoublePrimitive.new(prototype, args)
      end
      
      def apply(prototype, args)
        Double.apply(prototype, args)
      end
    end
    
    def Double(value)
      Double.literal(0).coerce(value)[0]
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
      def initialize(prototype, args)
        @prototype = prototype
        @args = args.map { |arg|
          Double === arg ? arg : MVK::Core::Double(arg)
        }
      end
      
      def compile(context)
        case @prototype
        when Prototype.new(:sin, [:double], :double)
          context.builder.call(
            context.module.functions[:sin],
            @args[0].compile(context))
        when Prototype.new(:cos, [:double], :double)
          context.builder.call(
            context.module.functions[:cos],
            @args[0].compile(context))
        when Prototype.new(:tan, [:double], :double)
          context.builder.call(
            context.module.functions[:tan],
            @args[0].compile(context))
        when Prototype.new(:-@, [:double], :double)
          context.builder.fneg(
            @args[0].compile(context))
        when Prototype.new(:+, [:double, :double], :double)
          context.builder.fadd(
            @args[0].compile(context),
            @args[1].compile(context))
        when Prototype.new(:-, [:double, :double], :double)
          context.builder.fsub(
            @args[0].compile(context),
            @args[1].compile(context))
        when Prototype.new(:*, [:double, :double], :double)
          context.builder.fmul(
            @args[0].compile(context),
            @args[1].compile(context))
        when Prototype.new(:/, [:double, :double], :double)
          context.builder.fdiv(
            @args[0].compile(context),
            @args[1].compile(context))
        when Prototype.new(:%, [:double, :double], :double)
          context.builder.fmod(
            @args[0].compile(context),
            @args[1].compile(context))
        when Prototype.new(:**, [:double, :double], :double)
          context.builder.call(
            context.module.functions[:pow],
            @args[0].compile(context),
            @args[1].compile(context))
        end
      end
    end
  end
end
