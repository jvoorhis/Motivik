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
        Application.new(proto, args)
      end
      
      def coerce(val)
        case val
        when type then [val, self]
        else [type.const(val), self]
        end
      end
      
      include Primitive
      
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
        Float.apply(
          Prototype.new(:to_float, [type], Float),
          [self]
        )
      end
      
      def to_double
        Double.apply(
          Prototype.new(:to_double, [type], Double),
          [self]
        )
      end
      
      def upto(upper_bound)
        Action.new { |context|
          initial_value = compile(context)
          bound = upper_bound.compile(context)
          body = context.function.basic_blocks.append("body")
          exit = context.function.basic_blocks.append("exit")
          
          induction_var = context.builder.alloca(LLVM::Int)
          context.builder.store(initial_value, induction_var)
          context.builder.br(body)
          
          context.builder.position_at_end(body)
          induction_value = context.builder.load(induction_var)
          yield(Core::Int.data(induction_value)).compile(context)
          induction_value = context.builder.add(LLVM::Int(1), induction_value)
          context.builder.store(induction_value, induction_var)
          continue = context.builder.icmp(:slt, induction_value, bound)
          context.builder.cond(continue, body, exit)
          context.builder.position_at_end(exit)
          nil
        }
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
      
      class Application < MVK::Application
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
