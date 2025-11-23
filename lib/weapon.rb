class Weapon
  attr_accessor :level, :damage, :cooldown, :last_attack_time, :range, :amount, :area, :duration, :type, :max_level, :name, :icon

  def initialize(type)
    @type = type
    @level = 0
    @damage = 10
    @cooldown = 1.0
    @last_attack_time = 0
    @range = 100
    @amount = 1 # Количество снарядов
    @area = 1.0 # Радиус области
    @duration = 1.0 # Длительность эффекта
    @projectiles = []
    @max_level = 8
    initialize_weapon_stats
  end

  def initialize_weapon_stats
    case @type
    when :whip
      @damage = 20
      @cooldown = 0.8
      @range = 80
      @name = "Кнут"
      @icon = "⚔️"
    when :magic_wand
      @damage = 5
      @cooldown = 0.3
      @range = 200
      @amount = 1
      @name = "Магическая палочка"
      @icon = "✨"
    when :knife
      @damage = 8
      @cooldown = 0.4
      @range = 150
      @amount = 1
      @name = "Нож"
      @icon = "🔪"
    when :axe
      @damage = 15
      @cooldown = 1.2
      @range = 120
      @name = "Топор"
      @icon = "🪓"
    when :cross
      @damage = 12
      @cooldown = 2.0
      @range = 100
      @name = "Крест"
      @icon = "✝️"
    when :garlic
      @damage = 3
      @cooldown = 0.1
      @range = 50
      @area = 50
      @name = "Чеснок"
      @icon = "🧄"
    end
  end

  def upgrade
    return false if @level >= @max_level
    @level += 1
    apply_level_bonuses
    true
  end

  def apply_level_bonuses
    # Улучшения зависят от уровня
    case @level
    when 1
      @damage *= 1.2
    when 2
      @cooldown *= 0.9
    when 3
      @range *= 1.15
    when 4
      @damage *= 1.2
    when 5
      @amount += 1 if @amount < 5
    when 6
      @cooldown *= 0.9
    when 7
      @damage *= 1.3
    when 8
      @damage *= 1.5
      @cooldown *= 0.8
    end
  end

  def can_attack?(current_time)
    current_time - @last_attack_time >= @cooldown
  end

  def attack(player_x, player_y, enemies, current_time)
    return [] unless can_attack?(current_time)
    
    @last_attack_time = current_time
    projectiles = []

    case @type
    when :whip
      projectiles = whip_attack(player_x, player_y, enemies)
    when :magic_wand
      projectiles = magic_wand_attack(player_x, player_y, enemies)
    when :knife
      projectiles = knife_attack(player_x, player_y, enemies)
    when :axe
      projectiles = axe_attack(player_x, player_y, enemies)
    when :cross
      projectiles = cross_attack(player_x, player_y)
    when :garlic
      projectiles = garlic_attack(player_x, player_y, enemies)
    end

    projectiles
  end

  def whip_attack(player_x, player_y, enemies)
    # Кнут бьет в направлении ближайшего врага
    nearest = enemies.min_by { |e| Math.sqrt((e.x - player_x)**2 + (e.y - player_y)**2) }
    return [] unless nearest

    angle = Math.atan2(nearest.y - player_y, nearest.x - player_x)
    [{ type: :whip, x: player_x, y: player_y, angle: angle, damage: @damage, range: @range }]
  end

  def magic_wand_attack(player_x, player_y, enemies)
    # Магическая палочка стреляет в ближайшего врага
    nearest = enemies.min_by { |e| Math.sqrt((e.x - player_x)**2 + (e.y - player_y)**2) }
    return [] unless nearest

    angle = Math.atan2(nearest.y - player_y, nearest.x - player_x)
    projectiles = []
    @amount.times do
      projectiles << { type: :magic_wand, x: player_x, y: player_y, angle: angle, damage: @damage, speed: 200, range: @range }
    end
    projectiles
  end

  def knife_attack(player_x, player_y, enemies)
    # Нож летит в направлении ближайшего врага
    nearest = enemies.min_by { |e| Math.sqrt((e.x - player_x)**2 + (e.y - player_y)**2) }
    return [] unless nearest

    angle = Math.atan2(nearest.y - player_y, nearest.x - player_x)
    projectiles = []
    @amount.times do |i|
      offset = (i - @amount / 2.0) * 0.1
      projectiles << { type: :knife, x: player_x, y: player_y, angle: angle + offset, damage: @damage, speed: 250, range: @range }
    end
    projectiles
  end

  def axe_attack(player_x, player_y, enemies)
    # Топор летит по дуге
    nearest = enemies.min_by { |e| Math.sqrt((e.x - player_x)**2 + (e.y - player_y)**2) }
    return [] unless nearest

    angle = Math.atan2(nearest.y - player_y, nearest.x - player_x)
    [{ type: :axe, x: player_x, y: player_y, angle: angle, damage: @damage, speed: 150, range: @range, arc: true }]
  end

  def cross_attack(player_x, player_y)
    # Крест вращается вокруг игрока
    [{ type: :cross, x: player_x, y: player_y, damage: @damage, range: @range, orbiting: true }]
  end

  def garlic_attack(player_x, player_y, enemies)
    # Чеснок наносит урон всем врагам в радиусе
    [{ type: :garlic, x: player_x, y: player_y, damage: @damage, range: @range, area: @area }]
  end

  def name
    @name || "Оружие"
  end

  def icon
    @icon || "⚔️"
  end

  def max_level?
    @level >= @max_level
  end
end

