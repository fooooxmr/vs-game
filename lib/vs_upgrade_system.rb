require_relative 'weapon'
require_relative 'passive'

class VSUpgradeSystem
  WEAPON_TYPES = [:whip, :magic_wand, :knife, :axe, :cross, :garlic].freeze
  
  # Базовые пассивки (для уровня): ХП, радиус подбора, броня, скорость, удача, опыт, вампиризм, шанс дропа, урон
  BASE_PASSIVE_TYPES = [:max_health, :magnet, :armor, :move_speed, :luck, :growth, :vampirism, :drop_chance, :damage].freeze
  
  # Уникальные пассивки (для сундуков): влияют на все оружия
  UNIQUE_PASSIVE_TYPES = [:weapon_amount, :weapon_area, :weapon_range, :cooldown_reduction, :duration].freeze
  
  PASSIVE_TYPES = (BASE_PASSIVE_TYPES + UNIQUE_PASSIVE_TYPES).freeze

  def initialize(player)
    @player = player
  end

  # Определить рарность улучшения на основе удачи игрока
  def determine_rarity(luck = 0)
    # Базовые шансы: простое 60%, редкое 25%, эпическое 12%, легендарное 3%
    # Удача увеличивает шансы на более высокую рарность
    luck_bonus = luck * 0.05  # +5% за каждую единицу удачи
    
    roll = rand
    if roll < (0.03 + luck_bonus * 0.5).clamp(0.0, 0.15)  # Легендарное: 3% + бонус удачи
      :legendary
    elsif roll < (0.12 + luck_bonus * 0.3).clamp(0.0, 0.35)  # Эпическое: 12% + бонус удачи
      :epic
    elsif roll < (0.25 + luck_bonus * 0.2).clamp(0.0, 0.50)  # Редкое: 25% + бонус удачи
      :rare
    else
      :common  # Простое: остальное
    end
  end
  
  # Получить множитель качества улучшения на основе рарности
  def get_rarity_multiplier(rarity)
    case rarity
    when :common
      1.0  # Базовое качество
    when :rare
      1.2  # +20% к улучшению
    when :epic
      1.5  # +50% к улучшению
    when :legendary
      2.0  # +100% к улучшению
    else
      1.0
    end
  end
  
  # Получить цвет рарности
  def get_rarity_color(rarity)
    case rarity
    when :common
      '#808080'  # Серый
    when :rare
      '#1E90FF'  # Синий
    when :epic
      '#9932CC'  # Фиолетовый
    when :legendary
      '#FFD700'  # Золотой
    else
      '#808080'
    end
  end
  
  # Получить название рарности
  def get_rarity_name(rarity)
    case rarity
    when :common
      'Простое'
    when :rare
      'Редкое'
    when :epic
      'Эпическое'
    when :legendary
      'Легендарное'
    else
      'Простое'
    end
  end
  
  # Получить улучшения только для уровня (оружие + базовые характеристики)
  def get_level_upgrades(count = 3)
    upgrades = []
    
    # Только улучшения существующего оружия (не новые)
    @player.weapons.each do |weapon|
      if weapon.level < weapon.max_level
        rarity = determine_rarity(@player.luck || 0)
        upgrades << {
          type: :weapon_upgrade,
          weapon_type: weapon.type,
          weapon: weapon,
          name: weapon.name,
          icon: weapon.icon,
          level: weapon.level,
          max_level: weapon.max_level,
          rarity: rarity,
          rarity_multiplier: get_rarity_multiplier(rarity)
        }
      end
    end
    
    # Базовые характеристики (ХП, радиус подбора, броня, скорость, удача, опыт, урон)
    BASE_PASSIVE_TYPES.each do |passive_type|
      existing = @player.passives.find { |p| p.type == passive_type }
      if existing
        if existing.level < existing.max_level
          rarity = determine_rarity(@player.luck || 0)
          upgrades << {
            type: :passive_upgrade,
            passive_type: passive_type,
            passive: existing,
            name: existing.name,
            icon: existing.icon,
            level: existing.level,
            max_level: existing.max_level,
            rarity: rarity,
            rarity_multiplier: get_rarity_multiplier(rarity)
          }
        end
      else
        # Создаем новую базовую пассивку
        passive = Passive.new(passive_type)
        rarity = determine_rarity(@player.luck || 0)
        upgrades << {
          type: :new_passive,
          passive_type: passive_type,
          passive: passive,
          name: passive.name,
          icon: passive.icon,
          level: 0,
          max_level: passive.max_level,
          rarity: rarity,
          rarity_multiplier: get_rarity_multiplier(rarity)
        }
      end
    end
    
    # Возвращаем случайные улучшения
    upgrades.sample([count, upgrades.size].min)
  end

  # Получить улучшения для сундуков (только очень ценные предметы)
  # Сундуки содержат: новые пушки, усиление существующей пушки на 2 уровня, особые усиления (уникальные пассивки)
  def get_chest_rewards
    rewards = []
    
    # Определяем, что дать из сундука (всегда что-то ценное)
    roll = rand
    
    # 1. Новое оружие (50% шанс, если есть доступные)
    available_weapons = WEAPON_TYPES.select do |weapon_type|
      !@player.weapons.find { |w| w.type == weapon_type }
    end
    
    if !available_weapons.empty? && roll < 0.5
      # Даем новое оружие
      weapon_type = available_weapons.sample
      weapon = Weapon.new(weapon_type)
      rarity = determine_rarity(@player.luck || 0)
      rewards << {
        type: :new_weapon,
        weapon_type: weapon_type,
        weapon: weapon,
        name: weapon.name,
        icon: weapon.icon,
        rarity: rarity,
        rarity_multiplier: get_rarity_multiplier(rarity)
      }
    elsif !@player.weapons.empty?
      # 2. Усиление существующей пушки на 2 уровня (50% шанс, если нет новых пушек)
      weapon = @player.weapons.sample
      if weapon && weapon.level < weapon.max_level
        rarity = determine_rarity(@player.luck || 0)
        # Всегда даем +2 уровня в сундуке
        rewards << {
          type: :weapon_upgrade,
          weapon_type: weapon.type,
          weapon: weapon,
          name: weapon.name,
          icon: weapon.icon,
          level: weapon.level,
          max_level: weapon.max_level,
          rarity: rarity,
          rarity_multiplier: 2.0, # Всегда +2 уровня в сундуке
          chest_upgrade: true # Флаг, что это улучшение из сундука
        }
      end
    end
    
    # 3. Особые усиления (уникальные пассивки) - всегда даем одну
    available_passives = UNIQUE_PASSIVE_TYPES.select do |passive_type|
      existing = @player.passives.find { |p| p.type == passive_type }
      !existing || existing.level < existing.max_level
    end
    
    if !available_passives.empty?
      passive_type = available_passives.sample
      existing = @player.passives.find { |p| p.type == passive_type }
      rarity = determine_rarity(@player.luck || 0)
      # В сундуках всегда даем более высокую рарность для пассивок
      rarity = [:rare, :epic, :legendary].sample if rand < 0.7 # 70% шанс на высокую рарность
      
      if existing
        rewards << {
          type: :passive_upgrade,
          passive_type: passive_type,
          passive: existing,
          name: existing.name,
          icon: existing.icon,
          level: existing.level,
          max_level: existing.max_level,
          rarity: rarity,
          rarity_multiplier: get_rarity_multiplier(rarity)
        }
      else
        passive = Passive.new(passive_type, get_rarity_multiplier(rarity))
        rewards << {
          type: :new_passive,
          passive_type: passive_type,
          passive: passive,
          name: passive.name,
          icon: passive.icon,
          rarity: rarity,
          rarity_multiplier: get_rarity_multiplier(rarity)
        }
      end
    end
    
    # Сундуки НЕ дают опыт и золото - только ценные предметы
    # Если ничего не дали (все оружия есть и все пассивки максимального уровня), даем хотя бы опыт
    if rewards.empty?
      rewards << {
        type: :experience,
        amount: 200 + rand(300) # Большой опыт, если все уже есть
      }
    end
    
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
    rarity_multiplier = upgrade_data[:rarity_multiplier] || 1.0
    
    case upgrade_data[:type]
    when :new_weapon, :weapon_upgrade
      existing = @player.weapons.find { |w| w.type == upgrade_data[:weapon_type] }
      if existing
        # Если это улучшение из сундука, всегда даем +2 уровня
        if upgrade_data[:chest_upgrade]
          levels_to_add = 2
        else
          # Рарность влияет на количество уровней, которые даются при улучшении
          # Обычное: +1 уровень, редкое: +1.2 уровня, эпическое: +1.5 уровня, легендарное: +2 уровня
          levels_to_add = case rarity_multiplier
          when 1.0
            1
          when 1.2
            1  # Округляем вниз для редкого
          when 1.5
            2  # Округляем вверх для эпического
          when 2.0
            2  # Легендарное дает +2 уровня
          else
            1
          end
        end
        
        levels_to_add.times do
          break if existing.level >= existing.max_level
          existing.upgrade
        end
      else
        @player.add_weapon(upgrade_data[:weapon_type])
      end
    when :new_passive, :passive_upgrade
      existing = @player.passives.find { |p| p.type == upgrade_data[:passive_type] }
      if existing
        # Обновляем рарность существующей пассивки
        existing.rarity_multiplier = rarity_multiplier
        existing.upgrade
      else
        # Создаем новую пассивку с рарностью
        passive = Passive.new(upgrade_data[:passive_type], rarity_multiplier)
        @player.passives << passive
      end
      # Применяем пассивки после добавления/улучшения
      @player.apply_passives
    end
  end
end

