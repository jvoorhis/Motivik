# Motivik is a domain specific language for computer music
# Copyright (C) 2009  Jeremy Voorhis
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'mvk/dsp'

module MVK
  DEFAULT_SAMPLE_RATE = 44100
  
  module_function
  
  # initialize the system
  def init
    $__mvk_init__ ||= begin
      LLVM.init_x86
      PortAudio.init
      true
    end
  end
  
  # the current time
  def now
    Signal.new { |t| t }
  end
  
  def sin(x)
    Signal.lift(x, &:sin)
  end
  
  def cos(x)
    Signal.lift(x, &:cos)
  end
  
  def tan(x)
    Signal.lift(x, &:tan)
  end
  
  # convert frequency in Hertz to radians
  def hz2rad(hz)
    2 * Math::PI * hz
  end
  
  # sine wave oscillator with amplitude amp and frequency fr
  def oscil(amp, fr, phase = 0)
    amp * cos(hz2rad(fr) * now + phase)
  end
end

if $0 == __FILE__
  include MVK
  
  dsp = DSP.new { |dsp|
    # Classical FM synthesis
    fr    = 440 # carrier frequency
    index = 0.7e-2 # modulation index (depth of FM effect)
    harm  = 100 # harmonicity ratio (carrier : modulator)
    dc    = fr - fr * index # dc offset
    mod   = oscil(fr * index, harm) + dc # modulating signal
    fm    = oscil(0.5, fr, mod)
    
    dsp.out = fm
    dsp.debug = true
  }
  
  dsp.start
  gets
  dsp.stop
end
