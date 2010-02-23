module MVK
  module Core
    CompilationContext = Struct.new(:module, :function, :builder, :insns)
    
    module FloatingExpr
      def FloatingExpr.const(val)
        FloatingConst.new(val)
      end
      
      def coerce(val)
        case val
          when FloatingExpr then [val, self]
          else [FloatingExpr.const(val), self]
        end
      end
      
      def -@
        FloatingPrimitive.new(:-@, 1, [self])
      end
      
      def +(rhs)
        FloatingPrimitive.new(:+, 2, [self, rhs])
      end
      
      def -(rhs)
        FloatingPrimitive.new(:-, 2, [self, rhs])
      end
      
      def *(rhs)
        FloatingPrimitive.new(:*, 2, [self, rhs])
      end
      
      def /(rhs)
        FloatingPrimitive.new(:/, 2, [self, rhs])
      end
      
      def %(rhs)
        FloatingPrimitive.new(:%, 2, [self, rhs])
      end
      
      def **(rhs)
        FloatingPrimitive.new(:**, 2, [self, rhs])
      end
    end
    
    def FloatingExpr(expr)
      FloatingExpr.const(0).coerce(expr)[0]
    end
    module_function :FloatingExpr
    
    class FloatingData < Struct.new(:data)
      include FloatingExpr
      
      def compile(context)
        [data, context]
      end
    end
    
    class FloatingConst < Struct.new(:value)
      include FloatingExpr
      
      def initialize(n)
        super n.to_f
      end
      
      def compile(context)
        defn = context.insns[self] ||= LLVM::Double(value)
        [defn, context]
      end
    end
    
    class FloatingPrimitive < Struct.new(:name, :arity, :parameters)
      include FloatingExpr
      
      def initialize(name, arity, parameters)
        super name, arity, parameters.map { |p| Core::FloatingExpr(p) }
      end
      
      def compile(context)
        defn = context.insns[self] ||= case [name, arity]
          when [:-@, 1]
            context.builder.neg(
              parameters[0].compile(context)[0])
          when [:+, 2]
            context.builder.fadd(
              parameters[0].compile(context)[0],
              parameters[1].compile(context)[0])
          when [:-, 2]
            context.builder.fsub(
              parameters[0].compile(context)[0],
              parameters[1].compile(context)[0])
          when [:*, 2]
            context.builder.fmul(
              parameters[0].compile(context)[0],
              parameters[1].compile(context)[0])
          when [:/, 2]
            context.builder.fdiv(
              parameters[0].compile(context)[0],
              parameters[1].compile(context)[0])
          when [:%, 2]
            context.builder.call(
              context.module.functions[:fmod],
              parameters[0].compile(context)[0],
              parameters[1].compile(context)[0])
          when [:**, 2]
            context.builder.call(
              context.module.functions[:pow],
              parameters[0].compile(context)[0],
              parameters[1].compile(context)[0])
          when [:sin, 1]
            context.builder.call(
              context.module.functions[:sin],
              parameters[0].compile(context)[0])
          when [:cos, 1]
            context.builder.call(
              context.module.functions[:cos],
              parameters[0].compile(context)[0])
          when [:tan, 1]
            context.builder.call(
              context.module.functions[:tan],
              parameters[0].compile(context)[0])
          else
            raise NameError, "#{name}/#{arity} is undefined"
        end
        
        [defn, context]
      end
    end
    
    module Action
      def seq(rhs)
        Seq.new(self, rhs)
      end
    end
    
    class Seq < Struct.new(:lhs, :rhs)
      include Action
      
      def compile(context)
        context_ = lhs.compile(context)[1]
        rhs.compile(context_)
      end
    end
    
    class StoreSample < Struct.new(:floating_expr, :buffer, :frame, :channel, :channel_count)
      include Action
      
      def compile(context)
        sample64     = floating_expr.compile(context)[0]
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
        defn         = context.builder.store(
                         sample32,
                         context.builder.int2ptr(
                           context.builder.add(
                             context.builder.ptr2int(
                               buffer,
                               LLVM::Int),
                             sample_index),
                           LLVM::Pointer(LLVM::Float)))
        [defn, context]
      end
    end
  end # Core
end # MVK
