class UpgradeSystem
  UPGRADES = {
    damage: {
      name: 'Урон',
      description: 'Увеличивает урон атаки на 25%',
      icon: '⚔️',
      max_level: 10
    },
    attack_speed: {
      name: 'Скорость атаки',
      description: 'Уменьшает время между атаками на 10%',
      icon: '⚡',
      max_level: 10
    },
    attack_range: {
      name: 'Дальность атаки',
      description: 'Увеличивает дальность атаки на 15%',
      icon: '📏',
      max_level: 8
    },
    health: {
      name: 'Здоровье',
      description: 'Увеличивает максимальное здоровье на 20%',
      icon: '❤️',
      max_level: 10
    },
    speed: {
      name: 'Скорость',
      description: 'Увеличивает скорость движения на 10%',
      icon: '🏃',
      max_level: 8
    },
    health_regen: {
      name: 'Регенерация',
      description: 'Восстанавливает здоровье со временем',
      icon: '💚',
      max_level: 5
    },
    crit_chance: {
      name: 'Критический удар',
      description: 'Шанс нанести двойной урон',
      icon: '💥',
      max_level: 5
    },
    armor: {
      name: 'Броня',
      description: 'Уменьшает получаемый урон на 10%',
      icon: '🛡️',
      max_level: 5
    }
  }.freeze

  attr_accessor :upgrade_levels

  def initialize
    @upgrade_levels = {}
    UPGRADES.each_key { |key| @upgrade_levels[key] = 0 }
  end

  def get_upgrade_level(upgrade_type)
    @upgrade_levels[upgrade_type] || 0
  end

  def can_upgrade?(upgrade_type)
    level = get_upgrade_level(upgrade_type)
    max_level = UPGRADES[upgrade_type][:max_level]
    level < max_level
  end

  def upgrade(upgrade_type)
    return false unless can_upgrade?(upgrade_type)
    @upgrade_levels[upgrade_type] += 1
    true
  end

  def get_available_upgrades(count = 3)
    available = UPGRADES.select { |key, _| can_upgrade?(key) }
    available.to_a.sample([count, available.size].min).to_h
  end

  def apply_upgrades(player)
    # Урон
    base_damage = 10
    damage_multiplier = 1.0 + (get_upgrade_level(:damage) * 0.25)
    player.base_damage = (base_damage * damage_multiplier).round

    # Скорость атаки
    base_cooldown = 0.5
    speed_multiplier = 1.0 - (get_upgrade_level(:attack_speed) * 0.1)
    player.attack_cooldown = [base_cooldown * speed_multiplier, 0.1].max

    # Дальность атаки
    base_range = 50
    range_multiplier = 1.0 + (get_upgrade_level(:attack_range) * 0.15)
    player.attack_range = (base_range * range_multiplier).round

    # Здоровье
    base_health = 100
    health_multiplier = 1.0 + (get_upgrade_level(:health) * 0.2)
    new_max_health = (base_health * health_multiplier).round
    if new_max_health > player.max_health
      health_diff = new_max_health - player.max_health
      player.max_health = new_max_health
      player.health += health_diff # Восстанавливаем разницу
    end

    # Скорость движения
    base_speed = 120
    speed_multiplier = 1.0 + (get_upgrade_level(:speed) * 0.1)
    player.speed = (base_speed * speed_multiplier).round

    # Регенерация здоровья
    player.health_regen_rate = get_upgrade_level(:health_regen) * 0.5 # HP в секунду

    # Критический удар
    player.crit_chance = get_upgrade_level(:crit_chance) * 0.1 # 10% за уровень

    # Броня
    player.armor = get_upgrade_level(:armor) * 0.1 # 10% уменьшение урона за уровень
  end
end

