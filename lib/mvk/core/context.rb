module MVK
  module Core
    class CompilationContext < Struct.new(:module, :function, :builder)
    end
  end
end
