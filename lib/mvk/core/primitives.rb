module MVK
  module Core
    def Core.primitives
      @primitives ||= {}
    end
    
    def Core.define_primitive(name, arg_types, ret_type, &impl)
      Core.primitives[ Prototype.new(name, arg_types, ret_type) ] = impl
    end
  end
end
