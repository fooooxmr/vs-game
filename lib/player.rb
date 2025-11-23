require 'set'
require_relative 'sprite_renderer'
require_relative 'weapon'
require_relative 'passive'

class Player
  attr_accessor :x, :y, :health, :max_health, :attack_range, :attack_cooldown, :last_attack_time, :speed, :keys_pressed,
                :base_damage, :health_regen_rate, :crit_chance, :armor, :level, :experience, :experience_to_next_level,
                :enemies_killed, :time_alive, :weapons, :passives, :experience_magnet_range, :is_attacking, :gold, :luck, :growth, :vampirism, :drop_chance, :size

  def initialize(x, y, hero_data = nil)
    @x = x
    @y = y
    @size = 20
    @keys_pressed = Set.new
    @sprite = nil
    @is_moving = false
    @is_attacking = false
    @took_damage = false
    @last_x = x
    @last_y = y
    
    # Сохраняем hero_data для использования в apply_passives
    @hero_data = hero_data
    
    # Применяем характеристики героя
    if hero_data && hero_data[:stats]
      stats = hero_data[:stats]
      @max_health = stats[:health] || 100
      @health = @max_health  # Устанавливаем здоровье равным максимальному
      @speed = stats[:speed] || 120
      @base_damage = stats[:damage] || 10
      @armor = stats[:armor] || 0
      @sprite_type = hero_data[:sprite_type] || :player
      @starting_weapon = hero_data[:starting_weapon] || :whip
    else
      # Значения по умолчанию
      @max_health = 100
      @health = @max_health  # Устанавливаем здоровье равным максимальному
      @speed = 120
      @base_damage = 10
      @armor = 0
      @sprite_type = :player
      @starting_weapon = :whip
    end
    
    @attack_range = 50
    @attack_cooldown = 0.5 # секунды между атаками
    @last_attack_time = 0
    
    # Система прокачки
    @level = 1
    @experience = 0
    
    # Система золота
    @gold = 0 # Начальное количество золота
    # Более сложная формула для повышения уровня - экспоненциальный рост
    base_exp = 20
    @experience_to_next_level = base_exp
    @health_regen_rate = 0
    @crit_chance = 0
    @last_regen_time = Time.now.to_f
    @enemies_killed = 0
    @time_alive = 0
    
    # Система оружия и пассивов (как в VS)
    @weapons = []
    @passives = []
    @experience_magnet_range = 50 # Радиус сбора опыта
    @luck = 0 # Бонус удачи
    @growth = 0 # Бонус роста опыта
    @vampirism = 0 # Вампиризм (шанс восстановления здоровья при атаке)
    @drop_chance = 0.05 # Базовый шанс дропа (5%)
    
    # Начинаем с стартового оружия героя
    add_weapon(@starting_weapon)
  end

  def add_weapon(type)
    weapon = Weapon.new(type)
    @weapons << weapon
    # Применяем пассивки к новому оружию
    apply_passives
    weapon
  end

  def add_passive(type)
    existing = @passives.find { |p| p.type == type }
    if existing
      existing.upgrade
    else
      passive = Passive.new(type)
      @passives << passive
      passive
    end
    # Применяем пассивки после добавления/улучшения
    apply_passives
  end

  def apply_passives
    # Сохраняем базовое здоровье героя (из hero_data)
    base_hero_health = if @hero_data && @hero_data[:stats] && @hero_data[:stats][:health]
      @hero_data[:stats][:health]
    else
      100
    end
    
    # Сбрасываем базовые значения
    base_speed = 120
    base_max_health = base_hero_health  # Используем здоровье героя как базу
    base_magnet = 50
    
    # Применяем базовые пассивки
    @passives.each do |passive|
      case passive.type
      when :move_speed
        base_speed = base_speed * (1.0 + passive.get_bonus)
      when :max_health
        base_max_health = base_max_health * (1.0 + passive.get_bonus)
      when :armor
        @armor = passive.get_bonus
      when :magnet
        base_magnet = base_magnet + (passive.get_bonus * 20)
      when :luck
        # Удача влияет на шанс получения лучших наград (можно использовать в будущем)
        @luck = passive.get_bonus
      when :growth
        # Рост влияет на получение опыта (применяется в add_experience)
        @growth = passive.get_bonus
      when :vampirism
        # Вампиризм - шанс восстановления здоровья при атаке
        @vampirism = passive.get_bonus
      when :drop_chance
        # Шанс дропа усилений с мобов
        @drop_chance = 0.05 + passive.get_bonus # Базовый 5% + бонус
      when :damage
        # Урон влияет на базовый урон игрока, который применяется ко всем оружиям
        # Сохраняем базовый урон героя
        base_hero_damage = if @hero_data && @hero_data[:stats] && @hero_data[:stats][:damage]
          @hero_data[:stats][:damage]
        else
          10
        end
        @base_damage = (base_hero_damage * (1.0 + passive.get_bonus)).round
      end
    end
    
    # Сохраняем текущий процент здоровья перед изменением max_health
    old_max_health = @max_health
    health_percent = old_max_health > 0 ? @health.to_f / old_max_health : 1.0
    
    @speed = base_speed.round
    @max_health = base_max_health.round
    
    # Если max_health увеличился, восстанавливаем здоровье пропорционально
    if @max_health > old_max_health
      health_increase = @max_health - old_max_health
      @health = [@health + health_increase, @max_health].min
    elsif @max_health < old_max_health
      # Если max_health уменьшился, уменьшаем здоровье пропорционально
      @health = [@health * (@max_health.to_f / old_max_health), @max_health].min
    else
      # Если max_health не изменился, просто ограничиваем здоровье
      @health = [@health, @max_health].min
    end
    
    @experience_magnet_range = base_magnet.round
    
    # Применяем уникальные пассивки ко всем оружиям
    apply_weapon_passives
  end
  
  def apply_weapon_passives
    # Собираем бонусы от уникальных пассивок
    weapon_amount_bonus = 0
    weapon_area_bonus = 0
    weapon_range_bonus = 0
    cooldown_reduction_bonus = 0
    duration_bonus = 0
    damage_multiplier = 1.0
    
    @passives.each do |passive|
      case passive.type
      when :weapon_amount
        # Округляем вниз для более сбалансированного бонуса
        weapon_amount_bonus += passive.get_bonus.floor
      when :weapon_area
        weapon_area_bonus += passive.get_bonus
      when :weapon_range
        weapon_range_bonus += passive.get_bonus
      when :cooldown_reduction
        cooldown_reduction_bonus += passive.get_bonus
      when :duration
        duration_bonus += passive.get_bonus
      when :damage
        # Урон увеличивает урон всех оружий
        damage_multiplier = 1.0 + passive.get_bonus
      end
    end
    
    # Применяем бонусы ко всем оружиям
    @weapons.each do |weapon|
      weapon.apply_passive_bonuses(
        amount: weapon_amount_bonus,
        area: weapon_area_bonus,
        range: weapon_range_bonus,
        cooldown_reduction: cooldown_reduction_bonus,
        duration: duration_bonus,
        damage_multiplier: damage_multiplier
      )
    end
  end

  def ensure_shapes
    unless @sprite
      sprite_type = @sprite_type || :player
      @sprite = SpriteRenderer.new(@x, @y, @size, sprite_type)
    end
  end

  def add_experience(amount)
    # Применяем бонус роста опыта
    growth_bonus = @growth || 0
    final_amount = amount * (1.0 + growth_bonus)
    
    @experience += final_amount.round
    # Проверяем повышение уровня
    while @experience >= @experience_to_next_level
      @experience -= @experience_to_next_level
      @level += 1
      # Более сложная формула для повышения уровня - экспоненциальный рост
      # Базовый опыт: 20, затем увеличивается на 15% за каждый уровень
      base_exp = 20
      @experience_to_next_level = (base_exp * (1.15 ** (@level - 1))).round
      
      # Небольшое увеличение базовых статов с каждым уровнем
      @speed = (@speed * 1.01).round  # +1% скорости
      @max_health = (@max_health * 1.02).round  # +2% здоровья
      @health = [@health, @max_health].min  # Восстанавливаем здоровье до максимума
      
      return true # Уровень повышен
    end
    false
  end

  def update(delta_time, enemies, map = nil, camera = nil)
    @time_alive += delta_time
    
    # Регенерация здоровья
    if @health_regen_rate > 0 && @health < @max_health
      current_time = Time.now.to_f
      if current_time - @last_regen_time >= 1.0
        @health = [@health + @health_regen_rate, @max_health].min
        @last_regen_time = current_time
      end
    end
    @last_x = @x
    @last_y = @y
    @is_moving = false
    # НЕ сбрасываем @is_attacking здесь - он устанавливается в auto_attack
    # Сохраняем старое значение для проверки
    old_attack_time = @last_attack_time
    @took_damage = false

    # Применяем пассивные улучшения
    apply_passives

    # Движение (теперь с учетом карты и коллизий с врагами)
    handle_movement(delta_time, map, enemies)
    
    # Проверяем, двигается ли персонаж
    @is_moving = (@x != @last_x || @y != @last_y)
    
    # Определяем направление взгляда
    if @is_moving
      if @x > @last_x
        @sprite&.set_facing_direction(:right)
      elsif @x < @last_x
        @sprite&.set_facing_direction(:left)
      end
    end
    
    # Автоатака ближайшего врага (вызывается из Game#update, здесь только проверяем состояние атаки)
    target_enemy = find_nearest_enemy(enemies)
    # auto_attack вызывается из Game#update после этого метода
    # Проверяем, произошла ли атака (время изменилось или уже установлен флаг)
    # @is_attacking устанавливается в auto_attack, но если время изменилось, тоже устанавливаем флаг
    if @last_attack_time != old_attack_time
      @is_attacking = true
    elsif @is_attacking && Time.now.to_f - @last_attack_time >= 0.2
      # Сбрасываем флаг атаки, если прошло достаточно времени
      @is_attacking = false
    end
    
    # Обновляем спрайт (с учетом камеры)
    if @sprite
      if camera
        screen_x, screen_y = camera.world_to_screen(@x, @y)
        @sprite.x = screen_x
        @sprite.y = screen_y
      else
        @sprite.x = @x
        @sprite.y = @y
      end
      # Обновляем дальность атаки для слеша
      whip = @weapons.find { |w| w.type == :whip }
      @sprite.attack_range = whip ? whip.range : 80
      # Передаем направление к врагу для слеша
      # Сохраняем attack_angle из auto_attack, если он был установлен
      attack_angle = @last_attack_angle
      if @is_attacking && !attack_angle && target_enemy
        dx = target_enemy.x - @x
        dy = target_enemy.y - @y
        attack_angle = Math.atan2(dy, dx)
        @last_attack_angle = attack_angle # Сохраняем для следующего кадра
      end
      @sprite.update(delta_time, @is_moving, @is_attacking, @took_damage, attack_angle)
      # Обновляем позиции всех фигур спрайта после установки @x и @y
      @sprite.update_all_positions
      # НЕ сбрасываем @last_attack_angle сразу - он нужен пока идет атака
      @last_attack_angle = nil if !@is_attacking # Сбрасываем только когда атака закончилась
    end
  end

  def handle_movement(delta_time, map = nil, enemies = [])
    move_x = 0
    move_y = 0

    move_x -= 1 if @keys_pressed.include?('a') || @keys_pressed.include?('left')
    move_x += 1 if @keys_pressed.include?('d') || @keys_pressed.include?('right')
    move_y -= 1 if @keys_pressed.include?('w') || @keys_pressed.include?('up')
    move_y += 1 if @keys_pressed.include?('s') || @keys_pressed.include?('down')

    return if move_x == 0 && move_y == 0

    # Нормализуем диагональное движение
    if move_x != 0 && move_y != 0
      move_x *= 0.707
      move_y *= 0.707
    end

    # Вычисляем новую позицию
    new_x = @x + move_x * @speed * delta_time
    new_y = @y + move_y * @speed * delta_time

    # Проверяем коллизии с картой
    if map
      # Проверяем коллизию по X
      test_x = new_x
      test_y = @y
      collisions_x = map.get_collisions(test_x, test_y, @size)
      if collisions_x.empty? || collisions_x.none? { |obj| obj.solid }
        # Проверяем коллизию с врагами по X
        enemy_collision_x = check_enemy_collision(test_x, test_y, enemies)
        if !enemy_collision_x
        @x = test_x
        else
          # Толкаем врага немного
          push_enemy(enemy_collision_x, move_x * @speed * delta_time * 0.3, 0)
        end
      end
      
      # Проверяем коллизию по Y
      test_x = @x
      test_y = new_y
      collisions_y = map.get_collisions(test_x, test_y, @size)
      if collisions_y.empty? || collisions_y.none? { |obj| obj.solid }
        # Проверяем коллизию с врагами по Y
        enemy_collision_y = check_enemy_collision(test_x, test_y, enemies)
        if !enemy_collision_y
        @y = test_y
        else
          # Толкаем врага немного
          push_enemy(enemy_collision_y, 0, move_y * @speed * delta_time * 0.3)
        end
      end
    else
      # Старое поведение (ограничение границами экрана) для обратной совместимости
      # Но все равно проверяем коллизии с врагами
      enemy_collision = check_enemy_collision(new_x, new_y, enemies)
      if !enemy_collision
      @x = new_x
      @y = new_y
      else
        # Толкаем врага немного
        push_enemy(enemy_collision, move_x * @speed * delta_time * 0.3, move_y * @speed * delta_time * 0.3)
      end
    end
  end
  
  def check_enemy_collision(x, y, enemies)
    return nil unless enemies
    enemies.each do |enemy|
      next unless enemy.alive?
      distance = Math.sqrt((x - enemy.x)**2 + (y - enemy.y)**2)
      collision_distance = (@size + enemy.size) * 0.8  # Небольшой зазор
      if distance < collision_distance
        return enemy
      end
    end
    nil
  end
  
  def push_enemy(enemy, push_x, push_y)
    # Игрок может немного толкать врагов
    enemy.x += push_x * 0.5  # Враг толкается слабее
    enemy.y += push_y * 0.5
  end

  def key_down(key)
    @keys_pressed.add(key)
  end

  def key_up(key)
    @keys_pressed.delete(key)
  end

  def auto_attack(enemies, delta_time)
    current_time = Time.now.to_f
    projectiles = []
    attacked = false
    
    # Атакуем всеми оружиями
    @weapons.each do |weapon|
      # Для кнута - создаем projectile для визуализации и нанесения урона
      if weapon.type == :whip
        nearest_enemy = find_nearest_enemy(enemies)
        if nearest_enemy && weapon.can_attack?(current_time)
          distance = distance_to(nearest_enemy.x, nearest_enemy.y)
          if distance <= weapon.range
            # Устанавливаем флаг атаки
            @is_attacking = true
            @last_attack_time = current_time
            
            # Сохраняем угол атаки для анимации
            attack_angle = Math.atan2(nearest_enemy.y - @y, nearest_enemy.x - @x)
            @last_attack_angle = attack_angle
            
            # Создаем projectile для визуализации и нанесения урона
            weapon_projectiles = weapon.attack(@x, @y, enemies, current_time)
            if weapon_projectiles && !weapon_projectiles.empty?
              attacked = true
              projectiles.concat(weapon_projectiles)
            end
          end
        end
      else
        # Для дальнобойного оружия
        weapon_projectiles = weapon.attack(@x, @y, enemies, current_time)
        if weapon_projectiles && !weapon_projectiles.empty?
          attacked = true
          projectiles.concat(weapon_projectiles)
          @last_attack_time = current_time
        end
      end
    end
    
        projectiles
  end
  
  def apply_vampirism(damage_dealt)
    return if @vampirism <= 0 || damage_dealt <= 0
    
    # Шанс вампиризма = @vampirism (например, 0.1 = 10% шанс)
    if rand < @vampirism
      # Восстанавливаем небольшой процент от нанесенного урона (5-10%)
      heal_amount = damage_dealt * (0.05 + rand * 0.05)
      @health = [@health + heal_amount, @max_health].min
    end
  end

  def find_nearest_enemy(enemies)
    return nil if enemies.empty?

    enemies.min_by { |enemy| distance_to(enemy.x, enemy.y) }
  end

  def distance_to(x, y)
    Math.sqrt((@x - x)**2 + (@y - y)**2)
  end

  def take_damage(amount, audio_manager = nil)
    # Применяем броню
    actual_damage = amount * (1.0 - @armor)
    @health -= actual_damage
    @health = 0 if @health < 0
    @took_damage = true
    # Звук получения урона игроком
    audio_manager&.play_sound(:player_hit) if actual_damage > 0
  end

  def alive?
    @health > 0
  end

  def draw(camera = nil)
    return unless alive?

    # Спрайт рисуется автоматически через Ruby2D (позиция уже обновлена в update)
    # Рисуем полоску здоровья (с учетом камеры)
    draw_health_bar(camera)
  end

  def draw_health_bar(camera = nil)
    health_percent = @health.to_f / @max_health
    bar_width = @size
    bar_height = 4
    
    # Преобразуем мировые координаты в экранные
    if camera
      bar_x, bar_y = camera.world_to_screen(@x, @y - @size / 2 - 12)
    else
      bar_x = @x - bar_width / 2
      bar_y = @y - @size / 2 - 12
    end
    bar_x -= bar_width / 2

    # Фон полоски здоровья
    unless @health_bar_bg
      @health_bar_bg = Rectangle.new(
        x: bar_x,
        y: bar_y,
        width: bar_width,
        height: bar_height,
        color: 'red'
      )
    end

    # Здоровье
    unless @health_bar
      @health_bar = Rectangle.new(
        x: bar_x,
        y: bar_y,
        width: bar_width,
        height: bar_height,
        color: 'green'
      )
    end

    # Обновляем позиции и размеры
    @health_bar_bg.x = bar_x
    @health_bar_bg.y = bar_y
    @health_bar_bg.width = bar_width

    @health_bar.x = bar_x
    @health_bar.y = bar_y
    @health_bar.width = bar_width * health_percent
  end

  def remove_shapes
    @sprite&.remove
    @health_bar_bg&.remove
    @health_bar&.remove
  end
end

