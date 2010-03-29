require 'mvk/core/floating_expr'
require 'mvk/core/int_expr'
require 'mvk/core/action'

module MVK
  module Core
    CompilationContext = Struct.new(:module, :function, :builder)
    
    # Takes a list of pairs of [type, any_value] to a list of 
    # values matching their given type.
    def coercing(arguments)
      yield arguments.map { |(type, expr)|
        case type
        when :float then Core::FloatingExpr(expr)
        when :int then Core::IntExpr(expr)
        else raise "Unknown type #{type}"
        end
      }
    end
    module_function :coercing

  end
end
