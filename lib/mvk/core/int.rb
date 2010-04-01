module MVK
  module Core
    
    # Signed, native integers
    class Int
      def Int.literal(val)
        IntLit.new(val)
      end
      
      def type
        :int
      end
      
      def coerce(val)
        case val
        when Int then [val, self]
        else [Int.literal(val), self]
        end
      end
      
      def +(rhs)
        apply(Prototype.new(:+, [type, type], type), [self, rhs])
      end
      
      def -(rhs)
        apply(Prototype.new(:-, [type, type], type), [self, rhs])
      end
      
      def -@(rhs)
        apply(Prototype.new(:-@, [type], type), [self, rhs])
      end
      
      def *(rhs)
        apply(Prototype.new(:*, [type, type], type), [self, rhs])
      end
      
      def /(rhs)
        apply(Prototype.new(:/, [type, type], type), [self, rhs])
      end
    end
    
    def Int(val)
      Int.literal(0).coerce(val)[0]
    end
    module_function :Int
    
    class ConstInt < Int
      def initialize(val)
        @value = val.to_i
      end
      
      def compile(context)
        LLVM::Int(@value)
      end
    end
    
    class IntData < Int
      def initialize(data)
        @data = data
      end
      
      def compile(context)
        @data
      end
    end
    
    class IntPrimitive < Int
      def initialize(proto, args)
        @proto = proto
        @args = args.map { |arg|
          Int === arg ? arg : MVK::Core::Int(arg)
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
    
    define_primitive :+, [:int, :int], :int do |c, lhs, rhs|
      c.builder.add(lhs.compile(c), rhs.compile(c))
    end
    
    define_primitive :-, [:int, :int], :int do |c, lhs, rhs|
      c.builder.sub(lhs.compile(c), rhs.compile(c))
    end
    
    define_primitive :-@, [:int], :int do |c, arg|
      c.builder.sub(LLVM::Int(0), arg.compile(c))
    end
    
    define_primitive :*, [:int, :int], :int do |c, lhs, rhs|
      c.builder.mul(lhs.compile(c), rhs.compile(c))
    end
    
    define_primitive :/, [:int, :int], :int do |c, lhs, rhs|
      c.builder.sdiv(lhs.compile(c), rhs.compile(c))
    end
  end
end
