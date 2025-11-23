require_relative 'sprite_renderer'

class HeroSelection
  HEROES = {
    knight: {
      name: "Рыцарь",
      icon: "⚔️",
      description: "Сбалансированный воин с отличной защитой и надежным щитом",
      stats: {
        health: 120,
        speed: 100,
        damage: 15,
        armor: 0.1
      },
      starting_weapon: :whip,
      sprite_type: :knight
    },
    mage: {
      name: "Маг",
      icon: "🔮",
      description: "Мастер магии с высоким уроном, но слабой защитой",
      stats: {
        health: 80,
        speed: 110,
        damage: 20,
        armor: 0.0
      },
      starting_weapon: :magic_wand,
      sprite_type: :mage
    },
    rogue: {
      name: "Разбойник",
      icon: "🗡️",
      description: "Быстрый и ловкий боец с высокой скоростью атаки",
      stats: {
        health: 90,
        speed: 130,
        damage: 12,
        armor: 0.05
      },
      starting_weapon: :knife,
      sprite_type: :rogue
    }
  }.freeze

  attr_accessor :selected_index, :shapes, :texts

  def initialize(window_width, window_height)
    @window_width = window_width
    @window_height = window_height
    @selected_index = 0
    @shapes = {}
    @texts = {}
    @heroes = HEROES.keys
    @animation_time = 0
    @flame_particles = {}
    @hero_sprites = {} # Спрайты персонажей для карточек
    initialize_ui
  end

  def initialize_ui
    # Эпичный темный фон с градиентом
    @shapes[:bg] = Rectangle.new(
      x: 0, y: 0,
      width: @window_width,
      height: @window_height,
      color: [5, 5, 15, 1.0]
    )

    # Создаем эпический фоновый рисунок программно
    create_epic_background

    # Декоративные элементы фона
    create_background_decorations

    # Заголовок с эффектом свечения
    @texts[:title] = Text.new(
      'ВЫБЕРИТЕ ГЕРОЯ',
      x: @window_width / 2,
      y: 40,
      size: 72,
      color: '#FFD700',
      font: nil
    )
    @texts[:title].x = @window_width / 2 - @texts[:title].width / 2

    # Подзаголовок
    @texts[:subtitle] = Text.new(
      'Судьба мира в ваших руках',
      x: @window_width / 2,
      y: 110,
      size: 28,
      color: '#CCCCCC',
      font: nil
    )
    @texts[:subtitle].x = @window_width / 2 - @texts[:subtitle].width / 2

    # Подсказка
    @texts[:hint] = Text.new(
      '← → или A/D для выбора | Enter для подтверждения',
      x: @window_width / 2,
      y: @window_height - 40,
      size: 22,
      color: '#888888',
      font: nil
    )
    @texts[:hint].x = @window_width / 2 - @texts[:hint].width / 2

    update_display
  end

  def create_epic_background
    # Создаем эпический фон с горами, замком, луной и огнем
    # Горы на заднем плане
    create_mountains
    
    # Замок вдалеке
    create_castle
    
    # Луна
    create_moon
    
    # Облака
    create_clouds
    
    # Огненный фон
    create_fire_background
  end

  def create_mountains
    # Создаем несколько горных вершин
    mountain_points = [
      [0, @window_height * 0.7],
      [@window_width * 0.2, @window_height * 0.5],
      [@window_width * 0.4, @window_height * 0.6],
      [@window_width * 0.6, @window_height * 0.45],
      [@window_width * 0.8, @window_height * 0.55],
      [@window_width, @window_height * 0.7]
    ]
    
    # Рисуем горы как многоугольники
    mountain_points.each_cons(2).with_index do |(p1, p2), i|
      @shapes["mountain_#{i}".to_sym] = Triangle.new(
        x1: p1[0], y1: p1[1],
        x2: p2[0], y2: p2[1],
        x3: (p1[0] + p2[0]) / 2, y3: [p1[1], p2[1]].min - 100,
        color: [30, 30, 40, 0.8]
      )
    end
    
    # Дополнительные горы на переднем плане
    @shapes[:mountain_foreground_1] = Triangle.new(
      x1: @window_width * 0.1, y1: @window_height * 0.75,
      x2: @window_width * 0.3, y2: @window_height * 0.75,
      x3: @window_width * 0.2, y3: @window_height * 0.6,
      color: [20, 20, 30, 0.9]
    )
    
    @shapes[:mountain_foreground_2] = Triangle.new(
      x1: @window_width * 0.7, y1: @window_height * 0.75,
      x2: @window_width * 0.9, y2: @window_height * 0.75,
      x3: @window_width * 0.8, y3: @window_height * 0.65,
      color: [20, 20, 30, 0.9]
    )
  end

  def create_castle
    castle_x = @window_width * 0.5
    castle_y = @window_height * 0.5
    castle_width = 120
    castle_height = 100
    
    # Основание замка
    @shapes[:castle_base] = Rectangle.new(
      x: castle_x - castle_width / 2,
      y: castle_y - castle_height / 2,
      width: castle_width,
      height: castle_height,
      color: [40, 40, 50, 0.7]
    )
    
    # Башни
    tower_size = 30
    @shapes[:castle_tower_left] = Rectangle.new(
      x: castle_x - castle_width / 2 - 10,
      y: castle_y - castle_height / 2 - 20,
      width: tower_size,
      height: tower_size + 20,
      color: [50, 50, 60, 0.8]
    )
    
    @shapes[:castle_tower_right] = Rectangle.new(
      x: castle_x + castle_width / 2 - 20,
      y: castle_y - castle_height / 2 - 20,
      width: tower_size,
      height: tower_size + 20,
      color: [50, 50, 60, 0.8]
    )
    
    # Центральная башня
    @shapes[:castle_tower_center] = Rectangle.new(
      x: castle_x - tower_size / 2,
      y: castle_y - castle_height / 2 - 40,
      width: tower_size,
      height: tower_size + 40,
      color: [60, 60, 70, 0.8]
    )
    
    # Окна (светятся)
    @shapes[:castle_window_1] = Rectangle.new(
      x: castle_x - 30,
      y: castle_y - 10,
      width: 15,
      height: 20,
      color: [255, 200, 100, 0.6]
    )
    
    @shapes[:castle_window_2] = Rectangle.new(
      x: castle_x + 15,
      y: castle_y - 10,
      width: 15,
      height: 20,
      color: [255, 200, 100, 0.6]
    )
  end

  def create_moon
    moon_x = @window_width * 0.85
    moon_y = @window_height * 0.15
    moon_radius = 50
    
    # Основной круг луны
    @shapes[:moon] = Circle.new(
      x: moon_x,
      y: moon_y,
      radius: moon_radius,
      color: [240, 240, 200, 0.9]
    )
    
    # Тени на луне для объема
    @shapes[:moon_shadow_1] = Circle.new(
      x: moon_x - 15,
      y: moon_y - 10,
      radius: moon_radius * 0.4,
      color: [200, 200, 180, 0.7]
    )
    
    @shapes[:moon_shadow_2] = Circle.new(
      x: moon_x - 10,
      y: moon_y + 5,
      radius: moon_radius * 0.3,
      color: [220, 220, 190, 0.6]
    )
    
    # Свечение вокруг луны
    3.times do |i|
      glow_radius = moon_radius + 10 + i * 5
      alpha = 0.2 - i * 0.05
      @shapes["moon_glow_#{i}".to_sym] = Circle.new(
        x: moon_x,
        y: moon_y,
        radius: glow_radius,
        color: [240, 240, 200, alpha]
      )
    end
  end

  def create_clouds
    # Создаем несколько облаков
    cloud_positions = [
      [@window_width * 0.2, @window_height * 0.2],
      [@window_width * 0.5, @window_height * 0.15],
      [@window_width * 0.75, @window_height * 0.25]
    ]
    
    cloud_positions.each_with_index do |(x, y), i|
      # Облако состоит из нескольких кругов
      3.times do |j|
        offset_x = (j - 1) * 30
        @shapes["cloud_#{i}_#{j}".to_sym] = Circle.new(
          x: x + offset_x,
          y: y,
          radius: 25 + rand(10),
          color: [100, 100, 120, 0.4]
        )
      end
    end
  end

  def create_background_monsters
    # Создаем скелетов и монстров на фоне для заполнения пространства
    
    # Скелет 1 (слева)
    create_skeleton(@window_width * 0.15, @window_height * 0.4, 0.6)
    
    # Скелет 2 (справа)
    create_skeleton(@window_width * 0.85, @window_height * 0.45, 0.5)
    
    # Гоблин 1 (слева от центра)
    create_goblin(@window_width * 0.3, @window_height * 0.5, 0.5)
    
    # Гоблин 2 (справа от центра)
    create_goblin(@window_width * 0.7, @window_height * 0.48, 0.5)
    
    # Зомби (в центре, за замком)
    create_zombie(@window_width * 0.5, @window_height * 0.55, 0.4)
    
    # Дополнительные декоративные элементы
    create_background_decorations
  end

  def create_skeleton(x, y, scale)
    size = 40 * scale
    base_key = "bg_skeleton_#{x.to_i}_#{y.to_i}"
    
    # Череп
    @shapes["#{base_key}_skull".to_sym] = Circle.new(
      x: x,
      y: y - size * 0.3,
      radius: size * 0.15,
      color: [220, 220, 220, 0.7]
    )
    # Глазницы
    @shapes["#{base_key}_eye_l".to_sym] = Circle.new(
      x: x - size * 0.05,
      y: y - size * 0.3,
      radius: size * 0.03,
      color: [0, 0, 0, 0.8]
    )
    @shapes["#{base_key}_eye_r".to_sym] = Circle.new(
      x: x + size * 0.05,
      y: y - size * 0.3,
      radius: size * 0.03,
      color: [0, 0, 0, 0.8]
    )
    # Позвоночник
    @shapes["#{base_key}_spine".to_sym] = Rectangle.new(
      x: x - size * 0.02,
      y: y - size * 0.15,
      width: size * 0.04,
      height: size * 0.3,
      color: [200, 200, 200, 0.7]
    )
    # Ребра
    3.times do |i|
      @shapes["#{base_key}_rib_#{i}".to_sym] = Rectangle.new(
        x: x - size * 0.08,
        y: y - size * 0.1 + i * size * 0.08,
        width: size * 0.16,
        height: size * 0.02,
        color: [210, 210, 210, 0.7]
      )
    end
    # Руки
    @shapes["#{base_key}_arm_l".to_sym] = Rectangle.new(
      x: x - size * 0.12,
      y: y - size * 0.05,
      width: size * 0.04,
      height: size * 0.2,
      color: [200, 200, 200, 0.7]
    )
    @shapes["#{base_key}_arm_r".to_sym] = Rectangle.new(
      x: x + size * 0.08,
      y: y - size * 0.05,
      width: size * 0.04,
      height: size * 0.2,
      color: [200, 200, 200, 0.7]
    )
    # Ноги
    @shapes["#{base_key}_leg_l".to_sym] = Rectangle.new(
      x: x - size * 0.06,
      y: y + size * 0.15,
      width: size * 0.04,
      height: size * 0.25,
      color: [200, 200, 200, 0.7]
    )
    @shapes["#{base_key}_leg_r".to_sym] = Rectangle.new(
      x: x + size * 0.02,
      y: y + size * 0.15,
      width: size * 0.04,
      height: size * 0.25,
      color: [200, 200, 200, 0.7]
    )
  end

  def create_goblin(x, y, scale)
    size = 35 * scale
    base_key = "bg_goblin_#{x.to_i}_#{y.to_i}"
    
    # Голова
    @shapes["#{base_key}_head".to_sym] = Circle.new(
      x: x,
      y: y - size * 0.2,
      radius: size * 0.12,
      color: [139, 90, 43, 0.7]
    )
    # Уши
    @shapes["#{base_key}_ear_l".to_sym] = Triangle.new(
      x1: x - size * 0.15, y1: y - size * 0.25,
      x2: x - size * 0.12, y2: y - size * 0.35,
      x3: x - size * 0.08, y3: y - size * 0.28,
      color: [139, 90, 43, 0.7]
    )
    @shapes["#{base_key}_ear_r".to_sym] = Triangle.new(
      x1: x + size * 0.15, y1: y - size * 0.25,
      x2: x + size * 0.12, y2: y - size * 0.35,
      x3: x + size * 0.08, y3: y - size * 0.28,
      color: [139, 90, 43, 0.7]
    )
    # Глаза
    @shapes["#{base_key}_eye_l".to_sym] = Circle.new(
      x: x - size * 0.04,
      y: y - size * 0.18,
      radius: size * 0.02,
      color: [255, 0, 0, 0.8]
    )
    @shapes["#{base_key}_eye_r".to_sym] = Circle.new(
      x: x + size * 0.04,
      y: y - size * 0.18,
      radius: size * 0.02,
      color: [255, 0, 0, 0.8]
    )
    # Тело
    @shapes["#{base_key}_body".to_sym] = Rectangle.new(
      x: x - size * 0.1,
      y: y,
      width: size * 0.2,
      height: size * 0.25,
      color: [85, 107, 47, 0.7]
    )
    # Руки
    @shapes["#{base_key}_arm_l".to_sym] = Rectangle.new(
      x: x - size * 0.15,
      y: y + size * 0.05,
      width: size * 0.04,
      height: size * 0.15,
      color: [139, 90, 43, 0.7]
    )
    @shapes["#{base_key}_arm_r".to_sym] = Rectangle.new(
      x: x + size * 0.11,
      y: y + size * 0.05,
      width: size * 0.04,
      height: size * 0.15,
      color: [139, 90, 43, 0.7]
    )
    # Когти
    @shapes["#{base_key}_claw_l".to_sym] = Triangle.new(
      x1: x - size * 0.15, y1: y + size * 0.2,
      x2: x - size * 0.18, y2: y + size * 0.18,
      x3: x - size * 0.13, y3: y + size * 0.18,
      color: [50, 50, 50, 0.8]
    )
    @shapes["#{base_key}_claw_r".to_sym] = Triangle.new(
      x1: x + size * 0.15, y1: y + size * 0.2,
      x2: x + size * 0.18, y2: y + size * 0.18,
      x3: x + size * 0.13, y3: y + size * 0.18,
      color: [50, 50, 50, 0.8]
    )
    # Ноги
    @shapes["#{base_key}_leg_l".to_sym] = Rectangle.new(
      x: x - size * 0.06,
      y: y + size * 0.25,
      width: size * 0.04,
      height: size * 0.2,
      color: [139, 90, 43, 0.7]
    )
    @shapes["#{base_key}_leg_r".to_sym] = Rectangle.new(
      x: x + size * 0.02,
      y: y + size * 0.25,
      width: size * 0.04,
      height: size * 0.2,
      color: [139, 90, 43, 0.7]
    )
  end

  def create_zombie(x, y, scale)
    size = 30 * scale
    base_key = "bg_zombie_#{x.to_i}_#{y.to_i}"
    
    # Голова
    @shapes["#{base_key}_head".to_sym] = Circle.new(
      x: x,
      y: y - size * 0.15,
      radius: size * 0.1,
      color: [139, 126, 102, 0.7]
    )
    # Раны
    @shapes["#{base_key}_wound1".to_sym] = Circle.new(
      x: x - size * 0.04,
      y: y - size * 0.12,
      radius: size * 0.02,
      color: [139, 0, 0, 0.8]
    )
    @shapes["#{base_key}_wound2".to_sym] = Circle.new(
      x: x + size * 0.05,
      y: y - size * 0.15,
      radius: size * 0.015,
      color: [139, 0, 0, 0.8]
    )
    # Глаза
    @shapes["#{base_key}_eye_l".to_sym] = Circle.new(
      x: x - size * 0.03,
      y: y - size * 0.15,
      radius: size * 0.015,
      color: [0, 100, 0, 0.9]
    )
    @shapes["#{base_key}_eye_r".to_sym] = Circle.new(
      x: x + size * 0.03,
      y: y - size * 0.15,
      radius: size * 0.015,
      color: [0, 100, 0, 0.9]
    )
    # Тело
    @shapes["#{base_key}_body".to_sym] = Rectangle.new(
      x: x - size * 0.08,
      y: y,
      width: size * 0.16,
      height: size * 0.2,
      color: [101, 67, 33, 0.7]
    )
    # Руки
    @shapes["#{base_key}_arm_l".to_sym] = Rectangle.new(
      x: x - size * 0.12,
      y: y + size * 0.02,
      width: size * 0.04,
      height: size * 0.15,
      color: [139, 126, 102, 0.7]
    )
    @shapes["#{base_key}_arm_r".to_sym] = Rectangle.new(
      x: x + size * 0.08,
      y: y + size * 0.02,
      width: size * 0.04,
      height: size * 0.15,
      color: [139, 126, 102, 0.7]
    )
    # Ноги
    @shapes["#{base_key}_leg_l".to_sym] = Rectangle.new(
      x: x - size * 0.05,
      y: y + size * 0.2,
      width: size * 0.04,
      height: size * 0.18,
      color: [101, 67, 33, 0.7]
    )
    @shapes["#{base_key}_leg_r".to_sym] = Rectangle.new(
      x: x + size * 0.01,
      y: y + size * 0.2,
      width: size * 0.04,
      height: size * 0.18,
      color: [101, 67, 33, 0.7]
    )
  end

  def create_fire_background
    # Создаем огненный фон внизу экрана - более реалистичный огонь
    @fire_particles = []
    80.times do |i|
      @fire_particles << {
        x: rand(@window_width),
        y: @window_height - 30 + rand(80),
        size: 4 + rand(8),
        speed: 30 + rand(50),
        life: 0.8 + rand * 1.2,
        max_life: 0.8 + rand * 1.2,
        color_offset: rand,
        flicker: rand * Math::PI * 2
      }
    end
    
    # Создаем базовый слой огня (полупрозрачный градиент)
    @shapes[:fire_base] = Rectangle.new(
      x: 0,
      y: @window_height - 100,
      width: @window_width,
      height: 100,
      color: [139, 0, 0, 0.3] # Темно-красный полупрозрачный
    )
    
    @shapes[:fire_mid] = Rectangle.new(
      x: 0,
      y: @window_height - 70,
      width: @window_width,
      height: 70,
      color: [255, 69, 0, 0.2] # Оранжевый полупрозрачный
    )
    
    @shapes[:fire_top] = Rectangle.new(
      x: 0,
      y: @window_height - 40,
      width: @window_width,
      height: 40,
      color: [255, 140, 0, 0.15] # Желто-оранжевый полупрозрачный
    )
  end

  def create_hero_icon(index, hero_key, card_x, card_y, card_width, card_height, selected)
    # Используем простые спрайты из игры, как они выглядят в игре
    icon_center_x = card_x + card_width / 2
    icon_center_y = card_y + 120 # Позиция иконки в карточке
    icon_size = selected ? 50 : 45 # Размер спрайта
    
    # Определяем тип спрайта
    sprite_type = case hero_key
    when :knight
      :knight
    when :mage
      :mage
    when :rogue
      :rogue
    else
      :player
    end
    
    # Удаляем старый спрайт если есть
    if @hero_sprites[index]
      @hero_sprites[index].remove
      @hero_sprites[index] = nil
    end
    
    # Создаем новый спрайт
    @hero_sprites[index] = SpriteRenderer.new(icon_center_x, icon_center_y, icon_size, sprite_type)
    @hero_sprites[index].current_state = :idle
    @hero_sprites[index].facing_direction = :right
  end

  # Старые методы портретов удалены - теперь используем SpriteRenderer
  def _old_create_knight_portrait(index, center_x, center_y, scale, brightness, card_width, card_height)
    size = [card_width * 0.7, card_height * 0.5].min * scale
    mult = brightness
    
    # Ноги и сапоги (снизу вверх) - более детальные
    # Левый сапог
    @shapes["hero_#{index}_boot_l_base".to_sym] = Rectangle.new(
      x: center_x - size * 0.15,
      y: center_y + size * 0.35,
      width: size * 0.12,
      height: size * 0.15,
      color: [30 * mult, 30 * mult, 30 * mult, 1.0]
    )
    @shapes["hero_#{index}_boot_l_top".to_sym] = Rectangle.new(
      x: center_x - size * 0.14,
      y: center_y + size * 0.32,
      width: size * 0.1,
      height: size * 0.05,
      color: [50 * mult, 50 * mult, 50 * mult, 1.0]
    )
    # Правый сапог
    @shapes["hero_#{index}_boot_r_base".to_sym] = Rectangle.new(
      x: center_x + size * 0.03,
      y: center_y + size * 0.35,
      width: size * 0.12,
      height: size * 0.15,
      color: [30 * mult, 30 * mult, 30 * mult, 1.0]
    )
    @shapes["hero_#{index}_boot_r_top".to_sym] = Rectangle.new(
      x: center_x + size * 0.04,
      y: center_y + size * 0.32,
      width: size * 0.1,
      height: size * 0.05,
      color: [50 * mult, 50 * mult, 50 * mult, 1.0]
    )
    # Левая нога
    @shapes["hero_#{index}_leg_l".to_sym] = Rectangle.new(
      x: center_x - size * 0.14,
      y: center_y + size * 0.2,
      width: size * 0.1,
      height: size * 0.15,
      color: [120 * mult, 120 * mult, 120 * mult, 1.0]
    )
    # Правая нога
    @shapes["hero_#{index}_leg_r".to_sym] = Rectangle.new(
      x: center_x + size * 0.04,
      y: center_y + size * 0.2,
      width: size * 0.1,
      height: size * 0.15,
      color: [120 * mult, 120 * mult, 120 * mult, 1.0]
    )
    
    # Тело и доспехи - более детальные
    # Нагрудник (основа)
    @shapes["hero_#{index}_chest".to_sym] = Rectangle.new(
      x: center_x - size * 0.2,
      y: center_y - size * 0.1,
      width: size * 0.4,
      height: size * 0.35,
      color: [120 * mult, 120 * mult, 120 * mult, 1.0]
    )
    # Пластина на груди (блестящая)
    @shapes["hero_#{index}_chest_plate".to_sym] = Rectangle.new(
      x: center_x - size * 0.12,
      y: center_y - size * 0.05,
      width: size * 0.24,
      height: size * 0.25,
      color: [200 * mult, 200 * mult, 200 * mult, 1.0]
    )
    # Блики на пластине
    @shapes["hero_#{index}_chest_highlight".to_sym] = Rectangle.new(
      x: center_x - size * 0.08,
      y: center_y - size * 0.02,
      width: size * 0.16,
      height: size * 0.15,
      color: [240 * mult, 240 * mult, 240 * mult, 0.6]
    )
    # Ремни и застежки
    @shapes["hero_#{index}_strap_l".to_sym] = Rectangle.new(
      x: center_x - size * 0.18,
      y: center_y + size * 0.05,
      width: size * 0.06,
      height: size * 0.02,
      color: [60 * mult, 40 * mult, 20 * mult, 1.0]
    )
    @shapes["hero_#{index}_strap_r".to_sym] = Rectangle.new(
      x: center_x + size * 0.12,
      y: center_y + size * 0.05,
      width: size * 0.06,
      height: size * 0.02,
      color: [60 * mult, 40 * mult, 20 * mult, 1.0]
    )
    # Левое плечо
    @shapes["hero_#{index}_shoulder_l".to_sym] = Circle.new(
      x: center_x - size * 0.25,
      y: center_y - size * 0.15,
      radius: size * 0.12,
      color: [130 * mult, 130 * mult, 130 * mult, 1.0]
    )
    # Правое плечо
    @shapes["hero_#{index}_shoulder_r".to_sym] = Circle.new(
      x: center_x + size * 0.25,
      y: center_y - size * 0.15,
      radius: size * 0.12,
      color: [130 * mult, 130 * mult, 130 * mult, 1.0]
    )
    
    # Руки
    # Левая рука
    @shapes["hero_#{index}_arm_l".to_sym] = Rectangle.new(
      x: center_x - size * 0.32,
      y: center_y - size * 0.05,
      width: size * 0.1,
      height: size * 0.25,
      color: [120 * mult, 120 * mult, 120 * mult, 1.0]
    )
    # Правая рука
    @shapes["hero_#{index}_arm_r".to_sym] = Rectangle.new(
      x: center_x + size * 0.22,
      y: center_y - size * 0.05,
      width: size * 0.1,
      height: size * 0.25,
      color: [120 * mult, 120 * mult, 120 * mult, 1.0]
    )
    
    # Щит (левая рука) - более детальный
    @shapes["hero_#{index}_shield_base".to_sym] = Circle.new(
      x: center_x - size * 0.28,
      y: center_y + size * 0.05,
      radius: size * 0.18,
      color: [60 * mult, 40 * mult, 20 * mult, 1.0]
    )
    @shapes["hero_#{index}_shield".to_sym] = Circle.new(
      x: center_x - size * 0.28,
      y: center_y + size * 0.05,
      radius: size * 0.16,
      color: [100 * mult, 60 * mult, 40 * mult, 1.0]
    )
    # Металлическая окантовка
    @shapes["hero_#{index}_shield_rim".to_sym] = Circle.new(
      x: center_x - size * 0.28,
      y: center_y + size * 0.05,
      radius: size * 0.17,
      color: [180 * mult, 180 * mult, 180 * mult, 0.5]
    )
    # Крест на щите (более детальный)
    @shapes["hero_#{index}_shield_cross_v".to_sym] = Rectangle.new(
      x: center_x - size * 0.29,
      y: center_y - size * 0.05,
      width: size * 0.02,
      height: size * 0.2,
      color: [220 * mult, 220 * mult, 220 * mult, 1.0]
    )
    @shapes["hero_#{index}_shield_cross_h".to_sym] = Rectangle.new(
      x: center_x - size * 0.35,
      y: center_y + size * 0.03,
      width: size * 0.16,
      height: size * 0.02,
      color: [220 * mult, 220 * mult, 220 * mult, 1.0]
    )
    # Центральная босса щита
    @shapes["hero_#{index}_shield_boss".to_sym] = Circle.new(
      x: center_x - size * 0.28,
      y: center_y + size * 0.05,
      radius: size * 0.04,
      color: [160 * mult, 160 * mult, 160 * mult, 1.0]
    )
    
    # Меч (правая рука) - более детальный
    # Клинок
    @shapes["hero_#{index}_sword_blade".to_sym] = Rectangle.new(
      x: center_x + size * 0.25,
      y: center_y - size * 0.2,
      width: size * 0.04,
      height: size * 0.35,
      color: [240 * mult, 240 * mult, 240 * mult, 1.0]
    )
    # Блики на клинке
    @shapes["hero_#{index}_sword_shine".to_sym] = Rectangle.new(
      x: center_x + size * 0.255,
      y: center_y - size * 0.15,
      width: size * 0.02,
      height: size * 0.25,
      color: [255, 255, 255, 0.7]
    )
    # Гарда
    @shapes["hero_#{index}_sword_guard".to_sym] = Rectangle.new(
      x: center_x + size * 0.24,
      y: center_y + size * 0.12,
      width: size * 0.1,
      height: size * 0.03,
      color: [200 * mult, 200 * mult, 200 * mult, 1.0]
    )
    # Рукоять
    @shapes["hero_#{index}_sword_handle".to_sym] = Rectangle.new(
      x: center_x + size * 0.27,
      y: center_y + size * 0.15,
      width: size * 0.06,
      height: size * 0.08,
      color: [139 * mult, 69 * mult, 19 * mult, 1.0]
    )
    # Навершие
    @shapes["hero_#{index}_sword_pommel".to_sym] = Circle.new(
      x: center_x + size * 0.3,
      y: center_y + size * 0.23,
      radius: size * 0.03,
      color: [180 * mult, 180 * mult, 180 * mult, 1.0]
    )
    
    # Голова и шлем - более детальные
    # Голова
    @shapes["hero_#{index}_head".to_sym] = Circle.new(
      x: center_x,
      y: center_y - size * 0.3,
      radius: size * 0.15,
      color: [245 * mult, 222 * mult, 179 * mult, 1.0]
    )
    # Шлем (основа)
    @shapes["hero_#{index}_helmet_base".to_sym] = Circle.new(
      x: center_x,
      y: center_y - size * 0.32,
      radius: size * 0.18,
      color: [140 * mult, 140 * mult, 140 * mult, 1.0]
    )
    # Шлем (блестящий слой)
    @shapes["hero_#{index}_helmet".to_sym] = Circle.new(
      x: center_x,
      y: center_y - size * 0.33,
      radius: size * 0.17,
      color: [180 * mult, 180 * mult, 180 * mult, 1.0]
    )
    # Блики на шлеме
    @shapes["hero_#{index}_helmet_highlight".to_sym] = Rectangle.new(
      x: center_x - size * 0.1,
      y: center_y - size * 0.38,
      width: size * 0.2,
      height: size * 0.08,
      color: [220 * mult, 220 * mult, 220 * mult, 0.5]
    )
    # Визор (с прорезями)
    @shapes["hero_#{index}_visor_base".to_sym] = Rectangle.new(
      x: center_x - size * 0.12,
      y: center_y - size * 0.28,
      width: size * 0.24,
      height: size * 0.08,
      color: [20, 20, 20, 0.9]
    )
    @shapes["hero_#{index}_visor".to_sym] = Rectangle.new(
      x: center_x - size * 0.11,
      y: center_y - size * 0.27,
      width: size * 0.22,
      height: size * 0.06,
      color: [10, 10, 10, 0.95]
    )
    # Прорези в визоре
    @shapes["hero_#{index}_visor_slit_l".to_sym] = Rectangle.new(
      x: center_x - size * 0.08,
      y: center_y - size * 0.26,
      width: size * 0.02,
      height: size * 0.04,
      color: [100, 100, 100, 0.3]
    )
    @shapes["hero_#{index}_visor_slit_r".to_sym] = Rectangle.new(
      x: center_x + size * 0.06,
      y: center_y - size * 0.26,
      width: size * 0.02,
      height: size * 0.04,
      color: [100, 100, 100, 0.3]
    )
    # Гребень на шлеме (более детальный)
    @shapes["hero_#{index}_crest_base".to_sym] = Rectangle.new(
      x: center_x - size * 0.04,
      y: center_y - size * 0.45,
      width: size * 0.08,
      height: size * 0.12,
      color: [150 * mult, 0, 0, 1.0]
    )
    @shapes["hero_#{index}_crest".to_sym] = Rectangle.new(
      x: center_x - size * 0.03,
      y: center_y - size * 0.46,
      width: size * 0.06,
      height: size * 0.1,
      color: [220 * mult, 0, 0, 1.0]
    )
    # Перья на гребне
    @shapes["hero_#{index}_crest_feather".to_sym] = Triangle.new(
      x1: center_x, y1: center_y - size * 0.5,
      x2: center_x - size * 0.02, y2: center_y - size * 0.48,
      x3: center_x + size * 0.02, y3: center_y - size * 0.48,
      color: [255 * mult, 0, 0, 1.0]
    )
  end

  def _old_create_mage_portrait(index, center_x, center_y, scale, brightness, card_width, card_height)
    size = [card_width * 0.7, card_height * 0.5].min * scale
    mult = brightness
    
    # Ноги
    @shapes["hero_#{index}_leg_l".to_sym] = Rectangle.new(
      x: center_x - size * 0.1,
      y: center_y + size * 0.25,
      width: size * 0.08,
      height: size * 0.2,
      color: [106 * mult, 13 * mult, 173 * mult, 1.0]
    )
    @shapes["hero_#{index}_leg_r".to_sym] = Rectangle.new(
      x: center_x + size * 0.02,
      y: center_y + size * 0.25,
      width: size * 0.08,
      height: size * 0.2,
      color: [106 * mult, 13 * mult, 173 * mult, 1.0]
    )
    
    # Мантия (тело)
    @shapes["hero_#{index}_robe_body".to_sym] = Rectangle.new(
      x: center_x - size * 0.18,
      y: center_y - size * 0.1,
      width: size * 0.36,
      height: size * 0.35,
      color: [106 * mult, 13 * mult, 173 * mult, 1.0]
    )
    # Внутренняя часть мантии
    @shapes["hero_#{index}_robe_inner".to_sym] = Rectangle.new(
      x: center_x - size * 0.12,
      y: center_y,
      width: size * 0.24,
      height: size * 0.25,
      color: [75 * mult, 0 * mult, 130 * mult, 1.0]
    )
    
    # Рукава
    @shapes["hero_#{index}_sleeve_l".to_sym] = Rectangle.new(
      x: center_x - size * 0.28,
      y: center_y - size * 0.05,
      width: size * 0.12,
      height: size * 0.3,
      color: [106 * mult, 13 * mult, 173 * mult, 1.0]
    )
    @shapes["hero_#{index}_sleeve_r".to_sym] = Rectangle.new(
      x: center_x + size * 0.16,
      y: center_y - size * 0.05,
      width: size * 0.12,
      height: size * 0.3,
      color: [106 * mult, 13 * mult, 173 * mult, 1.0]
    )
    
    # Посох - более детальный
    @shapes["hero_#{index}_staff_base".to_sym] = Rectangle.new(
      x: center_x + size * 0.22,
      y: center_y - size * 0.25,
      width: size * 0.04,
      height: size * 0.5,
      color: [100 * mult, 50 * mult, 20 * mult, 1.0]
    )
    @shapes["hero_#{index}_staff".to_sym] = Rectangle.new(
      x: center_x + size * 0.225,
      y: center_y - size * 0.24,
      width: size * 0.03,
      height: size * 0.48,
      color: [139 * mult, 69 * mult, 19 * mult, 1.0]
    )
    # Обмотка на посохе
    @shapes["hero_#{index}_staff_wrap_1".to_sym] = Rectangle.new(
      x: center_x + size * 0.22,
      y: center_y - size * 0.1,
      width: size * 0.04,
      height: size * 0.02,
      color: [80 * mult, 40 * mult, 20 * mult, 1.0]
    )
    @shapes["hero_#{index}_staff_wrap_2".to_sym] = Rectangle.new(
      x: center_x + size * 0.22,
      y: center_y + size * 0.05,
      width: size * 0.04,
      height: size * 0.02,
      color: [80 * mult, 40 * mult, 20 * mult, 1.0]
    )
    # Кристалл на посохе (свечение) - более детальное
    @shapes["hero_#{index}_crystal_glow_outer".to_sym] = Circle.new(
      x: center_x + size * 0.24,
      y: center_y - size * 0.35,
      radius: size * 0.14,
      color: [0, 200 * mult, 255 * mult, 0.3]
    )
    @shapes["hero_#{index}_crystal_glow".to_sym] = Circle.new(
      x: center_x + size * 0.24,
      y: center_y - size * 0.35,
      radius: size * 0.12,
      color: [0, 255 * mult, 255 * mult, 0.5]
    )
    @shapes["hero_#{index}_crystal".to_sym] = Circle.new(
      x: center_x + size * 0.24,
      y: center_y - size * 0.35,
      radius: size * 0.08,
      color: [0, 200 * mult, 255 * mult, 1.0]
    )
    # Внутренний кристалл
    @shapes["hero_#{index}_crystal_core".to_sym] = Circle.new(
      x: center_x + size * 0.24,
      y: center_y - size * 0.35,
      radius: size * 0.04,
      color: [200, 255, 255, 1.0]
    )
    # Блики на кристалле
    @shapes["hero_#{index}_crystal_highlight".to_sym] = Circle.new(
      x: center_x + size * 0.22,
      y: center_y - size * 0.37,
      radius: size * 0.02,
      color: [255, 255, 255, 0.8]
    )
    
    # Голова
    @shapes["hero_#{index}_head".to_sym] = Circle.new(
      x: center_x,
      y: center_y - size * 0.25,
      radius: size * 0.12,
      color: [245 * mult, 222 * mult, 179 * mult, 1.0]
    )
    # Борода
    @shapes["hero_#{index}_beard".to_sym] = Rectangle.new(
      x: center_x - size * 0.08,
      y: center_y - size * 0.18,
      width: size * 0.16,
      height: size * 0.1,
      color: [200 * mult, 200 * mult, 200 * mult, 1.0]
    )
    # Капюшон - более детальный
    @shapes["hero_#{index}_hood_base".to_sym] = Circle.new(
      x: center_x,
      y: center_y - size * 0.28,
      radius: size * 0.16,
      color: [60 * mult, 0 * mult, 100 * mult, 1.0]
    )
    @shapes["hero_#{index}_hood".to_sym] = Circle.new(
      x: center_x,
      y: center_y - size * 0.29,
      radius: size * 0.15,
      color: [75 * mult, 0 * mult, 130 * mult, 1.0]
    )
    # Складки на капюшоне
    @shapes["hero_#{index}_hood_fold_1".to_sym] = Rectangle.new(
      x: center_x - size * 0.12,
      y: center_y - size * 0.25,
      width: size * 0.24,
      height: size * 0.02,
      color: [50 * mult, 0 * mult, 100 * mult, 0.8]
    )
    @shapes["hero_#{index}_hood_fold_2".to_sym] = Rectangle.new(
      x: center_x - size * 0.1,
      y: center_y - size * 0.32,
      width: size * 0.2,
      height: size * 0.02,
      color: [50 * mult, 0 * mult, 100 * mult, 0.8]
    )
    # Звезды на капюшоне (магические символы) - более яркие
    3.times do |i|
      angle = (i * 2 * Math::PI / 3) + Math::PI / 2
      star_x = center_x + Math.cos(angle) * size * 0.12
      star_y = center_y - size * 0.28 + Math.sin(angle) * size * 0.12
      # Внешнее свечение
      @shapes["hero_#{index}_star_glow_#{i}".to_sym] = Circle.new(
        x: star_x,
        y: star_y,
        radius: size * 0.03,
        color: [255, 255, 0, 0.4]
      )
      # Сама звезда
      @shapes["hero_#{index}_star_#{i}".to_sym] = Circle.new(
        x: star_x,
        y: star_y,
        radius: size * 0.02,
        color: [255, 255, 100, 1.0]
      )
    end
  end

  def _old_create_rogue_portrait(index, center_x, center_y, scale, brightness, card_width, card_height)
    size = [card_width * 0.7, card_height * 0.5].min * scale
    mult = brightness
    
    # Ноги
    @shapes["hero_#{index}_leg_l".to_sym] = Rectangle.new(
      x: center_x - size * 0.1,
      y: center_y + size * 0.25,
      width: size * 0.08,
      height: size * 0.2,
      color: [101 * mult, 67 * mult, 33 * mult, 1.0]
    )
    @shapes["hero_#{index}_leg_r".to_sym] = Rectangle.new(
      x: center_x + size * 0.02,
      y: center_y + size * 0.25,
      width: size * 0.08,
      height: size * 0.2,
      color: [101 * mult, 67 * mult, 33 * mult, 1.0]
    )
    
    # Тело (кожаная броня)
    @shapes["hero_#{index}_body".to_sym] = Rectangle.new(
      x: center_x - size * 0.15,
      y: center_y - size * 0.05,
      width: size * 0.3,
      height: size * 0.3,
      color: [101 * mult, 67 * mult, 33 * mult, 1.0]
    )
    # Пояс
    @shapes["hero_#{index}_belt".to_sym] = Rectangle.new(
      x: center_x - size * 0.15,
      y: center_y + size * 0.15,
      width: size * 0.3,
      height: size * 0.04,
      color: [60 * mult, 40 * mult, 20 * mult, 1.0]
    )
    # Пряжка
    @shapes["hero_#{index}_buckle".to_sym] = Rectangle.new(
      x: center_x - size * 0.04,
      y: center_y + size * 0.15,
      width: size * 0.08,
      height: size * 0.04,
      color: [200 * mult, 200 * mult, 200 * mult, 1.0]
    )
    
    # Руки
    @shapes["hero_#{index}_arm_l".to_sym] = Rectangle.new(
      x: center_x - size * 0.22,
      y: center_y,
      width: size * 0.08,
      height: size * 0.25,
      color: [101 * mult, 67 * mult, 33 * mult, 1.0]
    )
    @shapes["hero_#{index}_arm_r".to_sym] = Rectangle.new(
      x: center_x + size * 0.14,
      y: center_y,
      width: size * 0.08,
      height: size * 0.25,
      color: [101 * mult, 67 * mult, 33 * mult, 1.0]
    )
    
    # Кинжалы - более детальные
    # Левый кинжал (в руке)
    @shapes["hero_#{index}_dagger_l_blade".to_sym] = Rectangle.new(
      x: center_x - size * 0.25,
      y: center_y + size * 0.1,
      width: size * 0.03,
      height: size * 0.2,
      color: [240 * mult, 240 * mult, 240 * mult, 1.0]
    )
    # Блики на лезвии
    @shapes["hero_#{index}_dagger_l_shine".to_sym] = Rectangle.new(
      x: center_x - size * 0.245,
      y: center_y + size * 0.12,
      width: size * 0.015,
      height: size * 0.16,
      color: [255, 255, 255, 0.7]
    )
    @shapes["hero_#{index}_dagger_l_guard".to_sym] = Rectangle.new(
      x: center_x - size * 0.26,
      y: center_y + size * 0.28,
      width: size * 0.05,
      height: size * 0.02,
      color: [180 * mult, 180 * mult, 180 * mult, 1.0]
    )
    @shapes["hero_#{index}_dagger_l_handle".to_sym] = Rectangle.new(
      x: center_x - size * 0.26,
      y: center_y + size * 0.3,
      width: size * 0.05,
      height: size * 0.06,
      color: [139 * mult, 69 * mult, 19 * mult, 1.0]
    )
    # Правый кинжал (в руке)
    @shapes["hero_#{index}_dagger_r_blade".to_sym] = Rectangle.new(
      x: center_x + size * 0.22,
      y: center_y + size * 0.1,
      width: size * 0.03,
      height: size * 0.2,
      color: [240 * mult, 240 * mult, 240 * mult, 1.0]
    )
    # Блики на лезвии
    @shapes["hero_#{index}_dagger_r_shine".to_sym] = Rectangle.new(
      x: center_x + size * 0.225,
      y: center_y + size * 0.12,
      width: size * 0.015,
      height: size * 0.16,
      color: [255, 255, 255, 0.7]
    )
    @shapes["hero_#{index}_dagger_r_guard".to_sym] = Rectangle.new(
      x: center_x + size * 0.21,
      y: center_y + size * 0.28,
      width: size * 0.05,
      height: size * 0.02,
      color: [180 * mult, 180 * mult, 180 * mult, 1.0]
    )
    @shapes["hero_#{index}_dagger_r_handle".to_sym] = Rectangle.new(
      x: center_x + size * 0.21,
      y: center_y + size * 0.3,
      width: size * 0.05,
      height: size * 0.06,
      color: [139 * mult, 69 * mult, 19 * mult, 1.0]
    )
    
    # Голова
    @shapes["hero_#{index}_head".to_sym] = Circle.new(
      x: center_x,
      y: center_y - size * 0.2,
      radius: size * 0.11,
      color: [245 * mult, 222 * mult, 179 * mult, 1.0]
    )
    # Маска (нижняя часть лица) - более детальная
    @shapes["hero_#{index}_mask_base".to_sym] = Rectangle.new(
      x: center_x - size * 0.08,
      y: center_y - size * 0.12,
      width: size * 0.16,
      height: size * 0.08,
      color: [30 * mult, 30 * mult, 30 * mult, 1.0]
    )
    @shapes["hero_#{index}_mask".to_sym] = Rectangle.new(
      x: center_x - size * 0.07,
      y: center_y - size * 0.11,
      width: size * 0.14,
      height: size * 0.06,
      color: [47 * mult, 47 * mult, 47 * mult, 1.0]
    )
    # Прорези в маске
    @shapes["hero_#{index}_mask_hole_1".to_sym] = Circle.new(
      x: center_x - size * 0.03,
      y: center_y - size * 0.08,
      radius: size * 0.01,
      color: [20, 20, 20, 0.5]
    )
    @shapes["hero_#{index}_mask_hole_2".to_sym] = Circle.new(
      x: center_x + size * 0.03,
      y: center_y - size * 0.08,
      radius: size * 0.01,
      color: [20, 20, 20, 0.5]
    )
    # Капюшон - более детальный
    @shapes["hero_#{index}_hood_base".to_sym] = Circle.new(
      x: center_x,
      y: center_y - size * 0.22,
      radius: size * 0.14,
      color: [30 * mult, 30 * mult, 30 * mult, 1.0]
    )
    @shapes["hero_#{index}_hood".to_sym] = Circle.new(
      x: center_x,
      y: center_y - size * 0.23,
      radius: size * 0.13,
      color: [47 * mult, 47 * mult, 47 * mult, 1.0]
    )
    # Складки на капюшоне
    @shapes["hero_#{index}_hood_fold_1".to_sym] = Rectangle.new(
      x: center_x - size * 0.1,
      y: center_y - size * 0.2,
      width: size * 0.2,
      height: size * 0.015,
      color: [30 * mult, 30 * mult, 30 * mult, 0.8]
    )
    @shapes["hero_#{index}_hood_fold_2".to_sym] = Rectangle.new(
      x: center_x - size * 0.08,
      y: center_y - size * 0.26,
      width: size * 0.16,
      height: size * 0.015,
      color: [30 * mult, 30 * mult, 30 * mult, 0.8]
    )
    # Глаза (видны через прорези) - более яркие
    @shapes["hero_#{index}_eye_glow_l".to_sym] = Circle.new(
      x: center_x - size * 0.05,
      y: center_y - size * 0.18,
      radius: size * 0.025,
      color: [100, 150, 255, 0.4]
    )
    @shapes["hero_#{index}_eye_l".to_sym] = Circle.new(
      x: center_x - size * 0.05,
      y: center_y - size * 0.18,
      radius: size * 0.02,
      color: [100, 150, 255, 1.0]
    )
    @shapes["hero_#{index}_eye_glow_r".to_sym] = Circle.new(
      x: center_x + size * 0.05,
      y: center_y - size * 0.18,
      radius: size * 0.025,
      color: [100, 150, 255, 0.4]
    )
    @shapes["hero_#{index}_eye_r".to_sym] = Circle.new(
      x: center_x + size * 0.05,
      y: center_y - size * 0.18,
      radius: size * 0.02,
      color: [100, 150, 255, 1.0]
    )
  end

  def wrap_text(text, max_width, font_size)
    # Простой перенос текста по словам
    words = text.split(' ')
    lines = []
    current_line = ''
    
    words.each do |word|
      test_line = current_line.empty? ? word : "#{current_line} #{word}"
      # Приблизительная ширина текста (примерно 0.6 * font_size на символ)
      estimated_width = test_line.length * font_size * 0.6
      
      if estimated_width > max_width && !current_line.empty?
        lines << current_line
        current_line = word
      else
        current_line = test_line
      end
    end
    
    lines << current_line unless current_line.empty?
    lines.join("\n")
  end

  def create_background_decorations
    # Создаем декоративные элементы - звезды
    30.times do |i|
      x = (i * @window_width / 30) + rand(50)
      y = rand(@window_height * 0.6) # Только верхняя часть
      size = rand(2) + 1
      brightness = 0.3 + rand * 0.4
      @shapes["star_#{i}".to_sym] = Circle.new(
        x: x, y: y,
        radius: size,
        color: [255, 255, 255, brightness]
      )
    end
  end

  def update_display
    # Удаляем старые карточки героев (включая иконки)
    @shapes.select { |k, _| k.to_s.start_with?('hero_') || k.to_s.start_with?('flame_') }.each do |_, shape|
      shape.remove if shape.respond_to?(:remove)
    end
    @shapes.reject! { |k, _| k.to_s.start_with?('hero_') || k.to_s.start_with?('flame_') }
    
    @texts.select { |k, _| k.to_s.start_with?('hero_') }.each do |_, text|
      text.remove
    end
    @texts.reject! { |k, _| k.to_s.start_with?('hero_') }

    # Создаем карточки героев
    @heroes.each_with_index do |hero_key, index|
      hero_data = HEROES[hero_key]
      card_x = @window_width / 2 - 450 + index * 350
      card_y = @window_height / 2 - 120
      selected = index == @selected_index

      create_hero_card(hero_key, hero_data, card_x, card_y, index, selected)
    end
  end

  def create_hero_card(hero_key, hero_data, x, y, index, selected)
    card_width = 320
    card_height = 420

    # Внешняя рамка с эффектом свечения
    if selected
      # Множественные слои для эффекта свечения
      3.times do |i|
        glow_size = 10 + i * 5
        alpha = 0.3 - i * 0.1
        @shapes["hero_#{index}_glow_#{i}".to_sym] = Rectangle.new(
          x: x - glow_size,
          y: y - glow_size,
          width: card_width + glow_size * 2,
          height: card_height + glow_size * 2,
          color: [255, 100 + i * 20, 0, alpha]
        )
      end
    end

    # Основной фон карточки
    bg_color = selected ? [40, 20, 10, 0.95] : [20, 20, 30, 0.85]
    @shapes["hero_#{index}_bg".to_sym] = Rectangle.new(
      x: x,
      y: y,
      width: card_width,
      height: card_height,
      color: bg_color
    )

    # Внутренняя рамка
    border_color = selected ? [255, 150, 0, 0.8] : [100, 100, 120, 0.6]
    @shapes["hero_#{index}_border".to_sym] = Rectangle.new(
      x: x + 5,
      y: y + 5,
      width: card_width - 10,
      height: card_height - 10,
      color: border_color
    )

    # Внутренний фон
    inner_bg = selected ? [60, 30, 15, 0.9] : [30, 30, 40, 0.8]
    @shapes["hero_#{index}_inner".to_sym] = Rectangle.new(
      x: x + 10,
      y: y + 10,
      width: card_width - 20,
      height: card_height - 20,
      color: inner_bg
    )

    # Эффект пламени для выбранного героя
    if selected
      create_flame_effect(index, x, y, card_width, card_height)
    end

    # Иконка героя (создаем программно - полноценный портрет)
    create_hero_icon(index, hero_key, x, y, card_width, card_height, selected)

    # Имя героя
    name_color = selected ? '#FFD700' : '#FFFFFF'
    name_size = selected ? 42 : 36
    @texts["hero_#{index}_name".to_sym] = Text.new(
      hero_data[:name],
      x: x + card_width / 2,
      y: y + 150,
      size: name_size,
      color: name_color,
      font: nil
    )
    @texts["hero_#{index}_name".to_sym].x = x + card_width / 2 - @texts["hero_#{index}_name".to_sym].width / 2

    # Описание (с переносом строк)
    desc_text = wrap_text(hero_data[:description], card_width - 40, 16)
    desc_lines = desc_text.split("\n")
    desc_lines.each_with_index do |line, line_idx|
      @texts["hero_#{index}_desc_#{line_idx}".to_sym] = Text.new(
        line,
        x: x + card_width / 2,
        y: y + 200 + line_idx * 20,
        size: 16,
        color: '#CCCCCC',
        font: nil
      )
      @texts["hero_#{index}_desc_#{line_idx}".to_sym].x = x + card_width / 2 - @texts["hero_#{index}_desc_#{line_idx}".to_sym].width / 2
    end

    # Статистика в красивом формате
    stats_y = y + 200 + desc_lines.length * 20 + 10
    stats = [
      ["[H]", "Здоровье", hero_data[:stats][:health]],
      ["[S]", "Скорость", hero_data[:stats][:speed]],
      ["[W]", "Урон", hero_data[:stats][:damage]],
      ["[D]", "Броня", "#{(hero_data[:stats][:armor] * 100).to_i}%"]
    ]

    stats.each_with_index do |(icon, label, value), i|
      stat_text = "#{icon} #{label}: #{value}"
      @texts["hero_#{index}_stat_#{i}".to_sym] = Text.new(
        stat_text,
        x: x + 20,
        y: stats_y + i * 25,
        size: 16,
        color: '#AAAAAA',
        font: nil
      )
    end

    # Стартовое оружие
    weapon_name = case hero_data[:starting_weapon]
    when :whip then "Кнут"
    when :magic_wand then "Магическая палочка"
    when :knife then "Нож"
    else "Оружие"
    end

    weapon_y = stats_y + stats.length * 25 + 10
    @texts["hero_#{index}_weapon".to_sym] = Text.new(
      "[W] Стартовое оружие: #{weapon_name}",
      x: x + card_width / 2,
      y: weapon_y,
      size: 16,
      color: selected ? '#FFD700' : '#FFA500',
      font: nil
    )
    @texts["hero_#{index}_weapon".to_sym].x = x + card_width / 2 - @texts["hero_#{index}_weapon".to_sym].width / 2
  end

  def create_flame_effect(index, x, y, width, height)
    # Создаем частицы пламени вокруг выбранной карточки
    particle_count = 15
    particle_count.times do |i|
      angle = (i.to_f / particle_count) * 2 * Math::PI
      base_radius = [width, height].max / 2 + 20
      
      @flame_particles["#{index}_#{i}".to_sym] = {
        angle: angle,
        base_radius: base_radius,
        offset: rand * 10,
        speed: 0.5 + rand * 0.5,
        size: 3 + rand * 3,
        alpha: 0.6 + rand * 0.4
      }
    end
  end

  def update(delta_time = 0.016)
    @animation_time += delta_time
    
    # Обновляем спрайты персонажей
    @hero_sprites.each do |index, sprite|
      next unless sprite
      sprite.update(delta_time, false, false, false, nil) # idle состояние
    end
    
    # Обновляем эффект пламени
    @flame_particles.each do |key, particle|
      particle[:offset] += particle[:speed] * delta_time * 20
      particle[:angle] += delta_time * 0.5
      
      # Создаем/обновляем визуальные частицы
      index = key.to_s.split('_').first.to_i
      i = key.to_s.split('_').last.to_i
      
      if @selected_index == index
        radius = particle[:base_radius] + Math.sin(@animation_time * 2 + particle[:offset]) * 5
        px = @window_width / 2 - 450 + index * 350 + 160 + Math.cos(particle[:angle]) * radius
        py = @window_height / 2 - 120 + 210 + Math.sin(particle[:angle]) * radius
        
        flame_key = "flame_#{key}".to_sym
        if @shapes[flame_key]
          @shapes[flame_key].x = px
          @shapes[flame_key].y = py
          # Пульсация размера
          current_size = particle[:size] + Math.sin(@animation_time * 3) * 2
          @shapes[flame_key].radius = [current_size, 1].max
          # Пульсация яркости
          alpha = particle[:alpha] + Math.sin(@animation_time * 4) * 0.2
          r = 1.0
          g = 0.3 + Math.sin(@animation_time * 2) * 0.2
          b = 0.0
          @shapes[flame_key].color = [r * 255, g * 255, b * 255, alpha]
        else
          @shapes[flame_key] = Circle.new(
            x: px, y: py,
            radius: particle[:size],
            color: [255, 100, 0, particle[:alpha]]
          )
        end
      else
        # Удаляем частицы для невыбранных карточек
        @shapes["flame_#{key}".to_sym]&.remove
        @shapes.delete("flame_#{key}".to_sym)
      end
    end

    # Обновляем огненный фон
    if @fire_particles
      @fire_particles.each_with_index do |particle, i|
        particle[:y] -= particle[:speed] * delta_time
        particle[:life] -= delta_time
        particle[:flicker] += delta_time * 5
        
        # Пересоздаем частицу если она ушла вверх или умерла
        if particle[:y] < @window_height - 150 || particle[:life] <= 0
          particle[:x] = rand(@window_width)
          particle[:y] = @window_height - 30 + rand(50)
          particle[:life] = particle[:max_life]
          particle[:flicker] = rand * Math::PI * 2
        end
        
        # Обновляем визуальную частицу
        fire_key = "bg_fire_#{i}".to_sym
        life_ratio = particle[:life] / particle[:max_life]
        
        # Пульсация размера
        flicker_size = 1.0 + Math.sin(particle[:flicker]) * 0.3
        size = particle[:size] * (0.6 + life_ratio * 0.4) * flicker_size
        
        # Цвет от красного к оранжевому к желтому (более реалистичный)
        color_progress = 1.0 - life_ratio
        r = 1.0
        g = 0.2 + color_progress * 0.6
        b = color_progress * 0.3
        alpha = 0.4 + life_ratio * 0.5
        
        # Движение частицы (покачивание)
        offset_x = Math.sin(@animation_time * 3 + particle[:color_offset]) * 8
        offset_y = Math.sin(@animation_time * 2 + particle[:color_offset] * 2) * 3
        
        if @shapes[fire_key]
          @shapes[fire_key].x = particle[:x] + offset_x
          @shapes[fire_key].y = particle[:y] + offset_y
          @shapes[fire_key].radius = [size, 2].max
          @shapes[fire_key].color = [r * 255, g * 255, b * 255, alpha]
        else
          @shapes[fire_key] = Circle.new(
            x: particle[:x],
            y: particle[:y],
            radius: size,
            color: [r * 255, g * 255, b * 255, alpha]
          )
        end
      end
    end

    # Обновляем звезды на фоне
    @shapes.select { |k, _| k.to_s.start_with?('star_') }.each do |key, star|
      star.y += delta_time * 10
      if star.y > @window_height
        star.y = -10
        star.x = rand(@window_width)
      end
    end
  end

  def handle_key_down(key)
    case key
    when 'left', 'a'
      @selected_index = (@selected_index - 1) % @heroes.length
      update_display
    when 'right', 'd'
      @selected_index = (@selected_index + 1) % @heroes.length
      update_display
    when 'return', 'enter'
      return select_hero
    end
    nil
  end

  def handle_mouse_click(x, y)
    @heroes.each_with_index do |hero_key, index|
      card_x = @window_width / 2 - 450 + index * 350
      card_y = @window_height / 2 - 120
      
      if x >= card_x && x <= card_x + 320 && y >= card_y && y <= card_y + 420
        @selected_index = index
        update_display
        return select_hero
      end
    end
    nil
  end

  def select_hero
    hero_key = @heroes[@selected_index]
    HEROES[hero_key]
  end

  def draw
    # Все рисуется через shapes и texts
  end

  def remove
    @shapes.values.each { |s| s.remove if s.respond_to?(:remove) }
    @texts.values.each(&:remove)
    @hero_sprites.values.each { |sprite| sprite&.remove }
    @hero_sprites.clear
    @fire_particles = nil
    @flame_particles = {}
  end
end
