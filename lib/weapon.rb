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
    
    # Сохраняем базовые значения для применения пассивок
    @base_damage = @damage
    @base_cooldown = @cooldown
    @base_range = @range
    @base_amount = @amount
    @base_area = @area
    @base_duration = @duration
  end

  def initialize_weapon_stats
    case @type
    when :whip
      @damage = 15  # Снижен с 20
      @cooldown = 1.2  # Увеличен с 0.8
      @range = 80
      @name = "Кнут"
      @icon = "[W]"
    when :magic_wand
      @damage = 5
      @cooldown = 1.0  # 1 снаряд в секунду изначально
      @range = 200
      @amount = 1
      @name = "Магическая палочка"
      @icon = "[*]"
    when :knife
      @damage = 8
      @cooldown = 1.0  # 1 снаряд в секунду изначально
      @range = 150
      @amount = 1
      @name = "Нож"
      @icon = "[K]"
    when :axe
      @damage = 15
      @cooldown = 1.2
      @range = 120
      @name = "Топор"
      @icon = "[A]"
    when :cross
      @damage = 12
      @cooldown = 2.0
      @range = 100
      @name = "Крест"
      @icon = "[+]"
    when :garlic
      @damage = 3
      @cooldown = 0.1
      @range = 50
      @area = 50
      @name = "Чеснок"
      @icon = "[G]"
    end
    
    # Сохраняем базовые значения после инициализации
    @base_damage = @damage
    @base_cooldown = @cooldown
    @base_range = @range
    @base_amount = @amount
    @base_area = @area
    @base_duration = @duration
  end

  def upgrade
    return false if @level >= @max_level
    @level += 1
    apply_level_bonuses
    true
  end

  def apply_level_bonuses
    # Этот метод больше не используется напрямую - все улучшения через recalculate_with_level_bonuses
    # Оставляем для совместимости, но не применяем бонусы здесь
    # Все улучшения теперь линейные и применяются в recalculate_with_level_bonuses
  end

  def apply_passive_bonuses(amount: 0, area: 0, range: 0, cooldown_reduction: 0, duration: 0, damage_multiplier: 1.0)
    # Сначала пересчитываем значения с учетом уровня
    recalculate_with_level_bonuses
    
    # Затем применяем бонусы от пассивок
    # Урон (мультипликативно от пассивки урона)
    @damage = (@damage * damage_multiplier).round
    
    # Количество снарядов (аддитивно)
    @amount = @base_amount + amount.to_i
    
    # Область (мультипликативно)
    @area = @base_area * (1.0 + area)
    
    # Дальность (мультипликативно) - ограничиваем максимальный бонус
    max_range_bonus = [range, 0.15].min  # Максимум +15% от пассивок
    @range = (@base_range * (1.0 + max_range_bonus)).round
    
    # Снижение кулдауна (мультипликативно, уменьшает кулдаун)
    # Ограничиваем максимальное снижение кулдауна от пассивок (максимум -15%)
    max_cooldown_reduction = [cooldown_reduction, 0.15].min
    @cooldown = @base_cooldown * (1.0 - max_cooldown_reduction).clamp(0.7, 1.0)
    
    # Длительность (мультипликативно)
    @duration = @base_duration * (1.0 + duration)
  end
  
  def recalculate_with_level_bonuses
    # ВАЖНО: Базовые значения НЕ должны изменяться! Они остаются постоянными
    # Восстанавливаем значения из базовых
    @damage = @base_damage
    @cooldown = @base_cooldown
    @range = @base_range
    @amount = @base_amount
    @area = @base_area
    @duration = @base_duration
    
    # Улучшения от уровня оружия - заметные, но сбалансированные
    # Урон: +5% за уровень (увеличено с 3%)
    damage_bonus = 1.0 + (@level * 0.05)
    @damage = (@base_damage * damage_bonus).round
    
    # Кулдаун: -3% за уровень (увеличено с 2%, минимум 0.5 от базового)
    cooldown_reduction = @level * 0.03
    @cooldown = [@base_cooldown * (1.0 - cooldown_reduction), @base_cooldown * 0.5].max
    
    # Дальность: +12% за уровень (увеличено с 3% до 12%, максимум +100%)
    range_bonus = 1.0 + (@level * 0.12)
    @range = (@base_range * [range_bonus, 2.0].min).round
    
    # Количество снарядов: увеличивается с уровнем для magic_wand и knife
    if @type == :magic_wand || @type == :knife
      # Увеличиваем на 12% за каждый уровень (увеличено с фиксированного +0.5)
      amount_bonus = 1.0 + (@level * 0.12)
      @amount = (@base_amount * amount_bonus).round
      # Максимум 15 снарядов (увеличено с 8)
      @amount = [@amount, 15].min
    end
    
    # НЕ обновляем базовые значения! Они должны оставаться постоянными
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
    # Магическая палочка стреляет в ближайшего врага в радиусе атаки
    return [] if enemies.nil? || enemies.empty?
    
    # Находим ближайшего врага в радиусе атаки
    enemies_in_range = enemies.select do |e|
      next false unless e.alive?
      distance = Math.sqrt((e.x - player_x)**2 + (e.y - player_y)**2)
      distance <= @range
    end
    
    return [] if enemies_in_range.empty?
    
    nearest = enemies_in_range.min_by { |e| Math.sqrt((e.x - player_x)**2 + (e.y - player_y)**2) }
    return [] unless nearest

    angle = Math.atan2(nearest.y - player_y, nearest.x - player_x)
    
    projectiles = []
    @amount.times do
      projectiles << { 
        type: :magic_wand, 
        x: player_x, 
        y: player_y, 
        angle: angle, 
        damage: @damage, 
        speed: 200, 
        range: @range 
      }
    end
    projectiles
  end

  def knife_attack(player_x, player_y, enemies)
    # Нож летит в направлении ближайшего врага
    nearest = enemies.min_by { |e| Math.sqrt((e.x - player_x)**2 + (e.y - player_y)**2) }
    return [] unless nearest

    angle = Math.atan2(nearest.y - player_y, nearest.x - player_x)
    distance = Math.sqrt((nearest.x - player_x)**2 + (nearest.y - player_y)**2)
    
    # Проверяем, что враг в зоне атаки
    return [] unless distance <= @range

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
    @icon || "[W]"
  end

  def max_level?
    @level >= @max_level
  end
end

