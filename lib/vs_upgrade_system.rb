require_relative 'weapon'
require_relative 'passive'

class VSUpgradeSystem
  WEAPON_TYPES = [:whip, :magic_wand, :knife, :axe, :cross, :garlic].freeze
  PASSIVE_TYPES = [:move_speed, :max_health, :armor, :cooldown_reduction, :area, :duration, :amount, :magnet, :luck, :growth].freeze

  def initialize(player)
    @player = player
  end

  # Получить улучшения только для уровня (только улучшения существующего оружия/пассивов)
  def get_level_upgrades(count = 3)
    upgrades = []
    
    # Только улучшения существующего оружия (не новые)
    @player.weapons.each do |weapon|
      if weapon.level < weapon.max_level
        upgrades << {
          type: :weapon_upgrade,
          weapon_type: weapon.type,
          weapon: weapon,
          name: weapon.name,
          icon: weapon.icon,
          level: weapon.level,
          max_level: weapon.max_level
        }
      end
    end
    
    # Только улучшения существующих пассивов (не новые)
    @player.passives.each do |passive|
      if passive.level < passive.max_level
        upgrades << {
          type: :passive_upgrade,
          passive_type: passive.type,
          passive: passive,
          name: passive.name,
          icon: passive.icon,
          level: passive.level,
          max_level: passive.max_level
        }
      end
    end
    
    # Возвращаем случайные улучшения
    upgrades.sample([count, upgrades.size].min)
  end

  # Получить улучшения для сундуков (новое оружие, новые пассивные, опыт, золото)
  def get_chest_rewards
    rewards = []
    
    # Новое оружие (40% шанс)
    if rand < 0.4
      available_weapons = WEAPON_TYPES.select do |weapon_type|
        !@player.weapons.find { |w| w.type == weapon_type }
      end
      if !available_weapons.empty?
        weapon_type = available_weapons.sample
        weapon = Weapon.new(weapon_type)
        rewards << {
          type: :new_weapon,
          weapon_type: weapon_type,
          weapon: weapon,
          name: weapon.name,
          icon: weapon.icon
        }
      end
    end
    
    # Новое пассивное улучшение (40% шанс)
    if rand < 0.4
      available_passives = PASSIVE_TYPES.select do |passive_type|
        !@player.passives.find { |p| p.type == passive_type }
      end
      if !available_passives.empty?
        passive_type = available_passives.sample
        passive = Passive.new(passive_type)
        rewards << {
          type: :new_passive,
          passive_type: passive_type,
          passive: passive,
          name: passive.name,
          icon: passive.icon
        }
      end
    end
    
    # Опыт (всегда)
    rewards << {
      type: :experience,
      amount: 50 + rand(100)
    }
    
    # Золото (всегда, но разное количество)
    rewards << {
      type: :gold,
      amount: 20 + rand(50)
    }
    
    rewards
  end

  def get_available_upgrades(count = 3)
    upgrades = []
    
    # Собираем доступные улучшения
    available_weapons = WEAPON_TYPES.select do |weapon_type|
      existing = @player.weapons.find { |w| w.type == weapon_type }
      !existing || existing.level < existing.max_level
    end
    
    available_passives = PASSIVE_TYPES.select do |passive_type|
      existing = @player.passives.find { |p| p.type == passive_type }
      !existing || existing.level < existing.max_level
    end
    
    # Создаем список улучшений
    available_weapons.each do |weapon_type|
      existing = @player.weapons.find { |w| w.type == weapon_type }
      if existing
        upgrades << {
          type: :weapon_upgrade,
          weapon_type: weapon_type,
          weapon: existing,
          name: existing.name,
          icon: existing.icon,
          level: existing.level,
          max_level: existing.max_level
        }
      else
        weapon = Weapon.new(weapon_type)
        upgrades << {
          type: :new_weapon,
          weapon_type: weapon_type,
          weapon: weapon,
          name: weapon.name,
          icon: weapon.icon,
          level: 0,
          max_level: weapon.max_level
        }
      end
    end
    
    available_passives.each do |passive_type|
      existing = @player.passives.find { |p| p.type == passive_type }
      if existing
        upgrades << {
          type: :passive_upgrade,
          passive_type: passive_type,
          passive: existing,
          name: existing.name,
          icon: existing.icon,
          level: existing.level,
          max_level: existing.max_level
        }
      else
        passive = Passive.new(passive_type)
        upgrades << {
          type: :new_passive,
          passive_type: passive_type,
          passive: passive,
          name: passive.name,
          icon: passive.icon,
          level: 0,
          max_level: passive.max_level
        }
      end
    end
    
    # Возвращаем случайные улучшения
    upgrades.sample([count, upgrades.size].min)
  end

  def apply_upgrade(upgrade_data)
    case upgrade_data[:type]
    when :new_weapon, :weapon_upgrade
      existing = @player.weapons.find { |w| w.type == upgrade_data[:weapon_type] }
      if existing
        existing.upgrade
      else
        @player.add_weapon(upgrade_data[:weapon_type])
      end
    when :new_passive, :passive_upgrade
      @player.add_passive(upgrade_data[:passive_type])
    end
  end
end

