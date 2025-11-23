class Camera
  attr_accessor :x, :y, :target_x, :target_y, :window_width, :window_height

  def initialize(window_width, window_height)
    @window_width = window_width
    @window_height = window_height
    @x = 0
    @y = 0
    @target_x = 0
    @target_y = 0
    @smoothing = 0.1 # Плавность следования камеры
  end

  def follow(target_x, target_y)
    @target_x = target_x
    @target_y = target_y
    
    # Плавное следование за целью
    dx = @target_x - @x
    dy = @target_y - @y
    
    @x += dx * @smoothing
    @y += dy * @smoothing
  end

  def world_to_screen(world_x, world_y)
    # Преобразует мировые координаты в экранные
    screen_x = world_x - @x + @window_width / 2
    screen_y = world_y - @y + @window_height / 2
    [screen_x, screen_y]
  end

  def screen_to_world(screen_x, screen_y)
    # Преобразует экранные координаты в мировые
    world_x = screen_x + @x - @window_width / 2
    world_y = screen_y + @y - @window_height / 2
    [world_x, world_y]
  end

  def is_visible?(world_x, world_y, size = 0)
    # Проверяет, виден ли объект на экране
    screen_x, screen_y = world_to_screen(world_x, world_y)
    screen_x + size >= 0 && screen_x - size <= @window_width &&
    screen_y + size >= 0 && screen_y - size <= @window_height
  end
end

