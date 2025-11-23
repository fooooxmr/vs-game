class Passive
  attr_accessor :level, :max_level, :type, :name, :icon

  def initialize(type)
    @type = type
    @level = 0
    initialize_passive_stats
  end

  def initialize_passive_stats
    case @type
    when :move_speed
      @name = "Скорость движения"
      @icon = "🏃"
      @max_level = 5
      @bonus_per_level = 0.1 # +10% за уровень
    when :max_health
      @name = "Макс. здоровье"
      @icon = "❤️"
      @max_level = 5
      @bonus_per_level = 0.2 # +20% за уровень
    when :armor
      @name = "Броня"
      @icon = "🛡️"
      @max_level = 5
      @bonus_per_level = 0.1 # +10% за уровень
    when :cooldown_reduction
      @name = "Снижение кулдауна"
      @icon = "⚡"
      @max_level = 5
      @bonus_per_level = 0.08 # -8% за уровень
    when :area
      @name = "Область"
      @icon = "📏"
      @max_level = 5
      @bonus_per_level = 0.15 # +15% за уровень
    when :duration
      @name = "Длительность"
      @icon = "⏱️"
      @max_level = 5
      @bonus_per_level = 0.2 # +20% за уровень
    when :amount
      @name = "Количество"
      @icon = "🔢"
      @max_level = 5
      @bonus_per_level = 1 # +1 снаряд за уровень
    when :magnet
      @name = "Магнит"
      @icon = "🧲"
      @max_level = 5
      @bonus_per_level = 20 # +20 пикселей радиуса за уровень
    when :luck
      @name = "Удача"
      @icon = "🍀"
      @max_level = 5
      @bonus_per_level = 0.1 # +10% за уровень
    when :growth
      @name = "Рост"
      @icon = "📈"
      @max_level = 5
      @bonus_per_level = 0.1 # +10% опыта за уровень
    end
  end

  def upgrade
    return false if @level >= @max_level
    @level += 1
    true
  end

  def get_bonus
    @level * @bonus_per_level
  end

  def name
    @name || "Пассив"
  end

  def icon
    @icon || "⭐"
  end

  def max_level?
    @level >= @max_level
  end
end

