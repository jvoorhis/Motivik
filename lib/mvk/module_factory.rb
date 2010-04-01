require 'llvm/core'

module MVK
  class ModuleFactory
    TYPES = {
      sample: LLVM::Double,
      
      callback_state: LLVM::Struct(LLVM::Int),
      
      pa_stream_callback: -> types {
        LLVM::Function(
          [LLVM::Pointer(LLVM::Float),           # input
           LLVM::Pointer(LLVM::Float),           # output
           LLVM::Int,                            # frame count
           LLVM::Pointer(LLVM::Int8),            # time info
           LLVM::Int,                            # status flags
           LLVM::Pointer(types[:callback_state]) # user data
          ],
          LLVM::Int)                             # stream callback result
      }
    }
    
    EXTERN_FUNCTIONS = {
      fmod: [[LLVM::Double, LLVM::Double], LLVM::Double],
      fmodf: [[LLVM::Double, LLVM::Double], LLVM::Double],
      pow: [[LLVM::Double, LLVM::Double], LLVM::Double],
      powf: [[LLVM::Double, LLVM::Double], LLVM::Double],
      sin: [[LLVM::Double], LLVM::Double],
      sinf: [[LLVM::Double], LLVM::Double],
      cos: [[LLVM::Double], LLVM::Double],
      cosf: [[LLVM::Double], LLVM::Double],
      tan: [[LLVM::Double], LLVM::Double],
      tanf: [[LLVM::Double], LLVM::Double],
    }
    
    def self.build
      new.build
    end
    
    def build
      mod = LLVM::Module.create("MVK")
      declare_types!(mod)
      declare_functions!(mod)
      mod
    end
    
    private
      def declare_types!(mod)
        TYPES.each do |name, type|
          mod.types[name] = case type
            when Proc then type.call(mod.types)
            else type
          end
        end
      end
      
      def declare_functions!(mod)
        EXTERN_FUNCTIONS.each do |name, (argtypes, rettype)|
          mod.functions.add(name, argtypes, rettype)
        end
      end
  end
end
