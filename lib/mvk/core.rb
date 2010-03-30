require 'mvk/core/prototype'
require 'mvk/core/double'
require 'mvk/core/action'

module MVK
  module Core
    CompilationContext = Struct.new(:module, :function, :builder)
  end
end
