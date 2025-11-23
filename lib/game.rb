require_relative 'player'
require_relative 'enemy'
require_relative 'upgrade_system'
require_relative 'upgrade_screen'
require_relative 'weapon'
require_relative 'passive'
require_relative 'projectile'
require_relative 'vs_upgrade_system'
require_relative 'camera'
require_relative 'map'

class Game
  attr_accessor :player, :enemies, :window_width, :window_height, :spawn_timer, :last_spawn_time, :settings,
                :upgrade_system, :upgrade_screen, :showing_upgrades, :difficulty_multiplier, :game_start_time,
                :camera, :map, :delta_time

  def initialize(settings, hero_data = nil)
    @settings = settings
    @window_width = settings.resolution_width
    @window_height = settings.resolution_height
    @upgrade_system = UpgradeSystem.new
    @upgrade_screen = UpgradeScreen.new(@window_width, @window_height, @upgrade_system)
    @vs_upgrade_system = nil # Инициализируем после создания игрока
    @showing_upgrades = false
    @difficulty_multiplier = 1.0
    @hero_data = hero_data
    reset_game
  end

  def reset_game
    # Очищаем старые объекты
    @player&.remove_shapes if @player
    @enemies.each(&:remove) if @enemies
    @map&.remove if @map

    # Создаем камеру (нужна для инициализации объектов карты)
    @camera = Camera.new(@window_width, @window_height)
    
    # Создаем карту
    @map = Map.new
    
    # Игрок начинается в центре карты (0, 0)
    @player = Player.new(0, 0, @hero_data)
    @player.speed = @settings.player_speed
    @player.ensure_shapes
    
    # Камера следует за игроком
    @camera.x = @player.x
    @camera.y = @player.y
    
    # Сразу обновляем позиции всех объектов карты с учетом камеры
    @map.objects.each do |obj|
      obj.update_positions(@camera, 0.0)
    end
    
    @enemies = []
    @spawn_timer = @settings.spawn_rate
    @last_spawn_time = Time.now.to_f
    @last_time = Time.now.to_f
    @ui_texts = {}
    @ui_shapes = {}
    @upgrade_system = UpgradeSystem.new
    @vs_upgrade_system = VSUpgradeSystem.new(@player)
    @difficulty_multiplier = 1.0
    @game_start_time = Time.now.to_f
    @showing_upgrades = false
    @projectiles = []
    @experience_gems = [] # Опыт, который падает с врагов
    @chests_opened = 0 # Счетчик открытых сундуков для прогрессивной стоимости
  end

  def remove_shapes
    @player&.remove_shapes if @player
    @enemies.each(&:remove) if @enemies
    @projectiles.each(&:remove) if @projectiles
    @experience_gems.each do |gem|
      gem[:shapes].each(&:remove) if gem[:shapes]
    end
    @ui_texts.values.each(&:remove) if @ui_texts
    @ui_shapes.values.each(&:remove) if @ui_shapes
    @upgrade_screen.hide if @upgrade_screen
    # Удаляем фоновые тайлы
    if @map_background_tiles
      @map_background_tiles.values.each(&:remove)
      @map_background_tiles.clear
    end
  end

  def update
    current_time = Time.now.to_f
    
    if @showing_upgrades
      # Обновляем время даже когда экран улучшений показывается, чтобы избежать большого delta_time
      @last_time = current_time
      return
    end

    delta_time = current_time - @last_time
    @last_time = current_time
    @delta_time = delta_time # Сохраняем для использования в draw

    return unless @player.alive?

    # Увеличиваем сложность со временем
    game_time = current_time - @game_start_time
    @difficulty_multiplier = 1.0 + (game_time / 60.0) * 0.1 # +10% каждую минуту

    # Обновляем камеру (следует за игроком)
    @camera.follow(@player.x, @player.y)
    
    # Обновляем игрока (теперь с учетом карты и коллизий)
    @player.update(delta_time, @enemies.select(&:alive?), @map, @camera)

    # Атака оружием
    new_projectiles = @player.auto_attack(@enemies.select(&:alive?), delta_time)
    if new_projectiles && !new_projectiles.empty?
      new_projectiles.each do |p|
        # Не создаем проектиль для кнута, он наносит урон напрямую
        next if p[:type] == :whip
        @projectiles << Projectile.new(p[:type], p[:x], p[:y], p[:angle] || 0, p[:damage], p[:speed] || 0, p[:range] || 100, p)
      end
    end

    # Обновляем проектили (с учетом карты и коллизий)
    @projectiles.each { |p| p.update(delta_time, @enemies.select(&:alive?), @map) }
    
    # Проверяем столкновения проектилей с врагами
    @projectiles.each do |projectile|
      next unless projectile.active
      @enemies.each do |enemy|
        next unless enemy.alive?
        if projectile.check_collision(enemy)
          enemy.take_damage(projectile.damage)
        end
      end
    end

    # Удаляем неактивные проектили
    @projectiles.reject! { |p| !p.active }

    # Проверяем убийства врагов и создаем опыт и золото
    @enemies.each do |enemy|
      if enemy.just_died?
        @player.enemies_killed += 1
        
        # Создаем опыт-гем с начальными параметрами
        @experience_gems << { 
          x: enemy.x, 
          y: enemy.y, 
          value: enemy.experience_value, 
          collected: false,
          being_collected: false,
          collect_speed: 200.0, # Скорость притягивания
          shapes: [] # Фигуры для отрисовки
        }
        
        # Даем золото за убийство монстра (30% шанс, 1-3 золота)
        if rand < 0.3
          gold_amount = 1 + rand(3) # 1-3 золота
          @player.gold += gold_amount
        end
      end
    end

    # Обновляем и собираем опыт (с анимацией притягивания)
    @experience_gems.each do |gem|
      next if gem[:collected]
      
      distance = Math.sqrt((@player.x - gem[:x])**2 + (@player.y - gem[:y])**2)
      
      # Если в зоне магнита, начинаем притягивание
      if distance <= @player.experience_magnet_range
        gem[:being_collected] = true
      end
      
      # Если притягивается, двигаем к игроку
      if gem[:being_collected]
        dx = @player.x - gem[:x]
        dy = @player.y - gem[:y]
        move_distance = gem[:collect_speed] * delta_time
        
        if distance <= move_distance
          # Достигли игрока - собираем
          gem[:collected] = true
          if @player.add_experience(gem[:value])
            # Игрок повысил уровень - показываем экран улучшений
            show_upgrade_screen
            return
          end
        else
          # Двигаем к игроку
          move_x = (dx / distance) * move_distance
          move_y = (dy / distance) * move_distance
          gem[:x] += move_x
          gem[:y] += move_y
        end
      end
    end

    # Удаляем собранный опыт и его фигуры
    @experience_gems.each do |gem|
      if gem[:collected]
        # Удаляем все фигуры опыта
        gem[:shapes].each(&:remove) if gem[:shapes]
        gem[:shapes] = []
      end
    end
    @experience_gems.reject! { |g| g[:collected] }

    # Обновляем врагов (с учетом карты и коллизий)
    @enemies.each { |enemy| enemy.update(delta_time, @player, @map) if enemy.alive? }

    # Удаляем мертвых врагов
    dead_enemies = @enemies.select { |enemy| !enemy.alive? }
    dead_enemies.each(&:remove)
    @enemies.reject! { |enemy| !enemy.alive? }

    # Спавним новых врагов (с учетом сложности)
    spawn_enemies(current_time)

    # Ограничиваем количество врагов на экране (увеличивается со временем)
    base_max_enemies = @settings.max_enemies
    max_enemies = (base_max_enemies * @difficulty_multiplier).round
    @enemies = @enemies.last(max_enemies) if @enemies.size > max_enemies

    # Обрабатываем взаимодействие с интерактивными объектами
    handle_interactive_objects(delta_time)
  end

  def handle_interactive_objects(delta_time)
    interaction_range = 40
    
    # Создаем копию массива объектов, чтобы можно было безопасно удалять элементы во время итерации
    objects_to_check = @map.objects.dup
    
    # Проверяем близость к интерактивным объектам
    objects_to_check.each do |obj|
      next unless obj.interactive
      next if obj.opened || obj.destroyed
      next unless @map.objects.include?(obj) # Пропускаем, если объект уже удален
      
      # Для сундуков - прогрессивное открытие с индикацией
      if obj.type == :chest
        can_interact = obj.can_interact?(@player.x, @player.y, interaction_range)
        obj.set_highlight(can_interact, @camera)
        
        chest_cost = get_chest_cost
        
        if can_interact && !obj.opened
          # Показываем стоимость и обновляем прогресс
          obj.update_interaction_progress(delta_time, @camera, chest_cost, @player.gold)
          if obj.interaction_progress >= 1.0
            open_chest(obj)
            next # Объект удален, переходим к следующему
          end
        else
          # Сбрасываем прогресс, если игрок отошел
          obj.reset_interaction_progress
        end
      elsif obj.type == :barrel
        # Для ящиков - прогрессивное разрушение с индикацией
        # Если ящик начал разрушаться, обновляем прогресс
        if obj.destroying?
          obj.update_interaction_progress(delta_time, @camera)
          if obj.interaction_progress >= 1.0
            destroy_barrel(obj)
            next # Объект удален, переходим к следующему
          end
        else
          # Сбрасываем прогресс, если ящик не разрушается
          obj.reset_interaction_progress
        end
      end
    end
    
    # Проверяем разрушение бочек при атаке
    check_barrel_destruction
  end

  def get_chest_cost
    # Прогрессивная стоимость: базовая стоимость * (1.5 ^ количество открытых сундуков)
    base_cost = 50 # Базовая стоимость первого сундука
    multiplier = 1.5 # Множитель прогрессии
    (base_cost * (multiplier ** @chests_opened)).round
  end

  def open_chest(chest)
    return if chest.opened || chest.destroyed
    
    # Дополнительная проверка перед открытием
    return if chest.opened
    
    # Проверяем, достаточно ли золота для открытия
    cost = get_chest_cost
    if @player.gold < cost
      # Недостаточно золота - не открываем
      return
    end
    
    # Вычитаем золото
    @player.gold -= cost
    
    # Увеличиваем счетчик открытых сундуков
    @chests_opened += 1
    
    chest.open!
    
    # Генерируем награды из сундука
    rewards = generate_chest_rewards
    
    # Применяем награды
    level_up = false
    rewards.each do |reward|
      case reward[:type]
      when :new_weapon
        # Даем новое оружие
        @player.add_weapon(reward[:weapon_type])
      when :new_passive
        # Даем новое пассивное улучшение
        @player.add_passive(reward[:passive_type])
      when :experience
        # Даем опыт
        if @player.add_experience(reward[:amount])
          # Игрок повысил уровень
          level_up = true
        end
      when :gold
        # Добавляем золото
        @player.gold += reward[:amount]
      end
    end
    
    # Создаем визуальный эффект (опыт-гемы из сундука)
    rewards.select { |r| r[:type] == :experience }.each do |reward|
      @experience_gems << {
        x: chest.x + rand(-10..10),
        y: chest.y + rand(-10..10),
        value: reward[:amount],
        collected: false,
        being_collected: false,
        collect_speed: 200.0,
        shapes: []
      }
    end
    
    # Удаляем сундук из карты после открытия (ВАЖНО: делаем это перед show_upgrade_screen)
    chest.remove # Удаляем все фигуры
    @map.objects.delete(chest) # Удаляем из массива объектов карты
    
    # Показываем экран улучшений после удаления сундука
    if level_up
      show_upgrade_screen
    end
  end

  def generate_chest_rewards
    # Используем систему улучшений для генерации наград из сундука
    @vs_upgrade_system.get_chest_rewards
  end

  def check_barrel_destruction
    # Проверяем, попали ли проектили или атаки в бочки
    # Создаем копию массива объектов, чтобы можно было безопасно удалять элементы во время итерации
    objects_to_check = @map.objects.dup
    
    objects_to_check.each do |obj|
      next unless obj.type == :barrel
      next if obj.destroyed
      next unless @map.objects.include?(obj) # Пропускаем, если объект уже удален
      
      # Проверяем столкновение с проектилями
      @projectiles.each do |projectile|
        next unless projectile.active
        
        distance = Math.sqrt((obj.x - projectile.x)**2 + (obj.y - projectile.y)**2)
        if distance < (obj.size + 10) / 2
          # Начинаем прогрессивное разрушение ящика
          obj.start_destruction
          projectile.active = false # Проектиль останавливается
          break
        end
      end
      
      # Проверяем столкновение с атаками игрока (ближний бой)
      if @player.is_attacking
        distance = Math.sqrt((obj.x - @player.x)**2 + (obj.y - @player.y)**2)
        if distance < (@player.attack_range + obj.size) / 2
          # Начинаем прогрессивное разрушение ящика
          obj.start_destruction
          break
        end
      end
    end
  end

  def destroy_barrel(barrel)
    return if barrel.destroyed
    
    barrel.destroy!
    
    # Бочки дают опыт (меньше, чем сундуки)
    exp_amount = 10 + rand(30)
    
    # Бочки дают небольшое количество золота
    gold_amount = 5 + rand(15)
    @player.gold += gold_amount
    
    # Создаем опыт-гемы
    3.times do |i|
      angle = i * Math::PI * 2 / 3
      @experience_gems << {
        x: barrel.x + Math.cos(angle) * 10,
        y: barrel.y + Math.sin(angle) * 10,
        value: exp_amount / 3,
        collected: false,
        being_collected: false,
        collect_speed: 200.0,
        shapes: []
      }
    end
    
    # Удаляем ящик из карты после разрушения
    barrel.remove # Удаляем все фигуры
    @map.objects.delete(barrel) # Удаляем из массива объектов карты
  end

  def show_upgrade_screen
    @showing_upgrades = true
    # Очищаем зажатые клавиши, чтобы избежать проблем с управлением после закрытия экрана
    @player.keys_pressed.clear
    # Обновляем время, чтобы избежать большого delta_time при возобновлении
    @last_time = Time.now.to_f
    # Используем улучшения только для уровня (только улучшения существующего оружия/пассивов)
    available = @vs_upgrade_system.get_level_upgrades(3)
    @upgrade_screen.show_vs_upgrades(available, @vs_upgrade_system)
  end

  def spawn_enemies(current_time)
    # Скорость спавна уменьшается со временем (враги появляются чаще)
    current_spawn_rate = @spawn_timer / @difficulty_multiplier
    return if current_time - @last_spawn_time < current_spawn_rate

    # Получаем границы видимой области в мировых координатах
    min_x, min_y = @camera.screen_to_world(0, 0)
    max_x, max_y = @camera.screen_to_world(@window_width, @window_height)
    
    # Получаем границы карты
    map_min_x = -@map.width / 2
    map_max_x = @map.width / 2
    map_min_y = -@map.height / 2
    map_max_y = @map.height / 2
    
    # Добавляем отступ от края экрана для спавна
    spawn_offset = 50
    
    # Спавним врага на краю видимой области, но внутри границ карты
    side = rand(4)
    case side
    when 0 # верх
      x = min_x + rand(max_x - min_x)
      y = min_y - spawn_offset
      # Ограничиваем границами карты
      x = [[x, map_min_x + 20].max, map_max_x - 20].min
      y = [y, map_min_y + 20].max
    when 1 # право
      x = max_x + spawn_offset
      y = min_y + rand(max_y - min_y)
      # Ограничиваем границами карты
      x = [x, map_max_x - 20].min
      y = [[y, map_min_y + 20].max, map_max_y - 20].min
    when 2 # низ
      x = min_x + rand(max_x - min_x)
      y = max_y + spawn_offset
      # Ограничиваем границами карты
      x = [[x, map_min_x + 20].max, map_max_x - 20].min
      y = [y, map_max_y - 20].min
    when 3 # лево
      x = min_x - spawn_offset
      y = min_y + rand(max_y - min_y)
      # Ограничиваем границами карты
      x = [x, map_min_x + 20].max
      y = [[y, map_min_y + 20].max, map_max_y - 20].min
    end

    # Проверяем, что позиция внутри границ карты
    if x < map_min_x || x > map_max_x || y < map_min_y || y > map_max_y
      return # Не спавним, если позиция за границами
    end

    enemy = Enemy.new(x, y)
    # Скорость врагов увеличивается со временем
    enemy.speed = (@settings.enemy_speed * @difficulty_multiplier).round
    enemy.ensure_shapes
    @enemies << enemy
    @last_spawn_time = current_time
  end

  def draw
    if @showing_upgrades && !@upgrade_screen.available_upgrades.empty?
      # Рисуем затемненный фон
      unless @ui_shapes[:upgrade_bg]
        @ui_shapes[:upgrade_bg] = Rectangle.new(
          x: 0,
          y: 0,
          width: @window_width,
          height: @window_height,
          color: [0, 0, 0, 0.7] # Полупрозрачный черный
        )
      end
      @upgrade_screen.draw
      @upgrade_screen.update
    else
      # Рисуем фон карты (траву/землю)
      draw_map_background
      
      # Рисуем карту (только видимые объекты)
      visible_objects = @map.get_visible_objects(@camera)
      visible_objects.each do |obj|
        obj.update_positions(@camera, @delta_time || 0.0)
      end
      
      # Рисуем опыт-гемы (обновляем существующие фигуры)
      @experience_gems.each_with_index do |gem, index|
        next if gem[:collected]
        update_experience_gem(gem, index)
      end

      # Обновляем позиции проектилей с учетом камеры
      @projectiles.each do |projectile|
        next unless projectile.active
        projectile.update_positions(@camera)
      end
      
      # Рисуем игрока (с учетом камеры)
      @player.draw(@camera) if @player.alive?

      # Рисуем врагов (с учетом камеры)
      @enemies.each { |enemy| enemy.draw(@camera) if enemy.alive? }

      # Рисуем информацию
      draw_ui
    end
  end

  def draw_upgrade_background
    unless @ui_shapes[:upgrade_bg]
      @ui_shapes[:upgrade_bg] = Rectangle.new(
        x: 0,
        y: 0,
        width: @window_width,
        height: @window_height,
        color: [0, 0, 0, 0.7] # Полупрозрачный черный
      )
    end
  end

  def draw_map_background
    # Рисуем фон карты (траву/землю)
    # Вычисляем видимую область в мировых координатах
    min_x, min_y = @camera.screen_to_world(0, 0)
    max_x, max_y = @camera.screen_to_world(@window_width, @window_height)
    
    # Добавляем небольшой запас для плавного обновления
    padding = 100
    min_x -= padding
    min_y -= padding
    max_x += padding
    max_y += padding
    
    # Создаем или обновляем фоновые тайлы
    tile_size = 100
    start_tile_x = (min_x / tile_size).floor * tile_size
    start_tile_y = (min_y / tile_size).floor * tile_size
    
    # Удаляем старые тайлы, которые больше не видны
    if @map_background_tiles
      @map_background_tiles.each do |key, tile|
        tile_x, tile_y = key.split(',').map(&:to_f)
        if tile_x < min_x - tile_size || tile_x > max_x + tile_size ||
           tile_y < min_y - tile_size || tile_y > max_y + tile_size
          tile.remove
          @map_background_tiles.delete(key)
        end
      end
    else
      @map_background_tiles = {}
    end
    
    # Создаем новые тайлы для видимой области
    (start_tile_x..max_x).step(tile_size) do |x|
      (start_tile_y..max_y).step(tile_size) do |y|
        key = "#{x},#{y}"
        next if @map_background_tiles[key]
        
        # Преобразуем в экранные координаты
        screen_x, screen_y = @camera.world_to_screen(x, y)
        
        # Создаем тайл (трава с небольшими вариациями цвета)
        base_color = [34, 139, 34] # Зеленый цвет травы
        variation = rand(-10..10)
        r = [[base_color[0] + variation, 0].max, 255].min
        g = [[base_color[1] + variation, 0].max, 255].min
        b = [[base_color[2] + variation, 0].max, 255].min
        
        # Ruby2D принимает цвет в формате строки '#RRGGBB' или массива [r, g, b, a] с float от 0.0 до 1.0
        color_string = format('#%02X%02X%02X', r, g, b)
        
        @map_background_tiles[key] = Rectangle.new(
          x: screen_x,
          y: screen_y,
          width: tile_size,
          height: tile_size,
          color: color_string,
          z: -1000 # Очень низкий z-порядок, чтобы фон был в самом низу
        )
      end
    end
    
    # Обновляем позиции существующих тайлов
    @map_background_tiles.each do |key, tile|
      tile_x, tile_y = key.split(',').map(&:to_f)
      screen_x, screen_y = @camera.world_to_screen(tile_x, tile_y)
      tile.x = screen_x
      tile.y = screen_y
      # Убеждаемся, что z-порядок установлен правильно
      tile.z = -1000 if tile.respond_to?(:z=)
    end
  end

  def draw_ui
    y_offset = 10
    
    # Уровень и опыт
    exp_text = "Уровень: #{@player.level} | Опыт: #{@player.experience}/#{@player.experience_to_next_level}"
    if @ui_texts[:level]
      @ui_texts[:level].text = exp_text
    else
      @ui_texts[:level] = Text.new(
        exp_text,
        x: 10,
        y: y_offset,
        size: 18,
        color: 'yellow'
      )
    end
    y_offset += 25

    # Информация о здоровье игрока
    hp_text = "HP: #{@player.health.to_i}/#{@player.max_health}"
    if @ui_texts[:hp]
      @ui_texts[:hp].text = hp_text
    else
      @ui_texts[:hp] = Text.new(
        hp_text,
        x: 10,
        y: y_offset,
        size: 20,
        color: 'white'
      )
    end
    y_offset += 25

    # Полоска опыта
    draw_experience_bar(y_offset)
    y_offset += 20

    # Статистика
    stats_text = "Убито: #{@player.enemies_killed} | Время: #{(Time.now.to_f - @game_start_time).to_i}с"
    if @ui_texts[:stats]
      @ui_texts[:stats].text = stats_text
    else
      @ui_texts[:stats] = Text.new(
        stats_text,
        x: 10,
        y: y_offset,
        size: 16,
        color: '#CCCCCC'
      )
    end
    y_offset += 25

    # Количество врагов
    if @ui_texts[:enemies]
      @ui_texts[:enemies].text = "Врагов: #{@enemies.count(&:alive?)}"
    else
      @ui_texts[:enemies] = Text.new(
        "Врагов: #{@enemies.count(&:alive?)}",
        x: 10,
        y: y_offset,
        size: 18,
        color: 'white'
      )
    end
    y_offset += 25

    # Отображаем золото
    gold_text = "Золото: #{@player.gold}"
    if @ui_texts[:gold]
      @ui_texts[:gold].text = gold_text
    else
      @ui_texts[:gold] = Text.new(
        gold_text,
        x: 10,
        y: y_offset,
        size: 18,
        color: '#FFD700', # Золотой цвет
        z: 1000
      )
    end

    # Сообщение о смерти
    if !@player.alive?
      draw_game_over_screen
    end
  end

  def draw_experience_bar(y_pos)
    bar_width = 200
    bar_height = 8
    bar_x = 10
    bar_y = y_pos

    exp_percent = @player.experience.to_f / @player.experience_to_next_level

    # Фон полоски опыта
    unless @ui_shapes && @ui_shapes[:exp_bg]
      @ui_shapes ||= {}
      @ui_shapes[:exp_bg] = Rectangle.new(
        x: bar_x,
        y: bar_y,
        width: bar_width,
        height: bar_height,
        color: '#333333'
      )
    end

    # Полоска опыта
    unless @ui_shapes[:exp_bar]
      @ui_shapes[:exp_bar] = Rectangle.new(
        x: bar_x,
        y: bar_y,
        width: bar_width * exp_percent,
        height: bar_height,
        color: '#00FF00'
      )
    else
      @ui_shapes[:exp_bar].width = bar_width * exp_percent
    end
  end

  def update_experience_gem(gem, index)
    # Преобразуем мировые координаты в экранные
    screen_x, screen_y = @camera.world_to_screen(gem[:x], gem[:y])
    
    # Создаем фигуры при первом появлении
    if gem[:shapes].empty?
      # Внешний круг (свечение)
      gem[:shapes] << Circle.new(
        x: screen_x, y: screen_y,
        radius: 7,
        color: [0, 255, 0, 0.3]
      )
      # Основной круг
      gem[:shapes] << Circle.new(
        x: screen_x, y: screen_y,
        radius: 5,
        color: '#00FF00'
      )
      # Внутренний круг (яркий)
      gem[:shapes] << Circle.new(
        x: screen_x, y: screen_y,
        radius: 3,
        color: '#88FF88'
      )
    else
      # Обновляем позиции существующих фигур
      gem[:shapes].each do |shape|
        shape.x = screen_x
        shape.y = screen_y
      end
    end
  end

  def draw_experience_gem(x, y, index)
    # Устаревший метод - используем update_experience_gem
    # Оставляем для совместимости, но не используем
  end

  def draw_game_over_screen
    unless @ui_texts[:game_over]
      game_time = (Time.now.to_f - @game_start_time).to_i
      minutes = game_time / 60
      seconds = game_time % 60
      
      @ui_texts[:game_over] = Text.new(
        "GAME OVER",
        x: @window_width / 2,
        y: @window_height / 2 - 80,
        size: 50,
        color: 'red',
        font: nil
      )
      @ui_texts[:game_over].x = @window_width / 2 - @ui_texts[:game_over].width / 2

      stats = "Уровень: #{@player.level} | Убито: #{@player.enemies_killed} | Время: #{minutes}м #{seconds}с"
      @ui_texts[:game_over_stats] = Text.new(
        stats,
        x: @window_width / 2,
        y: @window_height / 2 - 20,
        size: 24,
        color: 'white',
        font: nil
      )
      @ui_texts[:game_over_stats].x = @window_width / 2 - @ui_texts[:game_over_stats].width / 2

      @ui_texts[:game_over_hint] = Text.new(
        "Нажмите ESC для возврата в меню",
        x: @window_width / 2,
        y: @window_height / 2 + 40,
        size: 20,
        color: 'gray',
        font: nil
      )
      @ui_texts[:game_over_hint].x = @window_width / 2 - @ui_texts[:game_over_hint].width / 2
    end
  end

  def handle_key_down(key)
    if @showing_upgrades
      result = @upgrade_screen.handle_key_down(key)
      if result == :upgrade_selected
        # Применяем улучшения к игроку
        apply_selected_upgrade
      end
    elsif @player.alive?
      @player.key_down(key)
    end
  end

  def handle_key_up(key)
    @player.key_up(key) unless @showing_upgrades
  end

  def handle_mouse_down(x, y, button)
    return unless button == :left
    
    if @showing_upgrades
      result = @upgrade_screen.handle_mouse_click(x, y)
      if result == :upgrade_selected
        # Применяем улучшения к игроку
        apply_selected_upgrade
      end
    end
  end

  def apply_selected_upgrade
    # Улучшение уже применено в select_upgrade, просто скрываем экран
    @upgrade_screen.hide
    @showing_upgrades = false
    @ui_shapes[:upgrade_bg]&.remove
    @ui_shapes[:upgrade_bg] = nil
    # Очищаем зажатые клавиши и обновляем время, чтобы избежать проблем с управлением
    @player.keys_pressed.clear
    @last_time = Time.now.to_f
    # Убеждаемся, что камера правильно позиционирована на игроке
    @camera.x = @player.x
    @camera.y = @player.y
  end
end

