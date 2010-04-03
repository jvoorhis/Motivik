require 'portaudio'
require 'mvk/portaudio_callback'


module MVK
  class DSP
    attr_accessor :sample_rate, :block_size, :channels, :out, :debug
    
    def initialize(options = {})
      MVK.init
      
      self.sample_rate = options[:sample_rate] || DEFAULT_SAMPLE_RATE
      self.block_size  = options[:block_size]  || sample_rate / 100
      self.out         = []
      self.debug       = options[:debug]
      
      yield self
      
      self.out = Array(out) # treat scalar as a single channel
      self.channels ||= out.size # set channel count
      # truncate and fill undefined channels with silence
      self.out = Array.new(channels) { |n| MVK::Signal(out[n] || 0) }
      
      @callback = PortAudioCallback.new(out,
                    :sample_rate => sample_rate,
                    :debug => debug)
      @user_data = @callback.alloc_user_data
      @stream = PortAudio::Stream.open(
                  :sample_rate => @callback.sample_rate,
                  :frames => block_size,
                  :callback => @callback.to_ptr,
                  :user_data => @user_data,
                  :output => {
                    :device => PortAudio::Device.default_output,
                    :channels => channels,
                    :sample_format => @callback.sample_format
                  })
    end
    
    def start
      @callback.write_initial_user_data(@user_data)
      @stream.start
    end
    
    def stop
      @stream.stop
    end
    
    def dispose
      @user_data.free
      @user_data = nil
    end
  end
end
