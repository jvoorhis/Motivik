module MVK
  module Core
    
    class Prototype
      attr_reader :name, :arg_types, :result_type
      
      def initialize(name, arg_types, result_type)
        @name = name
        @arg_types = arg_types
        @result_type = result_type
      end
      
      def ==(rhs)
        name == rhs.name &&
        arg_types == rhs.arg_types &&
        result_type == rhs.result_type
      end
      alias_method :eql?, :==
      
      def hash
        [name, arg_types, result_type].hash
      end
      
      def to_s
        "<#@name [#{@arg_types * ', '}] #@result_type>"
      end
    end
  end
end
