require_relative 'sprite_renderer'

# Класс для дропов усилений с мобов
class Pickup
  TYPES = {
    health: {
      name: "Здоровье",
      icon: "[H]",
      color: '#FF0000',
      heal_amount: 0.3 # 30% от макс. здоровья
    },
    free_chest: {
      name: "Бесплатный сундук",
      icon: "[C]",
      color: '#FFD700',
      size: 30
    },
    magnet: {
      name: "Магнит",
      icon: "[M]",
      color: '#00FFFF',
      size: 25
    },
    bomb: {
      name: "Бомба",
      icon: "[B]",
      color: '#FF4500',
      size: 25,
      damage: 500,
      radius: 200
    }
  }.freeze
  
  attr_accessor :x, :y, :type, :collected, :shapes, :size
  
  def initialize(x, y, type)
    @x = x
    @y = y
    @type = type
    @collected = false
    @shapes = []
    @type_data = TYPES[@type] || TYPES[:health]
    @size = @type_data[:size] || 20
    @magnetized = false
    create_shapes
  end
  
  def create_shapes
    case @type
    when :health
      # Красный крест
      @shapes << Rectangle.new(
        x: 0, y: 0,
        width: 4, height: 20,
        color: @type_data[:color],
        z: 500
      )
      @shapes << Rectangle.new(
        x: 0, y: 0,
        width: 20, height: 4,
        color: @type_data[:color],
        z: 500
      )
      @shape_offsets = [
        { x: -2, y: -10 },
        { x: -10, y: -2 }
      ]
    when :free_chest
      # Золотой сундук (меньше обычного)
      @shapes << Rectangle.new(
        x: 0, y: 0,
        width: @size, height: @size * 0.7,
        color: '#FFD700',
        z: 500
      )
      @shapes << Rectangle.new(
        x: 0, y: 0,
        width: @size * 0.8, height: @size * 0.1,
        color: '#B8860B',
        z: 501
      )
      @shape_offsets = [
        { x: -@size/2, y: -@size*0.35 },
        { x: -@size*0.4, y: -@size*0.35 }
      ]
    when :magnet
      # Синий магнит
      @shapes << Circle.new(
        x: 0, y: 0,
        radius: @size / 2,
        color: @type_data[:color],
        z: 500
      )
      @shape_offsets = [{ x: 0, y: 0 }]
    when :bomb
      # Оранжевая бомба
      @shapes << Circle.new(
        x: 0, y: 0,
        radius: @size / 2,
        color: @type_data[:color],
        z: 500
      )
      @shapes << Circle.new(
        x: 0, y: 0,
        radius: @size / 4,
        color: '#FFFF00',
        z: 501
      )
      @shape_offsets = [
        { x: 0, y: 0 },
        { x: 0, y: 0 }
      ]
    end
  end
  
  def update_positions(camera)
    return if @collected
    return if @shapes.empty?
    
    screen_x, screen_y = camera.world_to_screen(@x, @y)
    
    @shapes.each_with_index do |shape, index|
      offset = @shape_offsets[index]
      next unless offset
      
      case shape
      when Circle
        shape.x = screen_x + (offset[:x] || 0)
        shape.y = screen_y + (offset[:y] || 0)
      when Rectangle
        shape.x = screen_x + (offset[:x] || 0)
        shape.y = screen_y + (offset[:y] || 0)
      end
    end
  end
  
  def remove
    @shapes.each(&:remove)
    @shapes.clear
  end
  
  def name
    @type_data[:name] || "Усиление"
  end
end





