module MVK

  class Signal
    def self.const(val)
      new { |t| val }
    end
    
    def self.lift(*args, &f)
      new { |t|
        f.call(*args.map { |arg|
          Signal(arg).call(t)
        })
      }
    end
    
    def initialize(&f)
      @f = f
    end
    
    def call(t)
      @f.call(t)
    end
    
    def compose(&g)
      self.class.new { |t| self.call(g.call(t)) }
    end
    
    def coerce(value)
      case value
      when Signal then [value, self]
      else [Signal.const(value), self]
      end
    end
    
    def method_missing(method, *args)
      self.class.lift(self, *args, &method)
    end
  end
  
  def Signal(value)
    Signal.const(0).coerce(value)[0]
  end
end
