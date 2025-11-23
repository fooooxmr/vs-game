class Passive
  attr_accessor :level, :max_level, :type, :name, :icon, :rarity_multiplier

  def initialize(type, rarity_multiplier = 1.0)
    @type = type
    @level = 0
    @rarity_multiplier = rarity_multiplier || 1.0
    initialize_passive_stats
  end

  def initialize_passive_stats
    case @type
    when :move_speed
      @name = "Скорость движения"
      @icon = "[S]"
      @max_level = 5
      @bonus_per_level = 0.1 # +10% за уровень
    when :max_health
      @name = "Макс. здоровье"
      @icon = "[H]"
      @max_level = 5
      @bonus_per_level = 0.2 # +20% за уровень
    when :armor
      @name = "Броня"
      @icon = "[D]"
      @max_level = 5
      @bonus_per_level = 0.1 # +10% за уровень
    when :cooldown_reduction
      @name = "Снижение кулдауна"
      @icon = "[C]"
      @max_level = 5
      @bonus_per_level = 0.02 # -2% за уровень (очень слабое улучшение)
    when :area
      @name = "Область"
      @icon = "[A]"
      @max_level = 5
      @bonus_per_level = 0.15 # +15% за уровень
    when :duration
      @name = "Длительность"
      @icon = "[T]"
      @max_level = 5
      @bonus_per_level = 0.2 # +20% за уровень
    when :amount
      @name = "Количество"
      @icon = "[#]"
      @max_level = 5
      @bonus_per_level = 1 # +1 снаряд за уровень
    when :magnet
      @name = "Магнит"
      @icon = "[M]"
      @max_level = 5
      @bonus_per_level = 20 # +20 пикселей радиуса за уровень
    when :luck
      @name = "Удача"
      @icon = "[L]"
      @max_level = 5
      @bonus_per_level = 0.1 # +10% за уровень
    when :growth
      @name = "Рост"
      @icon = "[X]"
      @max_level = 5
      @bonus_per_level = 0.1 # +10% опыта за уровень
    when :weapon_amount
      @name = "Кол-во снарядов"
      @icon = "[#]"
      @max_level = 5
      @bonus_per_level = 0.1 # +0.1 снаряда за уровень (очень слабое улучшение, округление вниз)
    when :weapon_area
      @name = "Размер оружия"
      @icon = "[A]"
      @max_level = 5
      @bonus_per_level = 0.05 # +5% размера за уровень (слабое улучшение)
    when :weapon_range
      @name = "Дальность оружия"
      @icon = "[R]"
      @max_level = 5
      @bonus_per_level = 0.05 # +5% дальности за уровень (слабое улучшение)
    when :vampirism
      @name = "Вампиризм"
      @icon = "[V]"
      @max_level = 5
      @bonus_per_level = 0.05 # +5% шанс вампиризма за уровень
    when :drop_chance
      @name = "Шанс дропа"
      @icon = "[D]"
      @max_level = 5
      @bonus_per_level = 0.02 # +2% шанс дропа за уровень
    when :damage
      @name = "Урон"
      @icon = "[⚔]"
      @max_level = 5
      @bonus_per_level = 0.1 # +10% урона за уровень
    end
  end

  def upgrade
    return false if @level >= @max_level
    @level += 1
    true
  end

  def get_bonus
    (@level * @bonus_per_level * @rarity_multiplier).round(3)
  end
  
  def get_bonus_without_rarity
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

