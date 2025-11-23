class Animation
  attr_accessor :current_frame, :frame_time, :elapsed_time, :loop, :playing

  def initialize(frames, frame_duration = 0.1, loop = true)
    @frames = frames
    @frame_duration = frame_duration
    @current_frame = 0
    @elapsed_time = 0
    @loop = loop
    @playing = true
  end

  def update(delta_time)
    return unless @playing

    @elapsed_time += delta_time

    if @elapsed_time >= @frame_duration
      @elapsed_time = 0
      @current_frame += 1

      if @current_frame >= @frames.length
        if @loop
          @current_frame = 0
        else
          @current_frame = @frames.length - 1
          @playing = false
        end
      end
    end
  end

  def get_current_frame
    @frames[@current_frame] || @frames[0]
  end

  def reset
    @current_frame = 0
    @elapsed_time = 0
    @playing = true
  end

  def stop
    @playing = false
  end

  def play
    @playing = true
  end
end

