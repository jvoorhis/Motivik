module MVK

  class Signal
    def self.const(val)
      new { |state| val }
    end
    
    def const(val)
      self.class.const(val)
    end
    
    def self.lift(*args, &f)
      new { |state|
        f.call *args.map { |a| a.call(state) }
      }
    end
    
    def lift(*args, &f)
      self.class.lift(*args, &f)
    end
    
    def initialize(&f)
      @f = f
    end
    
    def call(state)
      @f.call(state)
    end
    
    def compose(&g)
      self.class.new { |state| call g.call(state) }
    end
  end
  
  class FloatingSignal < Signal
    def coerce(val)
      case val
        when FloatingSignal then [val, self]
        else [const(val), self]
      end
    end
    
    def call(state)
      @f.call(state)
    end
    
    def -@
      lift(self, &:-@)
    end
    
    def +(rhs)
      lift(self, FloatingSignal(rhs), &:+)
    end
    
    def -(rhs)
      lift(self, FloatingSignal(rhs), &:-)
    end
    
    def *(rhs)
      lift(self, FloatingSignal(rhs), &:*)
    end
    
    def /(rhs)
      lift(self, FloatingSignal(rhs), &:/)
    end
    
    def %(rhs)
      lift(self, FloatingSignal(rhs), &:%)
    end
    
    def **(rhs)
      lift(self, FloatingSignal(rhs), &:**)
    end
  end
  
  def FloatingSignal(sig)
    FloatingSignal.const(0).coerce(sig)[0]
  end
  module_function :FloatingSignal
  
  module_function
  
  def now
    FloatingSignal.new { |t| t }
  end
  
  def sin(x)
    FloatingSignal.lift(FloatingSignal(x)) { |x|
      Core::FloatingExpr.sin(x)
    }
  end
  
  def cos(x)
    FloatingSignal.lift(FloatingSignal(x)) { |x|
      Core::FloatingExpr.cos(x)
    }
  end
  
  def tan(x)
    FloatingSignal.lift(FloatingSignal(x)) { |x|
      Core::FloatingExpr.tan(x)
    }
  end
end # MVK
