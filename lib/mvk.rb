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
  
  # Utilites
  
  def init
    $__mvk_init__ ||= begin
      LLVM.init_x86
      PortAudio.init
      true
    end
  end
  
  # Library functions
  
  # sine wave oscillator with amplitude amp and frequency fr
  def oscil(amp, fr, phase = 0)
    amp * cos((2 * Math::PI * fr * now) + phase)
  end
end

if $0 == __FILE__
  include MVK
  
  dsp = DSP.new { |dsp|
    # Classical FM synthesis
    fr    = 330    # carrier frequency
    index = 0.7e-3 # modulation index (depth of FM effect)
    harm  = 200    # harmonicity ratio (carrier : modulator)
    dc    = fr - fr * index
    mod   = oscil(fr * index, harm) + dc
    fm    = oscil(0.5, fr, mod) * oscil(0.7, 10.0)
    
    dsp.out = fm
    dsp.debug = true
  }
  
  dsp.start
  gets
  dsp.stop
end
