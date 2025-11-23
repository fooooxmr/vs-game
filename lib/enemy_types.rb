# Типы врагов и их характеристики
module EnemyTypes
  ENEMY_TYPES = {
    # Базовые мобы (появляются с начала)
    skeleton: {
      name: "Скелет",
      health: 30,
      speed: 60,
      damage: 5,
      attack_range: 25,
      attack_cooldown: 1.0,
      experience: 2,
      gold_chance: 0.3,
      gold_amount: (1..3),
      spawn_time: 0, # Появляется с начала
      sprite_type: :enemy
    },
    bat: {
      name: "Летучая мышь",
      health: 20,
      speed: 90,
      damage: 3,
      attack_range: 20,
      attack_cooldown: 0.8,
      experience: 1,
      gold_chance: 0.2,
      gold_amount: (1..2),
      spawn_time: 0,
      sprite_type: :enemy
    },
    
    # Средние мобы (появляются после 2 минут)
    ghost: {
      name: "Призрак",
      health: 50,
      speed: 70,
      damage: 7,
      attack_range: 30,
      attack_cooldown: 1.2,
      experience: 4,
      gold_chance: 0.4,
      gold_amount: (2..4),
      spawn_time: 120, # 2 минуты
      sprite_type: :enemy
    },
    zombie: {
      name: "Зомби",
      health: 80,
      speed: 40,
      damage: 10,
      attack_range: 30,
      attack_cooldown: 1.5,
      experience: 5,
      gold_chance: 0.5,
      gold_amount: (2..5),
      spawn_time: 120,
      sprite_type: :enemy
    },
    
    # Сильные мобы (появляются после 5 минут)
    knight: {
      name: "Рыцарь-скелет",
      health: 150,
      speed: 50,
      damage: 18,  # Улучшено с 15 до 18
      attack_range: 160,  # Дальнобойная атака (кнут 80, значит 80*2=160)
      attack_cooldown: 1.6,  # Улучшено с 1.8 до 1.6
      experience: 10,
      gold_chance: 0.6,
      gold_amount: (5..10),
      spawn_time: 300, # 5 минут
      sprite_type: :enemy,
      ranged: true  # Дальнобойный враг
    },
    mage: {
      name: "Маг-скелет",
      health: 100,
      speed: 45,
      damage: 24,  # Улучшено с 20 до 24
      attack_range: 200,  # Дальнобойная атака (больше чем у бандита)
      attack_cooldown: 1.8,  # Улучшено с 2.0 до 1.8
      experience: 12,
      gold_chance: 0.7,
      gold_amount: (5..12),
      spawn_time: 300,
      sprite_type: :enemy,
      ranged: true # Дальнобойный враг
    },
    
    # Элитные мобы (вызываются через алтари)
    elite_knight: {
      name: "Элитный рыцарь",
      health: 300,
      speed: 60,
      damage: 25,
      attack_range: 30,  # Уменьшено - ближний бой, как у обычных мобов
      attack_cooldown: 1.5,
      experience: 30,
      gold_chance: 1.0,
      gold_amount: (20..40),
      spawn_time: -1, # Только через алтари
      sprite_type: :enemy,
      elite: true,
      area_attack: false,  # Ближний бой, не атака по области
      special_attacks: true  # Специальные атаки с индикацией
    },
    elite_mage: {
      name: "Элитный маг",
      health: 250,
      speed: 55,
      damage: 30,
      attack_range: 200,
      attack_cooldown: 1.8,
      experience: 35,
      gold_chance: 1.0,
      gold_amount: (25..50),
      spawn_time: -1,
      sprite_type: :enemy,
      elite: true,
      ranged: true,
      area_attack: true
    },
    
    # Боссы (появляются автоматически каждые 3 минуты) - УСИЛЕНЫ
    boss: {
      name: "Босс",
      health: 1000,  # Увеличено с 500
      speed: 55,     # Увеличено с 45
      damage: 50,    # Увеличено с 30
      attack_range: 100,  # Увеличено с 80
      attack_cooldown: 1.2,  # Уменьшено с 1.5 (атакует чаще)
      experience: 75,  # Увеличено с 50
      gold_chance: 1.0,
      gold_amount: (50..100),  # Увеличено с 30..60
      spawn_time: 180, # 3 минуты
      sprite_type: :enemy,
      boss: true,
      area_attack: true,
      special_attacks: true
    },
    # Финальный босс (только через портал) - ОЧЕНЬ СИЛЬНЫЙ
    final_boss: {
      name: "Повелитель тьмы",
      health: 5000,  # Увеличено с 2000
      speed: 50,     # Увеличено с 40
      damage: 100,   # Увеличено с 50
      attack_range: 150,  # Увеличено с 100
      attack_cooldown: 1.5,  # Уменьшено с 2.0
      experience: 500,  # Увеличено с 200
      gold_chance: 1.0,
      gold_amount: (200..400),  # Увеличено с 100..200
      spawn_time: -1, # Только через портал
      sprite_type: :enemy,
      boss: true,
      area_attack: true,
      special_attacks: true # Специальные атаки
    }
  }.freeze
  
  # Получить типы врагов, доступные в данное время
  def self.available_types(game_time)
    ENEMY_TYPES.select { |_, data| data[:spawn_time] >= 0 && game_time >= data[:spawn_time] }
  end
  
  # Получить данные типа врага
  def self.get_type(type)
    ENEMY_TYPES[type] || ENEMY_TYPES[:skeleton]
  end
  
  # Получить элитные типы
  def self.elite_types
    ENEMY_TYPES.select { |_, data| data[:elite] }
  end
  
  # Получить боссов
  def self.boss_types
    ENEMY_TYPES.select { |_, data| data[:boss] }
  end
end

