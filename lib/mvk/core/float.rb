require 'mvk/core/floating'

module MVK
  module Core
    
    class Float < Floating
      def self.literal(val)
        FloatLit.new(val)
      end
      
      def self.data(data)
        FloatData.new(data)
      end
      
      def self.type
        :float
      end
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
      def initialize(prototype, args)
        unless prototype.arg_types == args.map(&:type)
          raise TypeError, "#{args} does not satisfy #{prototype}."
        end
        
        @prototype = prototype
        @args = @args
      end
      
      def compile(context)
        case @prototype
        when Prototype.new(:sin, [:float], :float)
          context.builder.call(
            context.module.functions[:sinf],
            @args[0].compile(context))
        when Prototype.new(:cos, [:float], :float)
          context.builder.call(
            context.module.functions[:cosf],
            @args[0].compile(context))
        when Prototype.new(:tan, [:float], :float)
          context.builder.call(
            context.module.functions[:tanf],
            @args[0].compile(context))
        when Prototype.new(:-@, [:float], :float)
          context.builder.fneg(
            @args[0].compile(context))
        when Prototype.new(:+, [:float, :float], :float)
          context.builder.fadd(
            @args[0].compile(context),
            @args[1].compile(context))
        when Prototype.new(:-, [:float, :float], :float)
          context.builder.fsub(
            @args[0].compile(context),
            @args[1].compile(context))
        when Prototype.new(:*, [:float, :float], :float)
          context.builder.fmul(
            @args[0].compile(context),
            @args[1].compile(context))
        when Prototype.new(:/, [:float, :float], :float)
          context.builder.fdiv(
            @args[0].compile(context),
            @args[1].compile(context))
        when Prototype.new(:%, [:float, :float], :float)
          context.builder.fmod(
            @args[0].compile(context),
            @args[1].compile(context))
        when Prototype.new(:**, [:float, :float], :float)
          context.builder.call(
            context.module.functions[:pow],
            @args[0].compile(context),
            @args[1].compile(context))
        end
      end
    end
  end
end
