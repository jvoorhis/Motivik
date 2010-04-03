module MVK
  
  class Data
    def initialize(data)
      @data = data
    end
    
    def compile(context)
      @data
    end
  end
  
  class Cond
    def initialize(condition, consequent, alternative)
      @condition   = condition
      @consequent  = consequent
      @alternative = alternative
    end
    
    def compile(context)
      consequent_block  = context.function.basic_blocks.append("consequent")
      alternative_block = context.function.basic_blocks.append("alternative")
      merge_block       = context.function.basic_blocks.append("merge")
      
      condition_value = context.builder.icmp(:eq, LLVM::Int1.from_i(1),
                                             @condition.compile(context))
      context.builder.cond(condition_value, consequent_block, alternative_block)
      
      context.builder.position_at_end(consequent_block)
      consequent_value = @consequent.compile(context)
      context.builder.br(merge_block)
      
      context.builder.position_at_end(alternative_block)
      alternative_value = @alternative.compile(context)
      context.builder.br(merge_block)
      
      context.builder.position_at_end(merge_block)
      context.builder.phi(target_type,
                          consequent_value, consequent_block,
                          alternative_value, alternative_block)
    end
  end
  
  class Primitive
    def initialize(proto, args)
      @proto = proto
      @args = args.zip(proto.arg_types).map { |(arg, type)|
        type === arg ? arg : type.const(arg)
      }
    end
    
    def compile(context)
      if op = Core.primitives[@proto]
        context.instance_exec(*@args.map { |arg| arg.compile(context) }, &op)
      else
        raise NotImplementedError, "#{@proto} is undefined."
      end
    end
  end
end
