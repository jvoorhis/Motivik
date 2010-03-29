module MVK

  class Signal
    def self.const(val)
      new { |t| val }
    end
    
    def const(val)
      self.class.const(val)
    end
    
    def self.lift(*args, &f)
      new { |t|
        f.call(*args.map { |arg|
          FloatingSignal(arg).call(t)
        })
      }
    end
    
    def lift(*args, &f)
      self.class.lift(*args, &f)
    end
    
    def initialize(&f)
      @f = f
    end
    
    def call(t)
      @f.call(t)
    end
    
    def compose(&g)
      self.class.new { |t| call g.call(t) }
    end
  end
  
  class FloatingSignal < Signal
    def coerce(val)
      case val
        when FloatingSignal then [val, self]
        else [const(val), self]
      end
    end
    
    def call(t)
      @f.call(t)
    end
    
    def -@
      lift(self, &:-@)
    end
    
    def +(rhs)
      lift(self, rhs, &:+)
    end
    
    def -(rhs)
      lift(self, rhs, &:-)
    end
    
    def *(rhs)
      lift(self, rhs, &:*)
    end
    
    def /(rhs)
      lift(self, rhs, &:/)
    end
    
    def %(rhs)
      lift(self, rhs, &:%)
    end
    
    def **(rhs)
      lift(self, rhs, &:**)
    end
  end
  
  module_function
  
  def FloatingSignal(sig)
    FloatingSignal.const(0).coerce(sig)[0]
  end
  
  def now
    FloatingSignal.new { |t| t }
  end
  
  def sin(x)
    FloatingSignal.lift(x) { |x|
      Core::FloatingExpr.sin(x)
    }
  end
  
  def cos(x)
    FloatingSignal.lift(x) { |x|
      Core::FloatingExpr.cos(x)
    }
  end
  
  def tan(x)
    FloatingSignal.lift(x) { |x|
      Core::FloatingExpr.tan(x)
    }
  end
end
