require_relative 'animation'

class SpriteRenderer
  STATES = {
    idle: :idle,
    walk: :walk,
    attack: :attack,
    damage: :damage
  }.freeze

  attr_accessor :x, :y, :current_state, :facing_direction, :size, :attack_range

  def initialize(x, y, size, type = :player)
    @x = x
    @y = y
    @size = size
    @type = type
    @current_state = :idle
    @facing_direction = :right
    @shapes = {}
    @animations = {}
    @damage_flash_time = 0
    @damage_flash_duration = 0.2
    @attack_angle = 0
    @slash_angle = 0
    @slash_visible = false
    @slash_time = 0
    @slash_duration = 0.4 # Увеличиваем длительность для большей заметности
    @attack_range = 80 # Дальность атаки по умолчанию

    initialize_animations
    create_sprite_shapes
  end

  def initialize_animations
    case @type
    when :player, :knight
      @animations[:idle] = Animation.new([0, 1], 0.6, true)
      @animations[:walk] = Animation.new([0, 1, 2, 1], 0.12, true)
      @animations[:attack] = Animation.new([0, 1, 2, 3, 4, 0], 0.08, false)
      @animations[:damage] = Animation.new([0], 0.2, false)
    when :mage
      @animations[:idle] = Animation.new([0, 1], 0.7, true)
      @animations[:walk] = Animation.new([0, 1, 2, 1], 0.15, true)
      @animations[:attack] = Animation.new([0, 1, 2, 3, 0], 0.1, false)
      @animations[:damage] = Animation.new([0], 0.2, false)
    when :rogue
      @animations[:idle] = Animation.new([0, 1], 0.5, true)
      @animations[:walk] = Animation.new([0, 1, 2, 1], 0.1, true)
      @animations[:attack] = Animation.new([0, 1, 2, 0], 0.06, false)
      @animations[:damage] = Animation.new([0], 0.2, false)
    else # enemy
      @animations[:idle] = Animation.new([0, 1], 0.5, true)
      @animations[:walk] = Animation.new([0, 1, 2, 1], 0.15, true)
      @animations[:attack] = Animation.new([0, 1, 2, 0], 0.1, false)
      @animations[:damage] = Animation.new([0], 0.2, false)
    end
  end

  def create_sprite_shapes
    case @type
    when :player, :knight
      create_knight_shapes
      create_slash_effect
    when :mage
      create_mage_shapes
      create_slash_effect
    when :rogue
      create_rogue_shapes
      create_slash_effect
    else
      create_monster_shapes
    end
  end

  def create_slash_effect
    # Эффект слеша (разрез мечом) - используем прямоугольники для более яркого эффекта
    @shapes[:slash_effect] = []
    # Создаем больше прямоугольников для более заметного эффекта
    15.times do |i|
      @shapes[:slash_effect] << Rectangle.new(
        x: @x, y: @y,
        width: 3,
        height: 3,
        color: '#FFFFFF'
      )
    end
  end

  def create_knight_shapes
    # Шлем
    @shapes[:helmet] = Circle.new(
      x: @x,
      y: @y - @size / 2 - @size * 0.15,
      radius: @size * 0.25,
      color: '#C0C0C0'
    )
    
    # Визор шлема
    @shapes[:visor] = Rectangle.new(
      x: @x - @size * 0.2,
      y: @y - @size / 2 - @size * 0.1,
      width: @size * 0.4,
      height: @size * 0.15,
      color: '#2C2C2C'
    )

    # Тело (кираса)
    @shapes[:body] = Rectangle.new(
      x: @x - @size * 0.35,
      y: @y - @size * 0.2,
      width: @size * 0.7,
      height: @size * 0.6,
      color: '#A0A0A0'
    )

    # Нагрудник
    @shapes[:chest] = Rectangle.new(
      x: @x - @size * 0.25,
      y: @y - @size * 0.15,
      width: @size * 0.5,
      height: @size * 0.4,
      color: '#D0D0D0'
    )

    # Плечи (наплечники)
    @shapes[:shoulder_left] = Rectangle.new(
      x: @x - @size * 0.5,
      y: @y - @size * 0.25,
      width: @size * 0.2,
      height: @size * 0.15,
      color: '#808080'
    )
    @shapes[:shoulder_right] = Rectangle.new(
      x: @x + @size * 0.3,
      y: @y - @size * 0.25,
      width: @size * 0.2,
      height: @size * 0.15,
      color: '#808080'
    )

    # Руки
    @shapes[:arm_left] = Rectangle.new(
      x: @x - @size * 0.45,
      y: @y - @size * 0.1,
      width: @size * 0.12,
      height: @size * 0.5,
      color: '#B0B0B0'
    )
    @shapes[:arm_right] = Rectangle.new(
      x: @x + @size * 0.33,
      y: @y - @size * 0.1,
      width: @size * 0.12,
      height: @size * 0.5,
      color: '#B0B0B0'
    )

    # Щит
    @shapes[:shield] = Rectangle.new(
      x: @x - @size * 0.5,
      y: @y - @size * 0.05,
      width: @size * 0.2,
      height: @size * 0.5,
      color: '#8B4513'
    )
    @shapes[:shield_center] = Circle.new(
      x: @x - @size * 0.4,
      y: @y + @size * 0.15,
      radius: @size * 0.08,
      color: '#654321'
    )

    # Меч (рукоять)
    @shapes[:sword_handle] = Rectangle.new(
      x: @x + @size * 0.35,
      y: @y - @size * 0.05,
      width: @size * 0.08,
      height: @size * 0.25,
      color: '#4A4A4A'
    )

    # Меч (клинок)
    @shapes[:sword_blade] = Rectangle.new(
      x: @x + @size * 0.38,
      y: @y - @size * 0.3,
      width: @size * 0.05,
      height: @size * 0.4,
      color: '#E0E0E0'
    )

    # Ноги
    @shapes[:leg_left] = Rectangle.new(
      x: @x - @size * 0.25,
      y: @y + @size * 0.4,
      width: @size * 0.2,
      height: @size * 0.3,
      color: '#707070'
    )
    @shapes[:leg_right] = Rectangle.new(
      x: @x + @size * 0.05,
      y: @y + @size * 0.4,
      width: @size * 0.2,
      height: @size * 0.3,
      color: '#707070'
    )

    # Сапоги
    @shapes[:boot_left] = Rectangle.new(
      x: @x - @size * 0.25,
      y: @y + @size * 0.7,
      width: @size * 0.2,
      height: @size * 0.15,
      color: '#505050'
    )
    @shapes[:boot_right] = Rectangle.new(
      x: @x + @size * 0.05,
      y: @y + @size * 0.7,
      width: @size * 0.2,
      height: @size * 0.15,
      color: '#505050'
    )
  end

  def create_mage_shapes
    # Голова (с капюшоном)
    @shapes[:head] = Circle.new(
      x: @x,
      y: @y - @size * 0.2,
      radius: @size * 0.2,
      color: '#F5DEB3'
    )
    @shapes[:hood] = Circle.new(
      x: @x,
      y: @y - @size * 0.25,
      radius: @size * 0.25,
      color: '#4B0082'
    )

    # Тело (мантија)
    @shapes[:body] = Rectangle.new(
      x: @x - @size * 0.2,
      y: @y - @size * 0.1,
      width: @size * 0.4,
      height: @size * 0.5,
      color: '#6A0DAD'
    )

    # Руки с посохом
    @shapes[:arm_left] = Rectangle.new(
      x: @x - @size * 0.35,
      y: @y,
      width: @size * 0.1,
      height: @size * 0.3,
      color: '#F5DEB3'
    )
    @shapes[:arm_right] = Rectangle.new(
      x: @x + @size * 0.25,
      y: @y - @size * 0.1,
      width: @size * 0.08,
      height: @size * 0.5,
      color: '#F5DEB3'
    )

    # Посох
    @shapes[:staff] = Rectangle.new(
      x: @x + @size * 0.3,
      y: @y - @size * 0.4,
      width: @size * 0.05,
      height: @size * 0.6,
      color: '#8B4513'
    )
    @shapes[:staff_crystal] = Circle.new(
      x: @x + @size * 0.325,
      y: @y - @size * 0.5,
      radius: @size * 0.08,
      color: '#00FFFF'
    )

    # Ноги
    @shapes[:leg_left] = Rectangle.new(
      x: @x - @size * 0.15,
      y: @y + @size * 0.4,
      width: @size * 0.15,
      height: @size * 0.3,
      color: '#4B0082'
    )
    @shapes[:leg_right] = Rectangle.new(
      x: @x,
      y: @y + @size * 0.4,
      width: @size * 0.15,
      height: @size * 0.3,
      color: '#4B0082'
    )
  end

  def create_rogue_shapes
    # Голова (с капюшоном)
    @shapes[:head] = Circle.new(
      x: @x,
      y: @y - @size * 0.2,
      radius: @size * 0.18,
      color: '#F5DEB3'
    )
    @shapes[:hood] = Circle.new(
      x: @x,
      y: @y - @size * 0.22,
      radius: @size * 0.22,
      color: '#2F2F2F'
    )

    # Тело (кожаная броня)
    @shapes[:body] = Rectangle.new(
      x: @x - @size * 0.18,
      y: @y - @size * 0.05,
      width: @size * 0.36,
      height: @size * 0.45,
      color: '#654321'
    )

    # Руки с кинжалами
    @shapes[:arm_left] = Rectangle.new(
      x: @x - @size * 0.3,
      y: @y,
      width: @size * 0.1,
      height: @size * 0.35,
      color: '#F5DEB3'
    )
    @shapes[:arm_right] = Rectangle.new(
      x: @x + @size * 0.2,
      y: @y,
      width: @size * 0.1,
      height: @size * 0.35,
      color: '#F5DEB3'
    )

    # Кинжалы
    @shapes[:dagger_left] = Rectangle.new(
      x: @x - @size * 0.35,
      y: @y + @size * 0.25,
      width: @size * 0.05,
      height: @size * 0.2,
      color: '#C0C0C0'
    )
    @shapes[:dagger_right] = Rectangle.new(
      x: @x + @size * 0.3,
      y: @y + @size * 0.25,
      width: @size * 0.05,
      height: @size * 0.2,
      color: '#C0C0C0'
    )

    # Ноги
    @shapes[:leg_left] = Rectangle.new(
      x: @x - @size * 0.12,
      y: @y + @size * 0.4,
      width: @size * 0.12,
      height: @size * 0.3,
      color: '#2F2F2F'
    )
    @shapes[:leg_right] = Rectangle.new(
      x: @x,
      y: @y + @size * 0.4,
      width: @size * 0.12,
      height: @size * 0.3,
      color: '#2F2F2F'
    )
  end

  def create_monster_shapes
    # Определяем тип монстра (случайный при создании)
    @monster_type = [:goblin, :skeleton, :zombie].sample

    case @monster_type
    when :goblin
      create_goblin_shapes
    when :skeleton
      create_skeleton_shapes
    when :zombie
      create_zombie_shapes
    end
  end

  def create_goblin_shapes
    # Голова гоблина (зеленая, большая)
    @shapes[:head] = Circle.new(
      x: @x,
      y: @y - @size / 2 - @size * 0.1,
      radius: @size * 0.3,
      color: '#4A7C59'
    )

    # Уши
    @shapes[:ear_left] = Triangle.new(
      x1: @x - @size * 0.25, y1: @y - @size / 2 - @size * 0.15,
      x2: @x - @size * 0.35, y2: @y - @size / 2 - @size * 0.3,
      x3: @x - @size * 0.15, y3: @y - @size / 2 - @size * 0.25,
      color: '#3A6B49'
    )
    @shapes[:ear_right] = Triangle.new(
      x1: @x + @size * 0.25, y1: @y - @size / 2 - @size * 0.15,
      x2: @x + @size * 0.35, y2: @y - @size / 2 - @size * 0.3,
      x3: @x + @size * 0.15, y3: @y - @size / 2 - @size * 0.25,
      color: '#3A6B49'
    )

    # Глаза (красные, злые)
    @shapes[:eye_left] = Circle.new(
      x: @x - @size * 0.12,
      y: @y - @size / 2 - @size * 0.08,
      radius: @size * 0.08,
      color: '#FF0000'
    )
    @shapes[:eye_right] = Circle.new(
      x: @x + @size * 0.12,
      y: @y - @size / 2 - @size * 0.08,
      radius: @size * 0.08,
      color: '#FF0000'
    )

    # Рот с клыками
    @shapes[:mouth] = Rectangle.new(
      x: @x - @size * 0.1,
      y: @y - @size / 2 + @size * 0.05,
      width: @size * 0.2,
      height: @size * 0.08,
      color: '#000000'
    )

    # Тело
    @shapes[:body] = Rectangle.new(
      x: @x - @size * 0.3,
      y: @y - @size * 0.1,
      width: @size * 0.6,
      height: @size * 0.5,
      color: '#5A8C69'
    )

    # Руки
    @shapes[:arm_left] = Rectangle.new(
      x: @x - @size * 0.4,
      y: @y - @size * 0.05,
      width: @size * 0.15,
      height: @size * 0.4,
      color: '#4A7C59'
    )
    @shapes[:arm_right] = Rectangle.new(
      x: @x + @size * 0.25,
      y: @y - @size * 0.05,
      width: @size * 0.15,
      height: @size * 0.4,
      color: '#4A7C59'
    )

    # Когти
    @shapes[:claw_left] = Triangle.new(
      x1: @x - @size * 0.4, y1: @y + @size * 0.35,
      x2: @x - @size * 0.45, y2: @y + @size * 0.4,
      x3: @x - @size * 0.35, y3: @y + @size * 0.4,
      color: '#2A2A2A'
    )
    @shapes[:claw_right] = Triangle.new(
      x1: @x + @size * 0.4, y1: @y + @size * 0.35,
      x2: @x + @size * 0.45, y2: @y + @size * 0.4,
      x3: @x + @size * 0.35, y3: @y + @size * 0.4,
      color: '#2A2A2A'
    )

    # Ноги
    @shapes[:leg_left] = Rectangle.new(
      x: @x - @size * 0.25,
      y: @y + @size * 0.4,
      width: @size * 0.2,
      height: @size * 0.3,
      color: '#4A7C59'
    )
    @shapes[:leg_right] = Rectangle.new(
      x: @x + @size * 0.05,
      y: @y + @size * 0.4,
      width: @size * 0.2,
      height: @size * 0.3,
      color: '#4A7C59'
    )
  end

  def create_skeleton_shapes
    # Череп
    @shapes[:skull] = Circle.new(
      x: @x,
      y: @y - @size / 2 - @size * 0.1,
      radius: @size * 0.25,
      color: '#F5F5DC'
    )

    # Глазницы
    @shapes[:eye_left] = Circle.new(
      x: @x - @size * 0.1,
      y: @y - @size / 2 - @size * 0.08,
      radius: @size * 0.06,
      color: '#000000'
    )
    @shapes[:eye_right] = Circle.new(
      x: @x + @size * 0.1,
      y: @y - @size / 2 - @size * 0.08,
      radius: @size * 0.06,
      color: '#000000'
    )

    # Челюсть
    @shapes[:jaw] = Rectangle.new(
      x: @x - @size * 0.15,
      y: @y - @size / 2 + @size * 0.05,
      width: @size * 0.3,
      height: @size * 0.1,
      color: '#F5F5DC'
    )

    # Позвоночник
    @shapes[:spine] = Rectangle.new(
      x: @x - @size * 0.05,
      y: @y - @size * 0.05,
      width: @size * 0.1,
      height: @size * 0.5,
      color: '#E0E0E0'
    )

    # Ребра
    (0..2).each do |i|
      @shapes["rib_#{i}".to_sym] = Rectangle.new(
        x: @x - @size * 0.2,
        y: @y + @size * (0.1 + i * 0.15),
        width: @size * 0.4,
        height: @size * 0.08,
        color: '#F5F5DC'
      )
    end

    # Руки (кости)
    @shapes[:arm_left] = Rectangle.new(
      x: @x - @size * 0.35,
      y: @y - @size * 0.05,
      width: @size * 0.1,
      height: @size * 0.45,
      color: '#E0E0E0'
    )
    @shapes[:arm_right] = Rectangle.new(
      x: @x + @size * 0.25,
      y: @y - @size * 0.05,
      width: @size * 0.1,
      height: @size * 0.45,
      color: '#E0E0E0'
    )

    # Ноги (кости)
    @shapes[:leg_left] = Rectangle.new(
      x: @x - @size * 0.2,
      y: @y + @size * 0.5,
      width: @size * 0.1,
      height: @size * 0.3,
      color: '#E0E0E0'
    )
    @shapes[:leg_right] = Rectangle.new(
      x: @x + @size * 0.1,
      y: @y + @size * 0.5,
      width: @size * 0.1,
      height: @size * 0.3,
      color: '#E0E0E0'
    )
  end

  def create_zombie_shapes
    # Голова (гнилая)
    @shapes[:head] = Circle.new(
      x: @x,
      y: @y - @size / 2 - @size * 0.1,
      radius: @size * 0.28,
      color: '#8B7355'
    )

    # Раны на голове
    @shapes[:wound1] = Circle.new(
      x: @x - @size * 0.1,
      y: @y - @size / 2 - @size * 0.15,
      radius: @size * 0.05,
      color: '#654321'
    )
    @shapes[:wound2] = Circle.new(
      x: @x + @size * 0.12,
      y: @y - @size / 2 - @size * 0.1,
      radius: @size * 0.04,
      color: '#654321'
    )

    # Пустые глазницы
    @shapes[:eye_left] = Circle.new(
      x: @x - @size * 0.12,
      y: @y - @size / 2 - @size * 0.08,
      radius: @size * 0.06,
      color: '#000000'
    )
    @shapes[:eye_right] = Circle.new(
      x: @x + @size * 0.12,
      y: @y - @size / 2 - @size * 0.08,
      radius: @size * 0.06,
      color: '#000000'
    )

    # Рот (открытый)
    @shapes[:mouth] = Rectangle.new(
      x: @x - @size * 0.08,
      y: @y - @size / 2 + @size * 0.05,
      width: @size * 0.16,
      height: @size * 0.1,
      color: '#000000'
    )

    # Тело (гнилое)
    @shapes[:body] = Rectangle.new(
      x: @x - @size * 0.3,
      y: @y - @size * 0.1,
      width: @size * 0.6,
      height: @size * 0.55,
      color: '#6B5B4A'
    )

    # Разорванная одежда
    @shapes[:cloth] = Rectangle.new(
      x: @x - @size * 0.25,
      y: @y + @size * 0.2,
      width: @size * 0.5,
      height: @size * 0.25,
      color: '#4A4A4A'
    )

    # Руки (гнилые)
    @shapes[:arm_left] = Rectangle.new(
      x: @x - @size * 0.4,
      y: @y - @size * 0.05,
      width: @size * 0.12,
      height: @size * 0.45,
      color: '#7B6B5A'
    )
    @shapes[:arm_right] = Rectangle.new(
      x: @x + @size * 0.28,
      y: @y - @size * 0.05,
      width: @size * 0.12,
      height: @size * 0.45,
      color: '#7B6B5A'
    )

    # Ноги (гнилые)
    @shapes[:leg_left] = Rectangle.new(
      x: @x - @size * 0.22,
      y: @y + @size * 0.45,
      width: @size * 0.18,
      height: @size * 0.3,
      color: '#6B5B4A'
    )
    @shapes[:leg_right] = Rectangle.new(
      x: @x + @size * 0.04,
      y: @y + @size * 0.45,
      width: @size * 0.18,
      height: @size * 0.3,
      color: '#6B5B4A'
    )
  end

  def set_state(new_state)
    return if @current_state == new_state && @animations[@current_state].playing

    if new_state == :damage
      @damage_flash_time = @damage_flash_duration
      @animations[:damage].reset
    elsif @current_state == :attack && @animations[:attack].playing
      return
    end

    @current_state = new_state
    @animations[@current_state].reset unless new_state == :damage
  end

  def set_facing_direction(direction)
    @facing_direction = direction
  end

  def update(delta_time, is_moving = false, is_attacking = false, took_damage = false, attack_angle = nil)
    if took_damage
      set_state(:damage)
    elsif is_attacking
      set_state(:attack)
      # Активируем слеш при начале атаки
      if attack_angle
        @slash_angle = attack_angle
        @slash_visible = true
        @slash_time = @slash_duration
      end
    elsif is_moving
      set_state(:walk)
    else
      set_state(:idle) unless @current_state == :attack && @animations[:attack].playing
    end

    @animations[@current_state].update(delta_time) if @animations[@current_state]

    if @damage_flash_time > 0
      @damage_flash_time -= delta_time
      if @damage_flash_time <= 0 && @current_state == :damage
        set_state(:idle)
      end
    end

    # Обновляем таймер слеша
    if @slash_time > 0
      @slash_time -= delta_time
      if @slash_time <= 0
        @slash_visible = false
      end
    end

    if @current_state == :attack && !@animations[:attack].playing
      set_state(:idle)
      @attack_angle = 0
    end

    update_sprite_animation
    update_all_positions # Всегда обновляем позиции всех элементов
  end

  def update_all_positions
    # Обновляем позиции всех фигур спрайта при изменении @x и @y
    case @type
    when :player, :knight
      update_knight_positions
    when :mage
      update_mage_positions
    when :rogue
      update_rogue_positions
    else
      update_monster_positions
    end
  end

  def update_knight_positions
    base_y = @y - @size / 2
    
    @shapes[:helmet]&.x = @x
    @shapes[:helmet]&.y = base_y - @size * 0.15
    @shapes[:visor]&.x = @x - @size * 0.2
    @shapes[:visor]&.y = base_y - @size * 0.1
    @shapes[:body]&.x = @x - @size * 0.35
    @shapes[:body]&.y = @y - @size * 0.2
    @shapes[:chest]&.x = @x - @size * 0.25
    @shapes[:chest]&.y = @y - @size * 0.15
    @shapes[:shoulder_left]&.x = @x - @size * 0.5
    @shapes[:shoulder_left]&.y = @y - @size * 0.25
    @shapes[:shoulder_right]&.x = @x + @size * 0.3
    @shapes[:shoulder_right]&.y = @y - @size * 0.25
    @shapes[:shield]&.x = @x - @size * 0.5
    @shapes[:shield]&.y = @y - @size * 0.05
    @shapes[:shield_center]&.x = @x - @size * 0.4
    @shapes[:shield_center]&.y = @y + @size * 0.15
    @shapes[:arm_left]&.x = @x - @size * 0.45
    @shapes[:arm_left]&.y = @y - @size * 0.1
    @shapes[:arm_right]&.x = @x + @size * 0.33
    @shapes[:arm_right]&.y = @y - @size * 0.1
    @shapes[:leg_left]&.x = @x - @size * 0.25
    @shapes[:leg_left]&.y = @y + @size * 0.4
    @shapes[:leg_right]&.x = @x + @size * 0.05
    @shapes[:leg_right]&.y = @y + @size * 0.4
    @shapes[:boot_left]&.x = @x - @size * 0.25
    @shapes[:boot_left]&.y = @y + @size * 0.7
    @shapes[:boot_right]&.x = @x + @size * 0.05
    @shapes[:boot_right]&.y = @y + @size * 0.7
    @shapes[:sword_handle]&.x = @x + @size * 0.35
    @shapes[:sword_handle]&.y = @y - @size * 0.05
    @shapes[:sword_blade]&.x = @x + @size * 0.38
    @shapes[:sword_blade]&.y = @y - @size * 0.3
  end

  def update_mage_positions
    @shapes[:head]&.x = @x
    @shapes[:head]&.y = @y - @size * 0.2
    @shapes[:hood]&.x = @x
    @shapes[:hood]&.y = @y - @size * 0.25
    @shapes[:body]&.x = @x - @size * 0.2
    @shapes[:body]&.y = @y - @size * 0.1
    @shapes[:arm_left]&.x = @x - @size * 0.35
    @shapes[:arm_left]&.y = @y
    @shapes[:arm_right]&.x = @x + @size * 0.25
    @shapes[:arm_right]&.y = @y - @size * 0.1
    @shapes[:staff]&.x = @x + @size * 0.3
    @shapes[:staff]&.y = @y - @size * 0.4
    @shapes[:staff_crystal]&.x = @x + @size * 0.325
    @shapes[:staff_crystal]&.y = @y - @size * 0.5
    @shapes[:leg_left]&.x = @x - @size * 0.15
    @shapes[:leg_left]&.y = @y + @size * 0.4
    @shapes[:leg_right]&.x = @x
    @shapes[:leg_right]&.y = @y + @size * 0.4
  end

  def update_rogue_positions
    @shapes[:head]&.x = @x
    @shapes[:head]&.y = @y - @size * 0.2
    @shapes[:hood]&.x = @x
    @shapes[:hood]&.y = @y - @size * 0.22
    @shapes[:body]&.x = @x - @size * 0.18
    @shapes[:body]&.y = @y - @size * 0.05
    @shapes[:arm_left]&.x = @x - @size * 0.3
    @shapes[:arm_left]&.y = @y
    @shapes[:arm_right]&.x = @x + @size * 0.2
    @shapes[:arm_right]&.y = @y
    @shapes[:dagger_left]&.x = @x - @size * 0.35
    @shapes[:dagger_left]&.y = @y + @size * 0.25
    @shapes[:dagger_right]&.x = @x + @size * 0.3
    @shapes[:dagger_right]&.y = @y + @size * 0.25
    @shapes[:leg_left]&.x = @x - @size * 0.12
    @shapes[:leg_left]&.y = @y + @size * 0.4
    @shapes[:leg_right]&.x = @x
    @shapes[:leg_right]&.y = @y + @size * 0.4
  end

  def update_monster_positions
    # Базовые позиции для монстров
    @shapes[:head]&.x = @x
    @shapes[:body]&.x = @x - @size * 0.3 if @shapes[:body]
    @shapes[:body]&.y = @y - @size * 0.1 if @shapes[:body]
  end

  def update_sprite_animation
    frame = @animations[@current_state].get_current_frame

    case @type
    when :player, :knight
      update_knight_animation(frame)
    when :mage
      update_mage_animation(frame)
    when :rogue
      update_rogue_animation(frame)
    else
      update_monster_animation(frame)
    end
  end

  def update_mage_animation(frame)
    # Анимация мага (посох светится при атаке)
    if @current_state == :attack && frame > 1
      @shapes[:staff_crystal]&.color = '#FFFF00'
    else
      @shapes[:staff_crystal]&.color = '#00FFFF'
    end
  end

  def update_rogue_animation(frame)
    # Анимация разбойника (кинжалы вращаются при атаке)
    if @current_state == :attack
      angle = frame * Math::PI / 4
      if @shapes[:dagger_left]
        @shapes[:dagger_left].x = @x - @size * 0.35 + Math.cos(angle) * @size * 0.1
        @shapes[:dagger_left].y = @y + @size * 0.25 + Math.sin(angle) * @size * 0.1
      end
      if @shapes[:dagger_right]
        @shapes[:dagger_right].x = @x + @size * 0.3 + Math.cos(-angle) * @size * 0.1
        @shapes[:dagger_right].y = @y + @size * 0.25 + Math.sin(-angle) * @size * 0.1
      end
    end
  end

  def update_knight_animation(frame)
    # Обновляем позиции всех элементов рыцаря
    base_y = @y - @size / 2

    # Шлем
    @shapes[:helmet].x = @x
    @shapes[:helmet].y = base_y - @size * 0.15

    # Визор
    @shapes[:visor].x = @x - @size * 0.2
    @shapes[:visor].y = base_y - @size * 0.1

    # Тело
    @shapes[:body].x = @x - @size * 0.35
    @shapes[:body].y = @y - @size * 0.2

    # Нагрудник
    @shapes[:chest].x = @x - @size * 0.25
    @shapes[:chest].y = @y - @size * 0.15

    # Плечи
    @shapes[:shoulder_left].x = @x - @size * 0.5
    @shapes[:shoulder_left].y = @y - @size * 0.25
    @shapes[:shoulder_right].x = @x + @size * 0.3
    @shapes[:shoulder_right].y = @y - @size * 0.25

    # Щит (всегда слева)
    @shapes[:shield].x = @x - @size * 0.5
    @shapes[:shield].y = @y - @size * 0.05
    @shapes[:shield_center].x = @x - @size * 0.4
    @shapes[:shield_center].y = @y + @size * 0.15

    # Анимация ходьбы
    if @current_state == :walk
      walk_offset = Math.sin(frame * Math::PI) * @size * 0.1
      
      # Руки качаются
      @shapes[:arm_left].x = @x - @size * 0.45
      @shapes[:arm_left].y = @y - @size * 0.1 - walk_offset
      @shapes[:arm_right].x = @x + @size * 0.33
      @shapes[:arm_right].y = @y - @size * 0.1 + walk_offset

      # Ноги шагают
      @shapes[:leg_left].x = @x - @size * 0.25
      @shapes[:leg_left].y = @y + @size * 0.4 + walk_offset * 0.5
      @shapes[:leg_right].x = @x + @size * 0.05
      @shapes[:leg_right].y = @y + @size * 0.4 - walk_offset * 0.5

      # Сапоги
      @shapes[:boot_left].x = @x - @size * 0.25
      @shapes[:boot_left].y = @y + @size * 0.7 + walk_offset * 0.5
      @shapes[:boot_right].x = @x + @size * 0.05
      @shapes[:boot_right].y = @y + @size * 0.7 - walk_offset * 0.5
    else
      # Стандартные позиции
      @shapes[:arm_left].x = @x - @size * 0.45
      @shapes[:arm_left].y = @y - @size * 0.1
      @shapes[:arm_right].x = @x + @size * 0.33
      @shapes[:arm_right].y = @y - @size * 0.1

      @shapes[:leg_left].x = @x - @size * 0.25
      @shapes[:leg_left].y = @y + @size * 0.4
      @shapes[:leg_right].x = @x + @size * 0.05
      @shapes[:leg_right].y = @y + @size * 0.4

      @shapes[:boot_left].x = @x - @size * 0.25
      @shapes[:boot_left].y = @y + @size * 0.7
      @shapes[:boot_right].x = @x + @size * 0.05
      @shapes[:boot_right].y = @y + @size * 0.7
    end

    # Анимация атаки мечом
    if @current_state == :attack
      # Угол атаки зависит от кадра анимации
      @attack_angle = (frame / 4.0) * Math::PI * 2
      
      # Рукоять меча
      sword_handle_x = @x + @size * 0.35
      sword_handle_y = @y - @size * 0.05
      
      @shapes[:sword_handle].x = sword_handle_x
      @shapes[:sword_handle].y = sword_handle_y

      # Клинок меча (вращается вокруг рукояти)
      blade_length = @size * 0.5
      blade_x = sword_handle_x + Math.cos(@attack_angle) * blade_length * 0.5
      blade_y = sword_handle_y + Math.sin(@attack_angle) * blade_length * 0.5
      
      # Для визуализации используем несколько прямоугольников для эффекта размаха
      if @shapes[:sword_blade]
        @shapes[:sword_blade].x = blade_x - @size * 0.025
        @shapes[:sword_blade].y = blade_y - @size * 0.2
        @shapes[:sword_blade].width = @size * 0.05
        @shapes[:sword_blade].height = blade_length
      end

      # Рука с мечом следует за анимацией
      @shapes[:arm_right].x = @x + @size * 0.33 + Math.cos(@attack_angle) * @size * 0.2
      @shapes[:arm_right].y = @y - @size * 0.1 + Math.sin(@attack_angle) * @size * 0.2
    else
      # Стандартная позиция меча
      @shapes[:sword_handle].x = @x + @size * 0.35
      @shapes[:sword_handle].y = @y - @size * 0.05
      @shapes[:sword_blade].x = @x + @size * 0.38
      @shapes[:sword_blade].y = @y - @size * 0.3
      @shapes[:sword_blade].width = @size * 0.05
      @shapes[:sword_blade].height = @size * 0.4
    end

    # Мигание при получении урона
    if @current_state == :damage
      flash = (@damage_flash_time / @damage_flash_duration * 2).round % 2 == 0
      flash_color = flash ? '#FF6B6B' : '#A0A0A0'
      @shapes[:body].color = flash_color
      @shapes[:chest].color = flash ? '#FF8B8B' : '#D0D0D0'
    else
      @shapes[:body].color = '#A0A0A0'
      @shapes[:chest].color = '#D0D0D0'
    end

    # Визуализация слеша мечом
    update_slash_effect
  end

  def update_slash_effect
    if @slash_visible && (@type == :player || @type == :knight) && @shapes[:slash_effect]
      # Прозрачность зависит от оставшегося времени
      opacity = (@slash_time / @slash_duration)
      
      # Длина слеша зависит от дальности атаки
      slash_length = @attack_range || (@size * 2.5)
      
      # Начальная точка слеша (у меча)
      sword_x = @x + @size * 0.35
      sword_y = @y - @size * 0.05
      
      # Создаем эффект слеша из нескольких прямоугольников, образующих дугу
      @shapes[:slash_effect].each_with_index do |rect, i|
        # Позиция вдоль слеша (от начала к концу)
        progress = i.to_f / (@shapes[:slash_effect].length - 1)
        
        # Создаем дугообразный след меча
        # Угол слеша с небольшим смещением для эффекта дуги
        arc_angle = @slash_angle + Math.sin(progress * Math::PI) * 0.4
        
        # Позиция прямоугольника вдоль слеша
        distance = @size * 0.3 + progress * slash_length
        rect_x = sword_x + Math.cos(arc_angle) * distance
        rect_y = sword_y + Math.sin(arc_angle) * distance
        
        # Увеличиваем размер прямоугольников для большей заметности
        # Размер больше в центре, меньше по краям
        base_size = @size * 0.12
        size_multiplier = (1 - (progress - 0.5).abs * 2)
        rect_width = base_size * size_multiplier * opacity * 1.5
        rect_height = @size * 0.5 * opacity * 1.3
        
        # Позиционируем прямоугольник перпендикулярно направлению слеша
        perp_angle = arc_angle + Math::PI / 2
        
        rect.x = rect_x - rect_width / 2
        rect.y = rect_y - rect_height / 2
        rect.width = rect_width
        rect.height = rect_height
        
        # Более яркие и заметные цвета
        if opacity > 0.8
          rect.color = '#FFFFFF' # Яркий белый
        elsif opacity > 0.6
          rect.color = '#FFFF88' # Яркий желтый
        elsif opacity > 0.4
          rect.color = '#FFFF00' # Желтый
        elsif opacity > 0.2
          rect.color = '#FFAA00' # Оранжевый
        else
          rect.color = '#FF6600' # Темно-оранжевый
        end
      end
    elsif @shapes[:slash_effect]
      # Скрываем слеш, когда он не виден
      @shapes[:slash_effect].each do |rect|
        rect.x = @x
        rect.y = @y
        rect.width = 0
        rect.height = 0
      end
    end
  end

  def update_monster_animation(frame)
    base_y = @y - @size / 2

    case @monster_type
    when :goblin
      update_goblin_animation(frame, base_y)
    when :skeleton
      update_skeleton_animation(frame, base_y)
    when :zombie
      update_zombie_animation(frame, base_y)
    end

    # Мигание при получении урона
    if @current_state == :damage
      flash = (@damage_flash_time / @damage_flash_duration * 2).round % 2 == 0
      if @monster_type == :goblin
        @shapes[:body].color = flash ? '#FF4444' : '#5A8C69'
      elsif @monster_type == :skeleton
        @shapes[:spine].color = flash ? '#FF8888' : '#E0E0E0'
      elsif @monster_type == :zombie
        @shapes[:body].color = flash ? '#FF4444' : '#6B5B4A'
      end
    end
  end

  def update_goblin_animation(frame, base_y)
    walk_offset = @current_state == :walk ? Math.sin(frame * Math::PI) * @size * 0.1 : 0

    @shapes[:head].x = @x
    @shapes[:head].y = base_y - @size * 0.1

    @shapes[:body].x = @x - @size * 0.3
    @shapes[:body].y = @y - @size * 0.1

    @shapes[:arm_left].x = @x - @size * 0.4
    @shapes[:arm_left].y = @y - @size * 0.05 - walk_offset
    @shapes[:arm_right].x = @x + @size * 0.25
    @shapes[:arm_right].y = @y - @size * 0.05 + walk_offset

    @shapes[:leg_left].x = @x - @size * 0.25
    @shapes[:leg_left].y = @y + @size * 0.4 + walk_offset * 0.5
    @shapes[:leg_right].x = @x + @size * 0.05
    @shapes[:leg_right].y = @y + @size * 0.4 - walk_offset * 0.5
  end

  def update_skeleton_animation(frame, base_y)
    walk_offset = @current_state == :walk ? Math.sin(frame * Math::PI) * @size * 0.1 : 0

    @shapes[:skull].x = @x
    @shapes[:skull].y = base_y - @size * 0.1

    @shapes[:spine].x = @x - @size * 0.05
    @shapes[:spine].y = @y - @size * 0.05

    @shapes[:arm_left].x = @x - @size * 0.35
    @shapes[:arm_left].y = @y - @size * 0.05 - walk_offset
    @shapes[:arm_right].x = @x + @size * 0.25
    @shapes[:arm_right].y = @y - @size * 0.05 + walk_offset

    @shapes[:leg_left].x = @x - @size * 0.2
    @shapes[:leg_left].y = @y + @size * 0.5 + walk_offset * 0.5
    @shapes[:leg_right].x = @x + @size * 0.1
    @shapes[:leg_right].y = @y + @size * 0.5 - walk_offset * 0.5
  end

  def update_zombie_animation(frame, base_y)
    walk_offset = @current_state == :walk ? Math.sin(frame * Math::PI) * @size * 0.1 : 0

    @shapes[:head].x = @x
    @shapes[:head].y = base_y - @size * 0.1

    @shapes[:body].x = @x - @size * 0.3
    @shapes[:body].y = @y - @size * 0.1

    @shapes[:arm_left].x = @x - @size * 0.4
    @shapes[:arm_left].y = @y - @size * 0.05 - walk_offset
    @shapes[:arm_right].x = @x + @size * 0.28
    @shapes[:arm_right].y = @y - @size * 0.05 + walk_offset

    @shapes[:leg_left].x = @x - @size * 0.22
    @shapes[:leg_left].y = @y + @size * 0.45 + walk_offset * 0.5
    @shapes[:leg_right].x = @x + @size * 0.04
    @shapes[:leg_right].y = @y + @size * 0.45 - walk_offset * 0.5
  end

  def remove
    @shapes.values.each do |shape|
      if shape.is_a?(Array)
        shape.each(&:remove)
      else
        shape.remove
      end
    end
  end
end
