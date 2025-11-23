require_relative 'player'
require_relative 'enemy'
require_relative 'enemy_types'
require_relative 'upgrade_system'
require_relative 'upgrade_screen'
require_relative 'weapon'
require_relative 'passive'
require_relative 'projectile'
require_relative 'vs_upgrade_system'
require_relative 'camera'
require_relative 'map'
require_relative 'pickup'

class Game
  attr_accessor :player, :enemies, :window_width, :window_height, :spawn_timer, :last_spawn_time, :settings,
                :upgrade_system, :upgrade_screen, :showing_upgrades, :difficulty_multiplier, :game_start_time,
                :camera, :map, :delta_time, :game_completed

  def initialize(settings, hero_data = nil, audio_manager = nil)
    @settings = settings
    @window_width = settings.resolution_width
    @window_height = settings.resolution_height
    @upgrade_system = UpgradeSystem.new
    @upgrade_screen = UpgradeScreen.new(@window_width, @window_height, @upgrade_system, audio_manager)
    @vs_upgrade_system = nil # Инициализируем после создания игрока
    @showing_upgrades = false
    @difficulty_multiplier = 1.0
    @hero_data = hero_data
    @audio_manager = audio_manager
    reset_game
    # Запускаем фоновую музыку при старте игры
    @audio_manager&.play_music
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
    
    # Обновляем позиции только видимых объектов карты (оптимизация)
    # Не обновляем все объекты сразу - это будет делаться в draw только для видимых
    
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
    @pickups = [] # Дропы усилений
    @explosions = [] # Визуальные эффекты взрывов
    @damage_effects = [] # Визуальные эффекты урона (кровь, частицы)
    @screen_flash = 0.0 # Эффект мигания экрана при получении урона
    @chests_opened = 0 # Счетчик открытых сундуков для прогрессивной стоимости
    @active_altar = nil
    @elite_enemies_to_kill = 0
    @elite_enemies_killed = 0
    @final_boss_spawned = false
    @final_boss = nil
    @game_completed = false
    @boss_spawned_this_minute = false
    @last_boss_minute = -1
    @boss_warning_time = 0
    @record_saved = false # Флаг, чтобы не сохранять рекорд несколько раз
    @last_wave_minute = -1 # Последняя минута, когда была волна
    @wave_spawned_this_minute = false # Флаг волны в текущей минуте
    @minimap_shapes = {} # Фигуры для миникарты
    @elite_attack_indicators = [] # Индикаторы атак элитных монстров
    @enemies_cache_dirty = true # Флаг для обновления кэша врагов
    @update_counter = 0 # Счетчик кадров для редких обновлений
  end

  def remove_shapes
    @player&.remove_shapes if @player
    
    # Удаляем всех врагов (полная очистка)
    if @enemies
      @enemies.each do |enemy|
        # Принудительно помечаем как мертвого
        enemy.instance_variable_set(:@health, 0) if enemy.health > 0
        enemy.instance_variable_set(:@just_died, true)
        
        # Удаляем спрайт и все его фигуры
        if enemy.sprite
          # Дополнительно очищаем shapes перед удалением
          if enemy.sprite.respond_to?(:shapes) && enemy.sprite.shapes
            enemy.sprite.shapes.values.each do |shape|
              if shape.is_a?(Array)
                shape.each do |s|
                  s.x = -100000 if s.respond_to?(:x=)
                  s.y = -100000 if s.respond_to?(:y=)
                  s.remove if s.respond_to?(:remove)
                end
              else
                shape.x = -100000 if shape.respond_to?(:x=)
                shape.y = -100000 if shape.respond_to?(:y=)
                shape.remove if shape.respond_to?(:remove)
              end
            end
          end
          enemy.sprite.remove if enemy.sprite.respond_to?(:remove)
          enemy.sprite = nil
        end
        enemy.remove if enemy.respond_to?(:remove)
      end
      @enemies.clear
    end
    
    # Удаляем все проектили
    if @projectiles
      @projectiles.each(&:remove)
      @projectiles.clear
    end
    
    # Удаляем опыт-гемы
    @experience_gems.each do |gem|
      gem[:shapes].each(&:remove) if gem[:shapes]
    end
    @experience_gems.clear
    
    # Удаляем дропы
    @pickups.each(&:remove) if @pickups
    @pickups.clear
    
    # Удаляем взрывы
    @explosions.each do |explosion|
      explosion[:shapes].each(&:remove) if explosion[:shapes]
      if explosion[:particles]
        explosion[:particles].each { |p| p[:shape].remove }
      end
    end
    @explosions.clear
    
    # Удаляем эффекты урона
    @damage_effects.each do |effect|
      effect[:shapes].each(&:remove) if effect[:shapes]
    end
    @damage_effects.clear
    
    # Удаляем индикаторы атак элитных монстров
    @elite_attack_indicators.each do |indicator|
      indicator[:shape].remove if indicator[:shape]
    end
    @elite_attack_indicators.clear
    
    # Удаляем мигание экрана
    @ui_shapes[:screen_flash]&.remove
    @ui_shapes[:screen_flash] = nil
    
    # Удаляем UI элементы
    @ui_texts.values.each { |text| text&.remove } if @ui_texts
    @ui_texts.clear
    @ui_shapes.values.each { |shape| shape&.remove } if @ui_shapes
    @ui_shapes.clear
    
    # Удаляем миникарту
    if @minimap_shapes
      @minimap_shapes.each do |key, shape|
        if shape.is_a?(Array)
          shape.each { |s| s.remove if s.respond_to?(:remove) }
        else
          shape.remove if shape.respond_to?(:remove)
        end
      end
      @minimap_shapes.clear
    end
    
    @upgrade_screen.hide if @upgrade_screen
    
    # Удаляем фоновые тайлы
    if @map_background_tiles
      @map_background_tiles.values.each(&:remove)
      @map_background_tiles.clear
    end
    
    # Удаляем объекты карты
    @map&.remove if @map
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

    # Увеличиваем сложность со временем - плавный рост
    game_time = current_time - @game_start_time
    game_minutes = (game_time / 60.0).floor
    
    # Базовый множитель сложности из настроек
    base_difficulty = @settings.difficulty_multiplier_base || 1.0
    
    # +6% каждую минуту (сбалансировано)
    time_multiplier = 1.0 + (game_time / 60.0) * 0.06
    # После 5 минут дополнительный бонус сложности +3% каждую минуту
    if game_time > 300
      extra_time = game_time - 300
      time_multiplier += (extra_time / 60.0) * 0.03
    end
    
    # Объединяем базовую сложность и временной множитель
    @difficulty_multiplier = base_difficulty * time_multiplier
    
    # Проверяем волны каждую минуту
    check_wave_spawn(current_time, game_minutes)

    # Обновляем камеру (следует за игроком)
    @camera.follow(@player.x, @player.y)
    
    # Кэшируем живых врагов (оптимизация - обновляем только при необходимости)
    if @enemies_cache_dirty || @alive_enemies_cache.nil? || @enemies.length != @alive_enemies_cache.length
      @alive_enemies_cache = @enemies.select(&:alive?)
      @enemies_cache_dirty = false
    end

    # Обновляем игрока (теперь с учетом карты и коллизий с врагами)
    @player.update(delta_time, @alive_enemies_cache, @map, @camera)

    # Атака оружием
    new_projectiles = @player.auto_attack(@alive_enemies_cache, delta_time)
    
    if new_projectiles && !new_projectiles.empty?
      new_projectiles.each do |p|
        # Создаем проектиль с правильными параметрами
        proj_type = p[:type]
        proj_x = p[:x] || @player.x
        proj_y = p[:y] || @player.y
        proj_angle = p[:angle] || 0
        proj_damage = p[:damage] || 5
        proj_speed = p[:speed] || 200
        proj_range = p[:range] || 200
        
        # Для креста и чеснока передаем позицию игрока и длительность
        options = p.dup
        if proj_type == :cross
          weapon = @player.weapons.find { |w| w.type == :cross }
          if weapon
            options[:player_x] = @player.x
            options[:player_y] = @player.y
            options[:duration] = weapon.duration
            # Распределяем кресты равномерно вокруг игрока
            cross_count = @player.weapons.count { |w| w.type == :cross }
            options[:initial_angle] = @cross_angle || 0
            @cross_angle = (@cross_angle || 0) + Math::PI * 2 / [cross_count, 1].max
          end
        elsif proj_type == :garlic
          # Для чеснока удаляем старые проектили чеснока перед созданием нового
          @projectiles.reject! do |proj|
            if proj.type == :garlic && proj.active
              proj.remove
              true
            else
              false
            end
          end
          # Передаем позицию игрока для чеснока
          options[:player_x] = @player.x
          options[:player_y] = @player.y
          weapon = @player.weapons.find { |w| w.type == :garlic }
          if weapon
            # Чеснок активен пока оружие существует, но используем длительность для контроля
            options[:duration] = weapon.duration || 999.0 # Очень большая длительность
          end
        end
        
        projectile = Projectile.new(
          proj_type, 
          proj_x, 
          proj_y, 
          proj_angle, 
          proj_damage, 
          proj_speed, 
          proj_range, 
          options
        )
        
        @projectiles << projectile
        
        # Звук выстрела (только для дальнобойного оружия)
        if [:magic_wand, :knife, :axe].include?(p[:type])
          @audio_manager&.play_sound(:projectile_shoot)
        elsif p[:type] == :whip
          @audio_manager&.play_sound(:attack)
        end
        
        # ВАЖНО: Сразу обновляем позиции фигур проектиля с учетом камеры
        if projectile.respond_to?(:update_positions)
          projectile.update_positions(@camera)
        end
      end
    end

    # Обновляем проектили и проверяем коллизии в одном проходе (оптимизация)
    inactive_projectiles = []
    @projectiles.each do |projectile|
      next unless projectile.active
      
      # Передаем позицию игрока для креста
      player_x = @player.x
      player_y = @player.y
      projectile.update(delta_time, @alive_enemies_cache, @map, player_x, player_y)
      
      # ВАЖНО: Обновляем позиции фигур после обновления логики
      if projectile.respond_to?(:update_positions)
        projectile.update_positions(@camera)
      end
      
      # Вампиризм для кнута (урон наносится в update_whip)
      if projectile.type == :whip && projectile.last_damage_dealt && projectile.last_damage_dealt > 0
        @player.apply_vampirism(projectile.last_damage_dealt)
        projectile.last_damage_dealt = 0 # Сбрасываем после применения
      end
      
      # Проверяем столкновения с врагами (оптимизация: сначала проверяем расстояние)
      projectile_x = projectile.x
      projectile_y = projectile.y
      projectile_radius = projectile.range || 50 # Примерный радиус для быстрой проверки
      
      @alive_enemies_cache.each do |enemy|
        # Быстрая проверка расстояния перед точной коллизией
        dx = projectile_x - enemy.x
        dy = projectile_y - enemy.y
        distance_sq = dx * dx + dy * dy
        max_distance = (projectile_radius + enemy.size) * 1.5 # Запас для точной проверки
        
        if distance_sq < max_distance * max_distance && projectile.check_collision(enemy)
          damage_dealt = enemy.take_damage(projectile.damage)
          # Вампиризм для дальнобойного оружия
          @player.apply_vampirism(damage_dealt) if damage_dealt > 0
          # Звук попадания по врагу
          @audio_manager&.play_sound(:enemy_hit)
          projectile.active = false if [:magic_wand, :knife, :axe].include?(projectile.type)
          break # Проектиль попал, переходим к следующему
        end
      end
      
      # Собираем неактивные проектили для удаления
      unless projectile.active
        projectile.remove
        inactive_projectiles << projectile
      end
    end
    
    # Удаляем неактивные проектили одним проходом
    @projectiles.reject! { |p| inactive_projectiles.include?(p) }

    # Проверяем убийства врагов и создаем опыт и золото (оптимизация: помечаем кэш как грязный)
    @enemies.each do |enemy|
      if enemy.just_died?
        @enemies_cache_dirty = true # Помечаем кэш как требующий обновления
        @player.enemies_killed += 1
        
        # Звук смерти врага
        @audio_manager&.play_sound(:enemy_death)
        
        # Отслеживаем убийства элитных мобов
        if enemy.elite && @active_altar
          @elite_enemies_killed += 1
        end
        
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
        
        # Проверяем дроп усиления
        drop_pickup(enemy.x, enemy.y)
      end
    end

    # Обновляем и собираем дропы
    update_pickups(delta_time)
    
    # Обновляем эффекты взрывов
    update_explosions(delta_time)
    update_damage_effects(delta_time)
    
    # Обновляем эффект мигания экрана
    if @screen_flash > 0
      @screen_flash -= delta_time * 2.0 # Быстрое затухание
      @screen_flash = 0 if @screen_flash < 0
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
          # Даем опыт и проверяем повышение уровня
          level_up = @player.add_experience(gem[:value])
          # Звук сбора опыта
          @audio_manager&.play_sound(:pickup)
          if level_up
            # Звук повышения уровня
            @audio_manager&.play_sound(:level_up)
            # Показываем экран улучшений при повышении уровня
            show_upgrade_screen
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
    # Оптимизация: обновляем только видимых врагов (в пределах экрана + запас)
    screen_min_x, screen_min_y = @camera.screen_to_world(-300, -300)
    screen_max_x, screen_max_y = @camera.screen_to_world(@window_width + 300, @window_height + 300)
    
    @enemies.each do |enemy|
      next unless enemy.alive?
      
      # Пропускаем врагов далеко от экрана (оптимизация)
      if enemy.x < screen_min_x || enemy.x > screen_max_x || enemy.y < screen_min_y || enemy.y > screen_max_y
        # Обновляем только позиции для врагов вне экрана (чтобы они не зависали)
        if enemy.respond_to?(:update_positions)
          enemy.update_positions(@camera)
        end
        next
      end
      
      enemy.update(delta_time, @player, @map)
      
      # Обрабатываем атаки боссов с индикацией
      if enemy.boss && enemy.respond_to?(:attack_player)
        # Боссы могут атаковать на любом расстоянии (дальние атаки)
        attack_result = enemy.attack_player(@player)
        if attack_result && attack_result.is_a?(Hash)
          case attack_result[:type]
          when :boss_ranged_attack
            # Создаем индикацию дальней атаки босса
            # Может быть несколько атак за раз
            if attack_result[:attacks] && attack_result[:attacks].is_a?(Array)
              # Создаем несколько атак
              attack_result[:attacks].each do |attack|
                create_boss_ranged_attack_indicator(
                  attack[:x], 
                  attack[:y], 
                  attack[:radius], 
                  attack[:delay], 
                  attack[:damage]
                )
              end
            else
              # Одна атака (старый формат)
              create_boss_ranged_attack_indicator(
                attack_result[:x], 
                attack_result[:y], 
                attack_result[:radius], 
                attack_result[:delay], 
                attack_result[:damage]
              )
            end
            # Обновляем время последней атаки врага
            enemy.instance_variable_set(:@last_attack_time, Time.now.to_f)
          end
        end
      end
      
      # Обрабатываем атаки элитных монстров с индикацией
      if enemy.elite && enemy.respond_to?(:attack_player)
        # Проверяем, может ли враг атаковать
        distance = Math.sqrt((enemy.x - @player.x)**2 + (enemy.y - @player.y)**2)
        
        # Для элитных монстров с дальними атаками используем большой радиус атаки
        # Для ближних атак используем обычный радиус
        max_attack_range = if enemy.ranged
          # Дальняя атака - большой радиус (500 пикселей)
          500
        else
          # Ближняя атака - обычный радиус
          enemy.attack_range
        end
        
        if distance <= max_attack_range
          attack_result = enemy.attack_player(@player)
          if attack_result && attack_result.is_a?(Hash)
            case attack_result[:type]
            when :elite_ranged_attack
              # Создаем индикацию дальней атаки элитного мага
              # Может быть несколько атак за раз
              if attack_result[:attacks] && attack_result[:attacks].is_a?(Array)
                # Создаем несколько атак
                attack_result[:attacks].each do |attack|
                  create_elite_ranged_attack_indicator(
                    attack[:x], 
                    attack[:y], 
                    attack[:radius], 
                    attack[:delay], 
                    attack[:damage]
                  )
                end
              else
                # Одна атака (старый формат)
                create_elite_ranged_attack_indicator(
                  attack_result[:x], 
                  attack_result[:y], 
                  attack_result[:radius], 
                  attack_result[:delay], 
                  attack_result[:damage]
                )
              end
              # Обновляем время последней атаки врага
              enemy.instance_variable_set(:@last_attack_time, Time.now.to_f)
            when :elite_melee_attack
              # Создаем индикацию ближней атаки элитного рыцаря
              create_elite_melee_attack_indicator(
                attack_result[:x], 
                attack_result[:y], 
                attack_result[:radius], 
                attack_result[:delay], 
                attack_result[:damage]
              )
              # Обновляем время последней атаки врага
              enemy.instance_variable_set(:@last_attack_time, Time.now.to_f)
            end
          end
        end
      end
    end

    # Удаляем мертвых врагов (с правильной очисткой)
    # Также удаляем зависших врагов (не двигаются и далеко от игрока)
    dead_enemies = []
    @enemies.each do |enemy|
      # Проверяем, мертв ли враг
      if !enemy.alive? || enemy.health <= 0
        dead_enemies << enemy
      # Проверяем, завис ли враг (не двигается долгое время и далеко от игрока)
      elsif enemy.respond_to?(:@last_x) && enemy.respond_to?(:@last_y)
        last_x = enemy.instance_variable_get(:@last_x)
        last_y = enemy.instance_variable_get(:@last_y)
        not_moving = (enemy.x == last_x && enemy.y == last_y)
        distance_to_player = Math.sqrt((enemy.x - @player.x)**2 + (enemy.y - @player.y)**2)
        # Если враг не двигается и далеко от игрока (более 300 пикселей), возможно он завис
        # Также проверяем, что враг не на экране (вне видимости камеры)
        screen_x, screen_y = @camera.world_to_screen(enemy.x, enemy.y)
        off_screen = screen_x < -500 || screen_x > @window_width + 500 || 
                     screen_y < -500 || screen_y > @window_height + 500
        
        if (not_moving && distance_to_player > 300) || (off_screen && distance_to_player > 500)
          dead_enemies << enemy
        end
      end
    end
    
    dead_enemies.each do |enemy|
      # Принудительно помечаем как мертвого
      enemy.instance_variable_set(:@health, 0) if enemy.health > 0
      enemy.instance_variable_set(:@just_died, true)
      
      # Удаляем спрайт и все его фигуры ПЕРЕД удалением из массива
      if enemy.sprite
        # Дополнительно очищаем shapes перед удалением
        if enemy.sprite.respond_to?(:shapes) && enemy.sprite.shapes
          enemy.sprite.shapes.values.each do |shape|
            if shape.is_a?(Array)
              shape.each do |s|
                s.x = -100000 if s.respond_to?(:x=)
                s.y = -100000 if s.respond_to?(:y=)
                s.remove if s.respond_to?(:remove)
              end
            else
              shape.x = -100000 if shape.respond_to?(:x=)
              shape.y = -100000 if shape.respond_to?(:y=)
              shape.remove if shape.respond_to?(:remove)
            end
          end
        end
        # Удаляем спрайт
        if enemy.sprite.respond_to?(:remove)
          enemy.sprite.remove
        end
        enemy.sprite = nil
      end
      # Удаляем полоску здоровья
      enemy.remove if enemy.respond_to?(:remove)
    end
    # Удаляем мертвых врагов из массива
    @enemies.reject! { |enemy| !enemy.alive? || enemy.health <= 0 || dead_enemies.include?(enemy) }
    # Сбрасываем кэш живых врагов после удаления
    @alive_enemies_cache = nil

    # Спавним новых врагов (с учетом сложности)
    spawn_enemies(current_time)

    # Ограничиваем количество врагов на экране (увеличивается со временем)
    base_max_enemies = @settings.max_enemies
    max_enemies = (base_max_enemies * @difficulty_multiplier).round
    @enemies = @enemies.last(max_enemies) if @enemies.size > max_enemies

    # Обрабатываем взаимодействие с интерактивными объектами
    handle_interactive_objects(delta_time)
    
    # Проверяем убийства элитных мобов от алтарей
    check_elite_enemies_killed
    
    # Проверяем убийство финального босса
    check_final_boss_killed
    
    # Автоматическое появление боссов
    check_boss_spawn(current_time)
    
    # Показываем таймер до появления босса
    show_boss_countdown(current_time)
    
    # Обрабатываем специальные атаки боссов
    handle_boss_special_attacks(delta_time)
    # Обновляем индикаторы атак элитных монстров
    update_elite_attack_indicators(delta_time) if @elite_attack_indicators
    # Обновляем индикаторы атак элитных монстров
    update_elite_attack_indicators(delta_time) if @elite_attack_indicators
    
    # Если игра завершена или игрок мертв, сохраняем рекорд
    if (@game_completed || !@player.alive?) && !@record_saved
      is_new_record = save_high_score
      @record_saved = true
      # Можно показать сообщение о новом рекорде
      if is_new_record
        # Сообщение будет показано на экране завершения
      end
    end
    
    # Если игра завершена, показываем экран завершения и очищаем все объекты
    if @game_completed || !@player.alive?
      # Очищаем всех врагов при завершении игры
      if @enemies
        @enemies.each do |enemy|
          # Принудительно помечаем как мертвого
          enemy.instance_variable_set(:@health, 0) if enemy.health > 0
          enemy.instance_variable_set(:@just_died, true)
          
          # Удаляем спрайт и все его фигуры
          if enemy.sprite
            if enemy.sprite.respond_to?(:shapes) && enemy.sprite.shapes
              enemy.sprite.shapes.values.each do |shape|
                if shape.is_a?(Array)
                  shape.each do |s|
                    s.x = -100000 if s.respond_to?(:x=)
                    s.y = -100000 if s.respond_to?(:y=)
                    s.remove if s.respond_to?(:remove)
                  end
                else
                  shape.x = -100000 if shape.respond_to?(:x=)
                  shape.y = -100000 if shape.respond_to?(:y=)
                  shape.remove if shape.respond_to?(:remove)
                end
              end
            end
            enemy.sprite.remove if enemy.sprite.respond_to?(:remove)
            enemy.sprite = nil
          end
          enemy.remove if enemy.respond_to?(:remove)
        end
        @enemies.clear
      end
      
      show_completion_screen if @game_completed
    end
  end
  
  def handle_boss_special_attacks(delta_time)
    current_time = Time.now.to_f
    
    @enemies.each do |enemy|
      next unless (enemy.boss || enemy.elite) && enemy.alive?
      
      # Проверяем специальные атаки
      if enemy.respond_to?(:use_special_attack)
        attack_result = enemy.use_special_attack(@player, current_time)
        if attack_result
          case attack_result[:type]
          when :area_damage
            # Создаем визуальный эффект атаки по области
            create_boss_area_attack_effect(attack_result[:x], attack_result[:y], attack_result[:radius])
          when :ranged_attack
            # Создаем индикацию дальней атаки элитного мага (красный круг)
            create_elite_ranged_attack_indicator(attack_result[:x], attack_result[:y], attack_result[:radius], attack_result[:delay], attack_result[:damage])
          end
        end
      end
    end
  end
  
  def create_elite_ranged_attack_indicator(x, y, radius, delay, damage)
    # Создаем индикатор атаки (ярко-красный круг)
    screen_x, screen_y = @camera.world_to_screen(x, y)
    indicator = {
      x: x,
      y: y,
      radius: radius,
      delay: delay,
      time: 0.0,
      damage: damage,
      type: :ranged,
      shape: Circle.new(
        x: screen_x, y: screen_y,
        radius: radius,
        color: [255, 0, 0, 0.7],  # Ярко-красный, более непрозрачный
        z: 498
      )
    }
    @elite_attack_indicators ||= []
    @elite_attack_indicators << indicator
  end
  
  def create_boss_ranged_attack_indicator(x, y, radius, delay, damage)
    # Создаем индикатор дальней атаки босса (темно-красный круг)
    screen_x, screen_y = @camera.world_to_screen(x, y)
    indicator = {
      x: x,
      y: y,
      radius: radius,
      delay: delay,
      time: 0.0,
      damage: damage,
      type: :boss_ranged,
      shape: Circle.new(
        x: screen_x, y: screen_y,
        radius: radius,
        color: [200, 0, 0, 0.5],  # Темно-красный
        z: 498
      )
    }
    @elite_attack_indicators ||= []
    @elite_attack_indicators << indicator
  end
  
  def create_elite_melee_attack_indicator(x, y, radius, delay, damage)
    # Создаем индикатор ближней атаки (оранжево-красный круг вокруг врага)
    screen_x, screen_y = @camera.world_to_screen(x, y)
    indicator = {
      x: x,
      y: y,
      radius: radius,
      delay: delay,
      time: 0.0,
      damage: damage,
      type: :melee,
      shape: Circle.new(
        x: screen_x, y: screen_y,
        radius: radius,
        color: [255, 100, 0, 0.7],  # Оранжево-красный, более непрозрачный
        z: 498
      )
    }
    @elite_attack_indicators ||= []
    @elite_attack_indicators << indicator
  end
  
  def update_elite_attack_indicators(delta_time)
    return unless @elite_attack_indicators
    @elite_attack_indicators.each do |indicator|
      indicator[:time] += delta_time
      
      # ВАЖНО: позиция индикатора НЕ обновляется - она зафиксирована на момент создания
      # Это позволяет игроку увернуться от атаки, переместившись из зоны удара
      # Для дальней атаки позиция предсказана на момент создания индикатора
      # Для ближней атаки позиция остается на месте врага
      
      screen_x, screen_y = @camera.world_to_screen(indicator[:x], indicator[:y])
      indicator[:shape].x = screen_x
      indicator[:shape].y = screen_y
      
      # Пульсирующий эффект
      pulse = 1.0 + Math.sin(indicator[:time] * 5) * 0.1
      indicator[:shape].radius = indicator[:radius] * pulse
      
      # Увеличиваем непрозрачность по мере приближения удара
      progress = [indicator[:time] / indicator[:delay], 1.0].min
      
      if indicator[:type] == :ranged
        # Дальняя атака элитного мага - ярко-красный цвет, держится дольше
        alpha = 0.6 + (progress * 0.3)  # От 0.6 до 0.9 (более заметно)
        indicator[:shape].color = [255, 0, 0, alpha]  # Ярко-красный
      elsif indicator[:type] == :boss_ranged
        # Дальняя атака босса - темно-красный цвет
        alpha = 0.5 + (progress * 0.3)  # От 0.5 до 0.8
        indicator[:shape].color = [200, 0, 0, alpha]
      elsif indicator[:type] == :boss_melee
        # Ближняя атака босса - оранжевый цвет
        alpha = 0.6 + (progress * 0.2)  # От 0.6 до 0.8
        indicator[:shape].color = [255, 150, 0, alpha]
      elsif indicator[:type] == :boss_pattern
        # Паттерн атаки босса - ярко-красный цвет
        alpha = 0.4 + (progress * 0.4)  # От 0.4 до 0.8
        indicator[:shape].color = [255, 50, 50, alpha]
      elsif indicator[:type] == :final_boss_pattern
        # Паттерн атаки финального босса - сохраняем оригинальный цвет, меняем только альфу
        alpha = 0.5 + (progress * 0.3)  # От 0.5 до 0.8
        current_color = indicator[:shape].color
        if current_color.is_a?(Array) && current_color.length >= 3
          indicator[:shape].color = [current_color[0], current_color[1], current_color[2], alpha]
        end
      else
        # Ближняя атака элитного рыцаря - оранжево-красный цвет
        alpha = 0.5 + (progress * 0.3)  # От 0.5 до 0.8
        indicator[:shape].color = [255, 100, 0, alpha]
      end
      
      # Когда время истекло - наносим урон и удаляем индикатор
      if indicator[:time] >= indicator[:delay]
        # Наносим урон игроку, если он в радиусе
        distance = Math.sqrt((indicator[:x] - @player.x)**2 + (indicator[:y] - @player.y)**2)
        # Проверяем урон с учетом увеличенного радиуса
        if distance <= indicator[:radius]
          @player.take_damage(indicator[:damage], @audio_manager)
        end
        
        # Удаляем индикатор
        indicator[:shape].remove
        @elite_attack_indicators.delete(indicator)
      end
    end
  end
  
  def create_boss_area_attack_effect(x, y, radius)
    # Создаем визуальный эффект атаки босса по области (красные круги)
    effect = {
      x: x,
      y: y,
      radius: 0,
      max_radius: radius,
      duration: 0.5,
      time: 0.0,
      shapes: []
    }
    
    # Создаем несколько концентрических кругов
    3.times do |i|
      effect[:shapes] << Circle.new(
        x: x, y: y,
        radius: 0,
        color: [255, 100 + i * 50, 100 + i * 50, 0.6 - i * 0.15],
        z: 499
      )
    end
    
    @explosions << effect
  end
  
  def check_wave_spawn(current_time, game_minutes)
    # Волны появляются каждую минуту (1, 2, 3, 4...)
    if game_minutes > 0 && game_minutes != @last_wave_minute && !@wave_spawned_this_minute
      spawn_wave(current_time, game_minutes)
      @wave_spawned_this_minute = true
      @last_wave_minute = game_minutes
    elsif game_minutes != @last_wave_minute
      @wave_spawned_this_minute = false
    end
  end
  
  def spawn_wave(current_time, game_minutes)
    # Большая волна монстров каждую минуту
    # Количество врагов в волне увеличивается со временем
    base_wave_size = 8 + (game_minutes * 2) # 8 + 2 за каждую минуту
    wave_size = [base_wave_size, 30].min # Максимум 30 врагов в волне
    
    # Количество элитных мобов в волне
    elite_count = 1 + (game_minutes / 3) # 1 элитный + 1 каждые 3 минуты
    elite_count = [elite_count, 5].min # Максимум 5 элитных
    
    # Спавним обычных мобов
    (wave_size - elite_count).times do
      spawn_wave_enemy(current_time, false)
    end
    
    # Спавним элитных мобов
    elite_count.times do
      spawn_wave_enemy(current_time, true)
    end
  end
  
  def spawn_wave_enemy(current_time, elite = false)
    # Получаем границы видимой области
    min_x, min_y = @camera.screen_to_world(0, 0)
    max_x, max_y = @camera.screen_to_world(@window_width, @window_height)
    
    # Получаем границы карты
    map_min_x = -@map.width / 2
    map_max_x = @map.width / 2
    map_min_y = -@map.height / 2
    map_max_y = @map.height / 2
    
    spawn_offset = 50
    
    # Спавним на краю экрана
    side = rand(4)
    case side
    when 0 # верх
      x = min_x + rand(max_x - min_x)
      y = min_y - spawn_offset
      x = [[x, map_min_x + 20].max, map_max_x - 20].min
      y = [y, map_min_y + 20].max
    when 1 # право
      x = max_x + spawn_offset
      y = min_y + rand(max_y - min_y)
      x = [x, map_max_x - 20].min
      y = [[y, map_min_y + 20].max, map_max_y - 20].min
    when 2 # низ
      x = min_x + rand(max_x - min_x)
      y = max_y + spawn_offset
      x = [[x, map_min_x + 20].max, map_max_x - 20].min
      y = [y, map_max_y - 20].min
    when 3 # лево
      x = min_x - spawn_offset
      y = min_y + rand(max_y - min_y)
      x = [x, map_min_x + 20].max
      y = [[y, map_min_y + 20].max, map_max_y - 20].min
    end
    
    # Проверяем границы карты
    return if x < map_min_x || x > map_max_x || y < map_min_y || y > map_max_y
    
    # Вычисляем время игры
    game_time = (current_time - @game_start_time).to_i
    
    # Выбираем тип врага
    if elite
      # Элитные мобы
      available_elite = [:elite_knight, :elite_mage]
      enemy_type_key = available_elite.sample
    else
      # Обычные мобы
      available_types = EnemyTypes.available_types(game_time)
      return if available_types.empty?
      enemy_type_key = weighted_random_enemy_type(available_types, game_time)
      return unless enemy_type_key
    end
    
    # Проверяем расстояние до игрока
    distance_to_player = Math.sqrt((x - @player.x)**2 + (y - @player.y)**2)
    return if distance_to_player <= 100
    
    # Создаем врага с усиленным множителем сложности для волн
    wave_difficulty = @difficulty_multiplier * 1.2 # +20% к сложности в волнах
    enemy = Enemy.new(x, y, enemy_type_key, wave_difficulty)
    enemy.ensure_shapes
    @enemies << enemy
  end

  def check_boss_spawn(current_time)
    return if @final_boss_spawned
    
    # Проверяем, есть ли уже живой босс (кроме финального)
    has_living_boss = @enemies.any? { |e| e.boss && e.alive? && !e.enemy_type == :final_boss }
    return if has_living_boss  # Боссы появляются по одному
    
    game_time = (current_time - @game_start_time).to_i
    game_minutes = game_time / 60
    
    # Боссы появляются каждые 3 минуты (3, 6, 9, 12...)
    boss_minute = 3
    if game_minutes >= boss_minute && game_minutes % 3 == 0 && !@boss_spawned_this_minute
      spawn_boss(current_time)
      @boss_spawned_this_minute = true
      @last_boss_minute = game_minutes
    elsif game_minutes != @last_boss_minute
      @boss_spawned_this_minute = false
    end
  end
  
  def spawn_boss(current_time)
    # Спавним босса на расстоянии от игрока (не слишком близко, не слишком далеко)
    min_distance = 250
    max_distance = 450
    
    # Пытаемся найти подходящую позицию
    attempts = 0
    x = 0
    y = 0
    
    loop do
      # Выбираем случайный угол от игрока
      angle = rand * Math::PI * 2
      spawn_distance = min_distance + rand(max_distance - min_distance)
      
      # Вычисляем позицию босса
      x = @player.x + Math.cos(angle) * spawn_distance
      y = @player.y + Math.sin(angle) * spawn_distance
      
      # Ограничиваем позицию границами карты
      map_min_x = -@map.width / 2 + 50
      map_max_x = @map.width / 2 - 50
      map_min_y = -@map.height / 2 + 50
      map_max_y = @map.height / 2 - 50
      
      x = [[x, map_min_x].max, map_max_x].min
      y = [[y, map_min_y].max, map_max_y].min
      
      # Проверяем, что позиция не слишком близко к игроку
      distance_to_player = Math.sqrt((x - @player.x)**2 + (y - @player.y)**2)
      break if distance_to_player >= min_distance || attempts >= 10
      
      attempts += 1
    end
    
    # Создаем обычного босса (не финального)
    # Боссы получают дополнительный множитель сложности
    boss_multiplier = @difficulty_multiplier * 2.0  # Увеличено с 1.5
    boss = Enemy.new(x, y, :boss, boss_multiplier)
    boss.ensure_shapes
    @enemies << boss
    
    # Звук спавна босса
    @audio_manager&.play_sound(:boss_spawn)
    
    # Показываем индикацию появления босса
    show_boss_warning
  end
  
  def show_boss_warning
    # Создаем текст предупреждения о боссе
    unless @ui_texts[:boss_warning]
      @ui_texts[:boss_warning] = Text.new(
        "ВНИМАНИЕ! Появился босс!",
        x: @window_width / 2 - 150,
        y: 100,
        size: 30,
        color: '#FF0000',
        z: 1000
      )
    end
    
    # Убираем предупреждение через 3 секунды
    @boss_warning_time = Time.now.to_f + 3.0
  end
  
  def show_boss_countdown(current_time)
    game_time = (current_time - @game_start_time).to_i
    game_minutes = game_time / 60
    next_boss_minute = ((game_minutes / 3) + 1) * 3
    seconds_until_boss = (next_boss_minute * 60) - game_time
    
    if seconds_until_boss <= 10 && seconds_until_boss > 0 && !@boss_spawned_this_minute
      countdown_text = "Босс появится через: #{seconds_until_boss} сек"
      if @ui_texts[:boss_countdown]
        @ui_texts[:boss_countdown].text = countdown_text
        @ui_texts[:boss_countdown].x = @window_width / 2 - 120
        @ui_texts[:boss_countdown].y = 50
      else
        @ui_texts[:boss_countdown] = Text.new(
          countdown_text,
          x: @window_width / 2 - 120,
          y: 50,
          size: 20,
          color: '#FFAA00',
          z: 1000
        )
      end
    elsif @ui_texts[:boss_countdown] && (seconds_until_boss > 10 || @boss_spawned_this_minute)
      @ui_texts[:boss_countdown]&.remove
      @ui_texts[:boss_countdown] = nil
    end
  end
  
  def handle_boss_special_attacks(delta_time)
    current_time = Time.now.to_f
    
    @enemies.each do |enemy|
      next unless (enemy.boss || enemy.elite) && enemy.alive?
      
      # Проверяем специальные атаки
      if enemy.respond_to?(:use_special_attack)
        attack_result = enemy.use_special_attack(@player, current_time)
        if attack_result
          case attack_result[:type]
          when :area_damage
            # Создаем визуальный эффект атаки по области
            create_boss_area_attack_effect(attack_result[:x], attack_result[:y], attack_result[:radius])
          when :ranged_attack
            # Создаем индикацию дальней атаки элитного мага (красный круг)
            create_elite_ranged_attack_indicator(attack_result[:x], attack_result[:y], attack_result[:radius], attack_result[:delay], attack_result[:damage])
          end
        end
      end
    end
  end
  
  def create_elite_ranged_attack_indicator(x, y, radius, delay, damage)
    # Создаем индикатор атаки (ярко-красный круг)
    screen_x, screen_y = @camera.world_to_screen(x, y)
    indicator = {
      x: x,
      y: y,
      radius: radius,
      delay: delay,
      time: 0.0,
      damage: damage,
      type: :ranged,
      shape: Circle.new(
        x: screen_x, y: screen_y,
        radius: radius,
        color: [255, 0, 0, 0.7],  # Ярко-красный, более непрозрачный
        z: 498
      )
    }
    @elite_attack_indicators ||= []
    @elite_attack_indicators << indicator
  end
  
  def create_boss_ranged_attack_indicator(x, y, radius, delay, damage)
    # Создаем индикатор дальней атаки босса (темно-красный круг)
    screen_x, screen_y = @camera.world_to_screen(x, y)
    indicator = {
      x: x,
      y: y,
      radius: radius,
      delay: delay,
      time: 0.0,
      damage: damage,
      type: :boss_ranged,
      shape: Circle.new(
        x: screen_x, y: screen_y,
        radius: radius,
        color: [200, 0, 0, 0.5],  # Темно-красный
        z: 498
      )
    }
    @elite_attack_indicators ||= []
    @elite_attack_indicators << indicator
  end
  
  def create_elite_melee_attack_indicator(x, y, radius, delay, damage)
    # Создаем индикатор ближней атаки (оранжево-красный круг вокруг врага)
    screen_x, screen_y = @camera.world_to_screen(x, y)
    indicator = {
      x: x,
      y: y,
      radius: radius,
      delay: delay,
      time: 0.0,
      damage: damage,
      type: :melee,
      shape: Circle.new(
        x: screen_x, y: screen_y,
        radius: radius,
        color: [255, 100, 0, 0.7],  # Оранжево-красный, более непрозрачный
        z: 498
      )
    }
    @elite_attack_indicators ||= []
    @elite_attack_indicators << indicator
  end
  
  def update_elite_attack_indicators(delta_time)
    return unless @elite_attack_indicators
    @elite_attack_indicators.each do |indicator|
      indicator[:time] += delta_time
      
      # ВАЖНО: позиция индикатора НЕ обновляется - она зафиксирована на момент создания
      # Это позволяет игроку увернуться от атаки, переместившись из зоны удара
      # Для дальней атаки позиция предсказана на момент создания индикатора
      # Для ближней атаки позиция остается на месте врага
      
      screen_x, screen_y = @camera.world_to_screen(indicator[:x], indicator[:y])
      indicator[:shape].x = screen_x
      indicator[:shape].y = screen_y
      
      # Пульсирующий эффект
      pulse = 1.0 + Math.sin(indicator[:time] * 5) * 0.1
      indicator[:shape].radius = indicator[:radius] * pulse
      
      # Увеличиваем непрозрачность по мере приближения удара
      progress = [indicator[:time] / indicator[:delay], 1.0].min
      
      if indicator[:type] == :ranged
        # Дальняя атака элитного мага - ярко-красный цвет, держится дольше
        alpha = 0.6 + (progress * 0.3)  # От 0.6 до 0.9 (более заметно)
        indicator[:shape].color = [255, 0, 0, alpha]  # Ярко-красный
      elsif indicator[:type] == :boss_ranged
        # Дальняя атака босса - темно-красный цвет
        alpha = 0.5 + (progress * 0.3)  # От 0.5 до 0.8
        indicator[:shape].color = [200, 0, 0, alpha]
      elsif indicator[:type] == :boss_melee
        # Ближняя атака босса - оранжевый цвет
        alpha = 0.6 + (progress * 0.2)  # От 0.6 до 0.8
        indicator[:shape].color = [255, 150, 0, alpha]
      elsif indicator[:type] == :boss_pattern
        # Паттерн атаки босса - ярко-красный цвет
        alpha = 0.4 + (progress * 0.4)  # От 0.4 до 0.8
        indicator[:shape].color = [255, 50, 50, alpha]
      elsif indicator[:type] == :final_boss_pattern
        # Паттерн атаки финального босса - сохраняем оригинальный цвет, меняем только альфу
        alpha = 0.5 + (progress * 0.3)  # От 0.5 до 0.8
        current_color = indicator[:shape].color
        if current_color.is_a?(Array) && current_color.length >= 3
          indicator[:shape].color = [current_color[0], current_color[1], current_color[2], alpha]
        end
      else
        # Ближняя атака элитного рыцаря - оранжево-красный цвет
        alpha = 0.5 + (progress * 0.3)  # От 0.5 до 0.8
        indicator[:shape].color = [255, 100, 0, alpha]
      end
      
      # Когда время истекло - наносим урон и удаляем индикатор
      if indicator[:time] >= indicator[:delay]
        # Наносим урон игроку, если он в радиусе
        distance = Math.sqrt((indicator[:x] - @player.x)**2 + (indicator[:y] - @player.y)**2)
        # Проверяем урон с учетом увеличенного радиуса
        if distance <= indicator[:radius]
          @player.take_damage(indicator[:damage], @audio_manager)
        end
        
        # Удаляем индикатор
        indicator[:shape].remove
        @elite_attack_indicators.delete(indicator)
      end
    end
  end
  
  def create_boss_area_attack_effect(x, y, radius)
    # Создаем визуальный эффект атаки босса по области (красные круги)
    effect = {
      x: x,
      y: y,
      radius: 0,
      max_radius: radius,
      duration: 0.5,
      time: 0.0,
      shapes: []
    }
    
    # Создаем несколько концентрических кругов
    3.times do |i|
      effect[:shapes] << Circle.new(
        x: x, y: y,
        radius: 0,
        color: [255, 100 + i * 50, 100 + i * 50, 0.6 - i * 0.15],
        z: 499
      )
    end
    
    @explosions << effect
  end

  def handle_interactive_objects(delta_time)
    # Большой радиус для сундуков и ящиков, чтобы можно было бегать по кругу во время открытия
    chest_interaction_range = 84  # Уменьшено на 30% (было 120) для сундуков
    barrel_interaction_range = 84  # Уменьшено на 30% (было 120) для ящиков
    default_interaction_range = 40  # Обычный радиус для других объектов
    
    # Оптимизация: обновляем только видимые объекты (в пределах экрана + запас)
    screen_min_x, screen_min_y = @camera.screen_to_world(-200, -200)
    screen_max_x, screen_max_y = @camera.screen_to_world(@window_width + 200, @window_height + 200)
    
    # Создаем копию массива объектов, чтобы можно было безопасно удалять элементы во время итерации
    objects_to_check = @map.objects.dup
    
    # Проверяем близость к интерактивным объектам (только видимые)
    objects_to_check.each do |obj|
      # Пропускаем объекты далеко от экрана (оптимизация)
      if obj.x < screen_min_x || obj.x > screen_max_x || obj.y < screen_min_y || obj.y > screen_max_y
        next
      end
      next unless obj.interactive
      next if (obj.opened || obj.destroyed) && obj.type != :free_chest # Бесплатный сундук можно открыть
      next unless @map.objects.include?(obj) # Пропускаем, если объект уже удален
      
      # Для сундуков - прогрессивное открытие с индикацией
      if obj.type == :chest
        can_interact = obj.can_interact?(@player.x, @player.y, chest_interaction_range)
        obj.set_highlight(can_interact, @camera, chest_interaction_range)
        
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
      elsif obj.type == :free_chest
        # Бесплатный сундук - открывается без стоимости
        can_interact = obj.can_interact?(@player.x, @player.y, chest_interaction_range)
        obj.set_highlight(can_interact, @camera, chest_interaction_range)
        
        if can_interact && !obj.opened
          # Обновляем прогресс (без стоимости)
          obj.update_interaction_progress(delta_time, @camera, 0, @player.gold)
          if obj.interaction_progress >= 1.0
            open_chest(obj, free: true)
            next
          end
        else
          obj.reset_interaction_progress
        end
      elsif obj.type == :barrel
        # Для ящиков - прогрессивное разрушение с индикацией (как у сундуков)
        can_interact = obj.can_interact?(@player.x, @player.y, barrel_interaction_range)
        obj.set_highlight(can_interact, @camera, barrel_interaction_range)
        
        if can_interact && !obj.destroyed
          # Начинаем разрушение, если еще не начато
          obj.start_destruction unless obj.destroying?
          
          # Показываем прогресс и обновляем его
          obj.update_interaction_progress(delta_time, @camera)
          if obj.interaction_progress >= 1.0
            destroy_barrel(obj)
            next # Объект удален, переходим к следующему
          end
        else
          # Сбрасываем прогресс, если игрок отошел
          obj.reset_interaction_progress
        end
      elsif obj.type == :altar
        # Алтари - вызывают группу элитных мобов
        can_interact = obj.can_interact?(@player.x, @player.y, default_interaction_range)
        obj.set_highlight(can_interact, @camera, default_interaction_range)
        
        if can_interact && !obj.opened
          obj.update_interaction_progress(delta_time, @camera)
          if obj.interaction_progress >= 1.0
            activate_altar(obj)
            next
          end
        else
          obj.reset_interaction_progress
        end
      elsif obj.type == :portal
        # Портал - вызывает финального босса
        can_interact = obj.can_interact?(@player.x, @player.y, default_interaction_range)
        obj.set_highlight(can_interact, @camera, default_interaction_range)
        
        if can_interact && !obj.opened
          obj.update_interaction_progress(delta_time, @camera)
          if obj.interaction_progress >= 1.0
            activate_portal(obj)
            next
          end
        else
          obj.reset_interaction_progress
        end
      end
    end
    
    # Проверяем разрушение бочек при атаке
    check_barrel_destruction
  end

  def get_chest_cost
    # Прогрессивная стоимость: базовая стоимость * (1.5 ^ количество открытых сундуков)
    base_cost = 10 # Базовая стоимость первого сундука (уменьшено с 50 до 10)
    multiplier = 1.5 # Множитель прогрессии
    (base_cost * (multiplier ** @chests_opened)).round
  end

  def open_chest(chest, free: false)
    # Строгая проверка - если сундук уже открыт или уничтожен, не открываем
    return if chest.destroyed
    return if chest.opened # Не открываем уже открытый сундук (кроме free_chest, но он обрабатывается отдельно)
    
    # Для бесплатного сундука проверяем отдельно
    if chest.type == :free_chest && chest.opened
      return
    end
    
    # Проверяем, достаточно ли золота для открытия (если не бесплатный)
    unless free || chest.type == :free_chest
      cost = get_chest_cost
      if @player.gold < cost
        # Недостаточно золота - не открываем
        return
      end
      
      # Вычитаем золото
      @player.gold -= cost
      
      # Увеличиваем счетчик открытых сундуков
      @chests_opened += 1
    end
    
    # Отмечаем сундук как открытый ПЕРЕД генерацией наград
    chest.open!
    
    # Звук открытия сундука
    @audio_manager&.play_sound(:chest_open)
    
    # Для всех сундуков - показываем экран улучшений с наградами из сундука
    rewards = generate_chest_rewards
    
    # Преобразуем награды из сундука в формат для экрана улучшений
    available = []
    rewards.each do |reward|
      case reward[:type]
      when :new_weapon
        available << {
          type: :new_weapon,
          weapon_type: reward[:weapon_type],
          weapon: reward[:weapon],
          name: reward[:name],
          icon: reward[:icon],
          level: 0,
          max_level: reward[:weapon].max_level,
          rarity: reward[:rarity],
          rarity_multiplier: reward[:rarity_multiplier]
        }
      when :weapon_upgrade
        available << {
          type: :weapon_upgrade,
          weapon_type: reward[:weapon_type],
          weapon: reward[:weapon],
          name: reward[:name],
          icon: reward[:icon],
          level: reward[:level],
          max_level: reward[:max_level],
          rarity: reward[:rarity],
          rarity_multiplier: reward[:rarity_multiplier],
          chest_upgrade: reward[:chest_upgrade]
        }
      when :new_passive
        available << {
          type: :new_passive,
          passive_type: reward[:passive_type],
          passive: reward[:passive],
          name: reward[:name],
          icon: reward[:icon],
          level: 0,
          max_level: reward[:passive].max_level,
          rarity: reward[:rarity],
          rarity_multiplier: reward[:rarity_multiplier]
        }
      when :passive_upgrade
        available << {
          type: :passive_upgrade,
          passive_type: reward[:passive_type],
          passive: reward[:passive],
          name: reward[:name],
          icon: reward[:icon],
          level: reward[:level],
          max_level: reward[:max_level],
          rarity: reward[:rarity],
          rarity_multiplier: reward[:rarity_multiplier]
        }
      when :experience, :gold
        # Опыт и золото применяем напрямую (если есть)
        if reward[:type] == :experience
          @player.add_experience(reward[:amount])
        elsif reward[:type] == :gold
          @player.gold += reward[:amount]
        end
      end
    end
    
    # Показываем экран улучшений с наградами из сундука
    # ВАЖНО: Всегда показываем экран, даже если наград нет (только опыт/золото)
    # Это гарантирует, что игрок видит, что сундук открыт
    if !available.empty?
      @upgrade_screen.show_vs_upgrades(available, @vs_upgrade_system)
      @showing_upgrades = true
      @player.keys_pressed.clear
      @last_time = Time.now.to_f
    elsif rewards.any? { |r| r[:type] == :experience || r[:type] == :gold }
      # Если есть только опыт/золото, показываем обычный экран улучшений при повышении уровня
      # Но если уровень не повысился, просто не показываем экран (опыт уже применен)
      # Это нормально - опыт и золото уже применены напрямую
    end
    
    # Удаляем сундук из карты после открытия
    chest.remove # Удаляем все фигуры
    @map.objects.delete(chest) # Удаляем из массива объектов карты
    @map.cache_interactive_objects if @map.respond_to?(:cache_interactive_objects) # Обновляем кэш
  end
  
  def apply_chest_rewards(rewards, chest_x, chest_y)
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
        # Даем опыт и проверяем, повысился ли уровень
        if @player.add_experience(reward[:amount])
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
        x: chest_x + rand(-10..10),
        y: chest_y + rand(-10..10),
        value: reward[:amount],
        collected: false,
        being_collected: false,
        collect_speed: 200.0,
        shapes: []
      }
    end
    
    level_up
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
    
    # Бочки дают опыт (увеличено)
    exp_amount = 20 + rand(40)  # Было 10 + rand(30), теперь 20-60 опыта
    
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
    @map.cache_interactive_objects if @map.respond_to?(:cache_interactive_objects) # Обновляем кэш
  end
  
  def drop_pickup(x, y)
    # Проверяем шанс дропа
    return if rand >= @player.drop_chance
    
    # Выбираем случайный тип дропа
    pickup_types = Pickup::TYPES.keys
    pickup_type = pickup_types.sample
    
    # Создаем дроп
    pickup = Pickup.new(x, y, pickup_type)
    @pickups << pickup
  end
  
  def update_pickups(delta_time)
    @pickups.each do |pickup|
      next if pickup.collected
      
      # Проверяем расстояние до игрока
      distance = Math.sqrt((pickup.x - @player.x)**2 + (pickup.y - @player.y)**2)
      
      # Если близко, собираем дроп
      if distance <= 30
        collect_pickup(pickup)
      else
        # Обновляем позиции визуальных элементов
        pickup.update_positions(@camera)
      end
    end
  end
  
  def collect_pickup(pickup)
    return if pickup.collected
    
    pickup.collected = true
    
    case pickup.type
    when :health
      # Восстанавливаем здоровье
      heal_amount = (@player.max_health * Pickup::TYPES[:health][:heal_amount]).round
      @player.health = [@player.health + heal_amount, @player.max_health].min
      
    when :free_chest
      # Создаем бесплатный сундук на месте дропа (выглядит по-другому)
      # НЕ открываем сразу - игрок должен открыть его вручную через handle_interactive_objects
      # Это позволит показать только экран улучшений, а не применять награды напрямую
      chest = MapObject.new(pickup.x, pickup.y, :free_chest)
      # Обновляем позиции фигур относительно камеры
      chest.update_positions(@camera) if chest.respond_to?(:update_positions)
      @map.objects << chest
      
    when :magnet
      # Притягиваем весь опыт с карты
      @experience_gems.each do |gem|
        next if gem[:collected]
        gem[:being_collected] = true
        gem[:collect_speed] = 500.0 # Быстрое притягивание
      end
      
    when :bomb
      # Взрыв - наносим урон всем врагам в радиусе
      bomb_data = Pickup::TYPES[:bomb]
      damage = bomb_data[:damage]
      radius = bomb_data[:radius]
      
      # Создаем визуальный эффект взрыва
      create_bomb_explosion(pickup.x, pickup.y, radius)
      
      @enemies.each do |enemy|
        next unless enemy.alive?
        
        distance = Math.sqrt((enemy.x - pickup.x)**2 + (enemy.y - pickup.y)**2)
        if distance <= radius
          enemy.take_damage(damage)
        end
      end
    end
    
    pickup.remove
  end
  
  def activate_altar(altar)
    return if altar.opened
    
    altar.open!
    
    # Спавним группу элитных мобов на расстоянии от игрока и в одной куче
    elite_types = EnemyTypes.elite_types
    return if elite_types.empty?
    
    elite_count = 3 + rand(3) # 3-5 элитных мобов
    
    # Выбираем позицию на расстоянии от игрока (200-350 пикселей)
    min_distance = 200
    max_distance = 350
    spawn_distance = min_distance + rand(max_distance - min_distance)
    
    # Выбираем случайный угол от игрока
    angle = rand * Math::PI * 2
    
    # Центр группы элитных монстров
    group_center_x = @player.x + Math.cos(angle) * spawn_distance
    group_center_y = @player.y + Math.sin(angle) * spawn_distance
    
    # Ограничиваем позицию границами карты
    map_min_x = -@map.width / 2 + 50
    map_max_x = @map.width / 2 - 50
    map_min_y = -@map.height / 2 + 50
    map_max_y = @map.height / 2 - 50
    
    group_center_x = [[group_center_x, map_min_x].max, map_max_x].min
    group_center_y = [[group_center_y, map_min_y].max, map_max_y].min
    
    # Спавним элитных монстров в одной куче вокруг центра группы
    elite_count.times do |i|
      # Небольшое случайное смещение от центра (в радиусе 30-50 пикселей)
      offset_angle = rand * Math::PI * 2
      offset_distance = 30 + rand(20)
      x = group_center_x + Math.cos(offset_angle) * offset_distance
      y = group_center_y + Math.sin(offset_angle) * offset_distance
      
      # Ограничиваем границами карты
      x = [[x, map_min_x].max, map_max_x].min
      y = [[y, map_min_y].max, map_max_y].min
      
      # Выбираем случайный элитный тип
      elite_type = elite_types.keys.sample
      enemy = Enemy.new(x, y, elite_type, @difficulty_multiplier)
      enemy.ensure_shapes
      @enemies << enemy
    end
    
    # Помечаем алтарь как активированный (для отслеживания убийств элитных мобов)
    @active_altar = altar
    @elite_enemies_to_kill = elite_count
    @elite_enemies_killed = 0
  end
  
  def activate_portal(portal)
    return if portal.opened || @final_boss_spawned
    
    portal.open!
    @final_boss_spawned = true
    
    # Спавним финального босса на расстоянии от игрока (не на портале)
    boss_type = :final_boss
    # Финальный босс получает огромный множитель сложности
    final_boss_multiplier = @difficulty_multiplier * 3.0  # Увеличено с 2.0
    
    # Находим позицию на расстоянии от игрока (200-400 пикселей)
    min_distance = 200
    max_distance = 400
    spawn_distance = min_distance + rand(max_distance - min_distance)
    
    # Выбираем случайный угол от игрока
    angle = rand * Math::PI * 2
    
    # Вычисляем позицию босса
    boss_x = @player.x + Math.cos(angle) * spawn_distance
    boss_y = @player.y + Math.sin(angle) * spawn_distance
    
    # Ограничиваем позицию границами карты
    map_min_x = -@map.width / 2 + 50
    map_max_x = @map.width / 2 - 50
    map_min_y = -@map.height / 2 + 50
    map_max_y = @map.height / 2 - 50
    
    boss_x = [[boss_x, map_min_x].max, map_max_x].min
    boss_y = [[boss_y, map_min_y].max, map_max_y].min
    
    boss = Enemy.new(boss_x, boss_y, boss_type, final_boss_multiplier)
    boss.ensure_shapes
    @enemies << boss
    @final_boss = boss
    # Звук спавна финального босса
    @audio_manager&.play_sound(:boss_spawn)
  end
  
  def check_elite_enemies_killed
    return unless @active_altar
    
    # Проверяем, все ли элитные мобы убиты
    current_elite_count = @enemies.count { |e| e.elite && e.alive? }
    
    # Если все элитные мобы убиты, даем награду
    if current_elite_count == 0 && @elite_enemies_killed >= @elite_enemies_to_kill
      # Всегда даем бесплатный сундук на месте алтаря
      chest = MapObject.new(@active_altar.x, @active_altar.y, :free_chest)
      # Обновляем позиции фигур относительно камеры
      chest.update_positions(@camera) if chest.respond_to?(:update_positions)
      @map.objects << chest
      
      # Удаляем алтарь
      @active_altar.remove if @active_altar.respond_to?(:remove)
      @map.objects.delete(@active_altar) if @map.objects.include?(@active_altar)
      
      @active_altar = nil
    end
  end
  
  def create_bomb_explosion(x, y, radius)
    # Создаем визуальный эффект взрыва
    explosion = {
      x: x,
      y: y,
      radius: 0,
      max_radius: radius,
      time: 0.0,
      duration: 0.5, # 0.5 секунды
      shapes: []
    }
    
    # Создаем несколько концентрических кругов для эффекта взрыва
    5.times do |i|
      explosion[:shapes] << Circle.new(
        x: 0, y: 0,
        radius: 0,
        color: [255, 100 + i * 30, 0, 1.0], # От оранжевого к желтому
        z: 600
      )
    end
    
    @explosions << explosion
  end
  
  def update_explosions(delta_time)
    @explosions.each do |explosion|
      explosion[:time] += delta_time
      progress = [explosion[:time] / explosion[:duration], 1.0].min
      
      # Радиус увеличивается от 0 до max_radius
      explosion[:radius] = explosion[:max_radius] * progress
      
      # Прозрачность уменьшается со временем
      opacity = 1.0 - progress
      
      # Обновляем визуальные элементы
      screen_x, screen_y = @camera.world_to_screen(explosion[:x], explosion[:y])
      
      # Обновляем концентрические круги
      explosion[:shapes].each_with_index do |circle, i|
        if i == 0
          # Внутренний круг - самый яркий
          circle_radius = explosion[:radius] * 0.4
          circle.color = [255, 255, 255, opacity * 1.0] # Белый
        elsif i <= 3
          # Средние круги
          circle_radius = explosion[:radius] * (0.5 + (i - 1) * 0.15)
          circle_opacity = opacity * (0.8 - (i - 1) * 0.15)
          if i == 1
            circle.color = [255, 200, 0, circle_opacity] # Желтый
          elsif i == 2
            circle.color = [255, 150, 0, circle_opacity] # Оранжевый
          else
            circle.color = [255, 100, 0, circle_opacity] # Красно-оранжевый
          end
        else
          # Внешний круг
          circle_radius = explosion[:radius] * 1.0
          circle.color = [255, 50, 0, opacity * 0.6] # Темно-красный
        end
        circle.radius = circle_radius
        circle.x = screen_x
        circle.y = screen_y
        circle.radius = circle_radius
      end
      
      # Обновляем частицы
      if explosion[:particles]
        explosion[:particles].each do |particle|
          particle[:time] += delta_time
          if particle[:time] < particle[:life]
            # Движение частицы
            particle[:x] += Math.cos(particle[:angle]) * particle[:speed] * delta_time
            particle[:y] += Math.sin(particle[:angle]) * particle[:speed] * delta_time
            
            # Обновляем позицию и прозрачность
            p_screen_x, p_screen_y = @camera.world_to_screen(particle[:x], particle[:y])
            particle[:shape].x = p_screen_x
            particle[:shape].y = p_screen_y
            particle[:shape].opacity = 1.0 - (particle[:time] / particle[:life])
          else
            # Удаляем частицу
            particle[:shape].remove
            explosion[:particles].delete(particle)
          end
        end
      end
    end
    
    # Удаляем завершенные взрывы
    @explosions.reject! do |explosion|
      if explosion[:time] >= explosion[:duration]
        explosion[:shapes].each(&:remove)
        if explosion[:particles]
          explosion[:particles].each { |p| p[:shape].remove }
        end
        true
      else
        false
      end
    end
  end
  
  def update_damage_effects(delta_time)
    @damage_effects.each do |effect|
      effect[:time] += delta_time
      progress = effect[:time] / effect[:duration]
      
      if progress >= 1.0
        # Удаляем эффект
        effect[:shapes].each(&:remove) if effect[:shapes]
        @damage_effects.delete(effect)
      else
        # Обновляем позиции и прозрачность
        screen_x, screen_y = @camera.world_to_screen(effect[:x], effect[:y])
        opacity = 1.0 - progress
        
        effect[:shapes].each do |shape|
          shape.x = screen_x + (shape.x - effect[:x]) * (1.0 + progress * 0.5)
          shape.y = screen_y + (shape.y - effect[:y]) * (1.0 + progress * 0.5)
          shape.opacity = opacity if shape.respond_to?(:opacity=)
        end
      end
    end
  end
  
  def create_damage_effect(x, y, damage_amount)
    # Создаем визуальный эффект урона (частицы крови, числа урона)
    effect = {
      x: x,
      y: y,
      time: 0.0,
      duration: 0.8,
      shapes: []
    }
    
    # Создаем несколько частиц крови
    8.times do |i|
      angle = (i * Math::PI * 2 / 8) + rand * 0.5
      distance = 10 + rand * 20
      particle_x = x + Math.cos(angle) * distance
      particle_y = y + Math.sin(angle) * distance
      
      screen_x, screen_y = @camera.world_to_screen(particle_x, particle_y)
      
      effect[:shapes] << Circle.new(
        x: screen_x,
        y: screen_y,
        radius: 2 + rand * 3,
        color: [200, 0, 0, 1.0],
        z: 603
      )
    end
    
    # Создаем текст урона (если нужно)
    # Можно добавить позже, если понадобится
    
    @damage_effects << effect
  end
  
  def check_final_boss_killed
    return unless @final_boss
    return if @final_boss.alive?
    return if @game_completed
    
    # Финальный босс убит - завершаем игру
    @game_completed = true
    # Рекорд сохранится автоматически в update
    # Игра завершится в следующем кадре
  end
  
  def save_high_score
    require 'json'
    
    high_score_file = 'high_score.json'
    records_file = 'records.json'
    
    current_score = @player.enemies_killed
    game_time = (Time.now.to_f - @game_start_time).to_i
    
    # Загружаем текущий рекорд
    best_score = 0
    best_record = nil
    if File.exist?(high_score_file)
      begin
        data = JSON.parse(File.read(high_score_file))
        best_score = data['enemies_killed'] || 0
        best_record = data
      rescue JSON::ParserError
        best_score = 0
      end
    end
    
    # Подготавливаем данные текущей игры
    current_record = {
      'enemies_killed' => current_score,
      'time_alive' => game_time,
      'level' => @player.level,
      'gold' => @player.gold || 0,
      'weapons_count' => @player.weapons.length,
      'passives_count' => @player.passives.length,
      'date' => Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      'completed' => @game_completed ? true : false
    }
    
    # Сохраняем новый рекорд, если он лучше
    is_new_record = current_score > best_score
    if is_new_record
      File.write(high_score_file, JSON.pretty_generate(current_record))
    end
    
    # Сохраняем в таблицу рекордов (топ 10)
    records = []
    if File.exist?(records_file)
      begin
        records = JSON.parse(File.read(records_file))
        records = [] unless records.is_a?(Array)
      rescue JSON::ParserError
        records = []
      end
    end
    
    # Добавляем текущий результат
    records << current_record
    
    # Сортируем по количеству убийств (по убыванию)
    records.sort_by! { |r| -(r['enemies_killed'] || 0) }
    
    # Оставляем только топ 10
    records = records.first(10)
    
    # Сохраняем таблицу рекордов
    File.write(records_file, JSON.pretty_generate(records))
    
    is_new_record
  end
  
  def self.load_high_score
    require 'json'
    
    high_score_file = 'high_score.json'
    return nil unless File.exist?(high_score_file)
    
    begin
      data = JSON.parse(File.read(high_score_file))
      {
        enemies_killed: data['enemies_killed'] || 0,
        time_alive: data['time_alive'] || 0,
        level: data['level'] || 0,
        date: data['date'] || 'N/A'
      }
    rescue JSON::ParserError
      nil
    end
  end
  
  def self.load_records(limit = 10)
    require 'json'
    
    records_file = 'records.json'
    return [] unless File.exist?(records_file)
    
    begin
      records = JSON.parse(File.read(records_file))
      records = [] unless records.is_a?(Array)
      records.first(limit)
    rescue JSON::ParserError
      []
    end
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
    
    # Вычисляем время игры в секундах
    game_time = (current_time - @game_start_time).to_i
    
    # Получаем доступные типы врагов для данного времени
    available_types = EnemyTypes.available_types(game_time)
    return if available_types.empty?
    
    # Выбираем случайный тип (с учетом весов - базовые мобы чаще)
    enemy_type_key = weighted_random_enemy_type(available_types, game_time)
    return unless enemy_type_key
    
    # Проверяем, что не слишком близко к игроку
    distance_to_player = Math.sqrt((x - @player.x)**2 + (y - @player.y)**2)
    return if distance_to_player <= 100

    enemy = Enemy.new(x, y, enemy_type_key, @difficulty_multiplier)
    enemy.ensure_shapes
    @enemies << enemy
    @last_spawn_time = current_time
  end
  
  def weighted_random_enemy_type(available_types, game_time)
    # Базовые мобы имеют больший вес
    weights = {}
    available_types.each do |type_key, type_data|
      case type_key
      when :skeleton, :bat
        weights[type_key] = 50 # Базовые мобы - чаще
      when :ghost, :zombie
        weights[type_key] = 30 # Средние мобы
      when :knight, :mage
        weights[type_key] = 20 # Сильные мобы
      else
        weights[type_key] = 10
      end
    end
    
    # Выбираем случайный тип с учетом весов
    total_weight = weights.values.sum
    return nil if total_weight == 0
    
    random = rand(total_weight)
    current = 0
    weights.each do |type_key, weight|
      current += weight
      return type_key if random < current
    end
    
    weights.keys.first
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
      # Рисуем фон карты (траву/землю) только если карта существует
      if @map
        draw_map_background
        
        # Рисуем карту (только видимые объекты) - обновляем каждый кадр для плавности
        visible_objects = @map.get_visible_objects(@camera)
        visible_objects.each do |obj|
          obj.update_positions(@camera, @delta_time || 0.0)
        end
      end
      
      # Вычисляем границы видимой области один раз для всех проверок (оптимизация)
      min_x, min_y = @camera.screen_to_world(0, 0)
      max_x, max_y = @camera.screen_to_world(@window_width, @window_height)
      margin = 200 # Запас для объектов, которые частично видны
      min_x -= margin
      min_y -= margin
      max_x += margin
      max_y += margin
      
      # Рисуем опыт-гемы (только видимые) - оптимизация
      @experience_gems.each_with_index do |gem, index|
        next if gem[:collected]
        # Быстрая проверка видимости
        if gem[:x] >= min_x && gem[:x] <= max_x && gem[:y] >= min_y && gem[:y] <= max_y
          update_experience_gem(gem, index)
        end
      end

      # Обновляем позиции проектилей с учетом камеры (только видимые) - оптимизация
      
      @projectiles.each do |projectile|
        next unless projectile.active
        next unless projectile.respond_to?(:update_positions)
        
        # Быстрая проверка видимости
        if projectile.x >= min_x && projectile.x <= max_x && projectile.y >= min_y && projectile.y <= max_y
          projectile.update_positions(@camera)
        end
      end
      
      # Отладочная информация (можно убрать позже)
      # puts "Projectiles: #{@projectiles.length}, Active: #{@projectiles.count(&:active)}"
      
      # Рисуем игрока (с учетом камеры)
      @player.draw(@camera) if @player.alive?

      # Рисуем врагов (с учетом камеры) - только живых и видимых
      @enemies.each do |enemy|
        next unless enemy.alive?
        next unless enemy.sprite # Пропускаем, если спрайт не создан
        
        # Проверяем, что враг виден на экране
        screen_x, screen_y = @camera.world_to_screen(enemy.x, enemy.y)
        if screen_x >= -300 && screen_x <= @window_width + 300 && 
           screen_y >= -300 && screen_y <= @window_height + 300
          # Враг виден - рисуем его
          enemy.draw(@camera)
        else
          # Если враг вне экрана и далеко от игрока, помечаем для удаления
          distance_to_player = Math.sqrt((enemy.x - @player.x)**2 + (enemy.y - @player.y)**2)
          if distance_to_player > 600
            # Враг слишком далеко - помечаем для удаления
            enemy.instance_variable_set(:@health, 0)
            enemy.instance_variable_set(:@just_died, true)
          else
            # Если враг вне экрана, скрываем все его фигуры (перемещаем далеко)
            if enemy.sprite && enemy.sprite.respond_to?(:shapes) && enemy.sprite.shapes
              enemy.sprite.shapes.values.each do |shape|
                if shape.is_a?(Array)
                  shape.each do |s|
                    s.x = -100000 if s.respond_to?(:x=)
                    s.y = -100000 if s.respond_to?(:y=)
                  end
                else
                  shape.x = -100000 if shape.respond_to?(:x=)
                  shape.y = -100000 if shape.respond_to?(:y=)
                  # Для треугольников обновляем все координаты
                  if shape.respond_to?(:x1=)
                    shape.x1 = -100000
                    shape.y1 = -100000
                    shape.x2 = -100000
                    shape.y2 = -100000
                    shape.x3 = -100000
                    shape.y3 = -100000
                  end
                end
              end
            end
          end
        end
      end
      
      # Дополнительная очистка: удаляем мертвых и зависших врагов
      @enemies.reject! do |enemy|
        should_remove = false
        
        # Проверяем, мертв ли враг
        if !enemy.alive? || enemy.health <= 0
          should_remove = true
        end
        
        # Проверяем, завис ли враг (не двигается долгое время и далеко от игрока)
        if enemy.alive? && enemy.respond_to?(:@last_x) && enemy.respond_to?(:@last_y)
          last_x = enemy.instance_variable_get(:@last_x)
          last_y = enemy.instance_variable_get(:@last_y)
          # Проверяем, двигается ли враг
          not_moving = (enemy.x == last_x && enemy.y == last_y)
          
          # Если враг не двигается и далеко от игрока, возможно он завис
          distance_to_player = Math.sqrt((enemy.x - @player.x)**2 + (enemy.y - @player.y)**2)
          # Также проверяем, что враг не на экране (вне видимости камеры)
          screen_x, screen_y = @camera.world_to_screen(enemy.x, enemy.y)
          off_screen = screen_x < -500 || screen_x > @window_width + 500 || 
                       screen_y < -500 || screen_y > @window_height + 500
          
          if (not_moving && distance_to_player > 300) || (off_screen && distance_to_player > 500)
            # Помечаем как зависшего и удаляем
            should_remove = true
          end
        end
        
        if should_remove
          # Удаляем все фигуры врага
          if enemy.sprite
            if enemy.sprite.respond_to?(:shapes) && enemy.sprite.shapes
              enemy.sprite.shapes.values.each do |shape|
                if shape.is_a?(Array)
                  shape.each do |s|
                    s.x = -100000 if s.respond_to?(:x=)
                    s.y = -100000 if s.respond_to?(:y=)
                    s.remove if s.respond_to?(:remove)
                  end
                else
                  shape.x = -100000 if shape.respond_to?(:x=)
                  shape.y = -100000 if shape.respond_to?(:y=)
                  shape.remove if shape.respond_to?(:remove)
                end
              end
            end
            if enemy.sprite.respond_to?(:remove)
              enemy.sprite.remove
            end
            enemy.sprite = nil
          end
          enemy.remove if enemy.respond_to?(:remove)
          true  # Удаляем из массива
        else
          false  # Оставляем в массиве
        end
      end
      
      # Рисуем дропы усилений (только видимые) - оптимизация
      @pickups.each do |pickup|
        next if pickup.collected
        # Быстрая проверка видимости
        if pickup.x >= min_x && pickup.x <= max_x && pickup.y >= min_y && pickup.y <= max_y
          pickup.update_positions(@camera)
        end
      end
      
      # Рисуем эффект мигания экрана при получении урона
      if @screen_flash > 0
        flash_opacity = @screen_flash * 0.3
        unless @ui_shapes[:screen_flash]
          @ui_shapes[:screen_flash] = Rectangle.new(
            x: 0, y: 0,
            width: @window_width,
            height: @window_height,
            color: [255, 0, 0, flash_opacity],
            z: 10000
          )
        else
          @ui_shapes[:screen_flash].color = [255, 0, 0, flash_opacity]
        end
      elsif @ui_shapes[:screen_flash]
        @ui_shapes[:screen_flash].remove
        @ui_shapes[:screen_flash] = nil
      end

      # Рисуем информацию
      draw_ui
      
      # Рисуем миникарту
      draw_minimap
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
    @map_background_tiles ||= {}
    @map_background_tiles.each do |key, tile|
      next unless tile # Пропускаем nil значения
      tile_x, tile_y = key.split(',').map(&:to_f)
      if tile_x < min_x - tile_size || tile_x > max_x + tile_size ||
         tile_y < min_y - tile_size || tile_y > max_y + tile_size
        tile.remove if tile.respond_to?(:remove)
        @map_background_tiles.delete(key)
      end
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
    # Не рисуем UI, если показывается экран улучшений
    return if @showing_upgrades
    
    y_offset = 10
    
    # Рисуем индикаторы здоровья боссов
    draw_boss_health_bars
    
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
    y_offset += 30

    # Отображаем характеристики
    draw_stats_panel(y_offset)

    # Сообщение о смерти
    if !@player.alive?
      draw_game_over_screen
    end
  end
  
  def draw_stats_panel(start_y)
    y_offset = start_y
    x_offset = 10
    
    # Заголовок
    stats_title = "Характеристики:"
    if @ui_texts[:stats_title]
      @ui_texts[:stats_title].text = stats_title
      @ui_texts[:stats_title].x = x_offset
      @ui_texts[:stats_title].y = y_offset
    else
      @ui_texts[:stats_title] = Text.new(
        stats_title,
        x: x_offset,
        y: y_offset,
        size: 16,
        color: '#FFFF00',
        z: 1000
      )
    end
    y_offset += 20
    
    # Базовые характеристики
    stats = [
      ["[H] Здоровье", "#{@player.health.to_i}/#{@player.max_health}"],
      ["[S] Скорость", @player.speed.to_s],
      ["[D] Броня", "#{(@player.armor * 100).round(1)}%"],
      ["[M] Радиус подбора", @player.experience_magnet_range.to_s],
      ["[L] Удача", "#{(@player.luck * 100).round(1)}%"],
      ["[X] Рост опыта", "#{(@player.growth * 100).round(1)}%"],
      ["[V] Вампиризм", "#{(@player.vampirism * 100).round(1)}%"],
      ["[D] Шанс дропа", "#{(@player.drop_chance * 100).round(1)}%"]
    ]
    
    stats.each_with_index do |(name, value), index|
      stat_text = "#{name}: #{value}"
      key = "stat_#{index}".to_sym
      if @ui_texts[key]
        @ui_texts[key].text = stat_text
        @ui_texts[key].x = x_offset + 10
        @ui_texts[key].y = y_offset
      else
        @ui_texts[key] = Text.new(
          stat_text,
          x: x_offset + 10,
          y: y_offset,
          size: 14,
          color: '#CCCCCC',
          z: 1000
        )
      end
      y_offset += 18
    end
    
    # Оружие
    y_offset += 5
    weapons_title = "Оружие:"
    if @ui_texts[:weapons_title]
      @ui_texts[:weapons_title].text = weapons_title
      @ui_texts[:weapons_title].x = x_offset
      @ui_texts[:weapons_title].y = y_offset
    else
      @ui_texts[:weapons_title] = Text.new(
        weapons_title,
        x: x_offset,
        y: y_offset,
        size: 16,
        color: '#FFFF00',
        z: 1000
      )
    end
    y_offset += 20
    
    # Удаляем старые тексты оружий, которых больше нет
    (@player.weapons.length..20).each do |i|
      key = "weapon_#{i}".to_sym
      if @ui_texts[key]
        @ui_texts[key].remove
        @ui_texts.delete(key)
      end
    end
    
    @player.weapons.each_with_index do |weapon, index|
      weapon_text = "#{weapon.icon} #{weapon.name} (Ур. #{weapon.level}/#{weapon.max_level})"
      key = "weapon_#{index}".to_sym
      if @ui_texts[key]
        @ui_texts[key].text = weapon_text
        @ui_texts[key].x = x_offset + 10
        @ui_texts[key].y = y_offset
      else
        @ui_texts[key] = Text.new(
          weapon_text,
          x: x_offset + 10,
          y: y_offset,
          size: 14,
          color: '#CCCCCC',
          z: 1000
        )
      end
      y_offset += 18
    end
    
    # Уникальные пассивки для оружий
    unique_passives = @player.passives.select { |p| [:weapon_amount, :weapon_area, :weapon_range, :cooldown_reduction, :duration].include?(p.type) }
    if unique_passives.any?
      y_offset += 5
      passives_title = "Улучшения оружия:"
      if @ui_texts[:passives_title]
        @ui_texts[:passives_title].text = passives_title
        @ui_texts[:passives_title].x = x_offset
        @ui_texts[:passives_title].y = y_offset
      else
        @ui_texts[:passives_title] = Text.new(
          passives_title,
          x: x_offset,
          y: y_offset,
          size: 16,
          color: '#FFFF00',
          z: 1000
        )
      end
      y_offset += 20
      
      # Удаляем старые тексты пассивок, которых больше нет
      (unique_passives.length..20).each do |i|
        key = "unique_passive_#{i}".to_sym
        if @ui_texts[key]
          @ui_texts[key].remove
          @ui_texts.delete(key)
        end
      end
      
      unique_passives.each_with_index do |passive, index|
        passive_text = "#{passive.icon} #{passive.name} (Ур. #{passive.level}/#{passive.max_level})"
        key = "unique_passive_#{index}".to_sym
        if @ui_texts[key]
          @ui_texts[key].text = passive_text
          @ui_texts[key].x = x_offset + 10
          @ui_texts[key].y = y_offset
        else
          @ui_texts[key] = Text.new(
            passive_text,
            x: x_offset + 10,
            y: y_offset,
            size: 14,
            color: '#CCCCCC',
            z: 1000
          )
        end
        y_offset += 18
      end
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
      )
      @ui_texts[:game_over].x = @window_width / 2 - @ui_texts[:game_over].width / 2

      stats = "Уровень: #{@player.level} | Убито: #{@player.enemies_killed} | Время: #{minutes}м #{seconds}с"
      @ui_texts[:game_over_stats] = Text.new(
        stats,
        x: @window_width / 2,
        y: @window_height / 2 - 20,
        size: 24,
        color: 'white',
      )
      @ui_texts[:game_over_stats].x = @window_width / 2 - @ui_texts[:game_over_stats].width / 2
      
      # Показываем информацию о рекорде
      high_score = Game.load_high_score
      if high_score && high_score[:enemies_killed] > 0
        if @player.enemies_killed >= high_score[:enemies_killed]
          record_text = "НОВЫЙ РЕКОРД! Убито: #{@player.enemies_killed}"
          record_color = '#FFD700'
        else
          record_text = "Лучший результат: #{high_score[:enemies_killed]} убийств"
          record_color = '#AAAAAA'
        end
        
        @ui_texts[:game_over_record] = Text.new(
          record_text,
          x: @window_width / 2,
          y: @window_height / 2 + 20,
          size: 20,
          color: record_color,
        )
        @ui_texts[:game_over_record].x = @window_width / 2 - @ui_texts[:game_over_record].width / 2
      end

      @ui_texts[:game_over_hint] = Text.new(
        "Нажмите ESC для возврата в меню",
        x: @window_width / 2,
        y: @window_height / 2 + 60,
        size: 20,
        color: 'gray',
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
    # ВАЖНО: Обновляем позиции всех врагов после закрытия экрана улучшений
    # Это предотвращает зависание монстров, которые могли упираться в препятствия
    @enemies.each do |enemy|
      next unless enemy.alive?
      # Принудительно обновляем позиции врагов, чтобы они не зависали
      if enemy.respond_to?(:update)
        # Обновляем врага с минимальным delta_time, чтобы он не "прыгнул"
        enemy.update(0.016, @player, @map) # ~60 FPS
      end
      # Обновляем спрайт врага (особенно важно для боссов)
      # Позиция будет обновлена в draw, здесь только обновляем анимацию
      if enemy.sprite
        # Обновляем анимацию спрайта
        enemy.sprite.update(0.016, enemy.instance_variable_get(:@is_moving) || false, 
                           enemy.instance_variable_get(:@is_attacking) || false, 
                           enemy.instance_variable_get(:@took_damage) || false) if enemy.sprite.respond_to?(:update)
      end
    end
  end
  
  def draw_boss_health_bars
    # Рисуем индикаторы здоровья для всех боссов на экране
    @enemies.each do |enemy|
      next unless enemy.boss && enemy.alive?
      
      # Проверяем, что босс виден на экране
      screen_x, screen_y = @camera.world_to_screen(enemy.x, enemy.y)
      if screen_x >= -100 && screen_x <= @window_width + 100 && 
         screen_y >= -100 && screen_y <= @window_height + 100
        
        # Рисуем большую полоску здоровья над боссом
        bar_width = 200
        bar_height = 10
        bar_x = screen_x - bar_width / 2
        bar_y = screen_y - enemy.size - 25
        
        health_percent = enemy.health.to_f / enemy.max_health
        
        # Фон полоски
        bg_key = "boss_hp_bg_#{enemy.object_id}".to_sym
        unless @ui_shapes[bg_key]
          @ui_shapes[bg_key] = Rectangle.new(
            x: bar_x, y: bar_y,
            width: bar_width, height: bar_height,
            color: '#333333',
            z: 1001
          )
        else
          @ui_shapes[bg_key].x = bar_x
          @ui_shapes[bg_key].y = bar_y
        end
        
        # Полоска здоровья
        hp_width = [bar_width * health_percent, 0].max.to_i
        hp_key = "boss_hp_#{enemy.object_id}".to_sym
        if @ui_shapes[hp_key]
          @ui_shapes[hp_key].width = hp_width
          @ui_shapes[hp_key].x = bar_x
          @ui_shapes[hp_key].y = bar_y
          # Меняем цвет в зависимости от здоровья
          if health_percent > 0.6
            @ui_shapes[hp_key].color = '#00FF00'
          elsif health_percent > 0.3
            @ui_shapes[hp_key].color = '#FFFF00'
          else
            @ui_shapes[hp_key].color = '#FF0000'
          end
        else
          @ui_shapes[hp_key] = Rectangle.new(
            x: bar_x, y: bar_y,
            width: hp_width, height: bar_height,
            color: health_percent > 0.6 ? '#00FF00' : (health_percent > 0.3 ? '#FFFF00' : '#FF0000'),
            z: 1002
          )
        end
        
        # Имя босса
        name_key = "boss_name_#{enemy.object_id}".to_sym
        if @ui_texts[name_key]
          @ui_texts[name_key].x = screen_x
          @ui_texts[name_key].y = bar_y - 20
          @ui_texts[name_key].text = enemy.name
        else
          @ui_texts[name_key] = Text.new(
            enemy.name,
            x: screen_x,
            y: bar_y - 20,
            size: 16,
            color: '#FF0000',
            z: 1003
          )
        end
        @ui_texts[name_key].x = screen_x - @ui_texts[name_key].width / 2
      else
        # Удаляем UI элементы, если босс вне экрана
        ["boss_hp_bg_#{enemy.object_id}", "boss_hp_#{enemy.object_id}", "boss_name_#{enemy.object_id}"].each do |key|
          sym_key = key.to_sym
          @ui_shapes[sym_key]&.remove
          @ui_shapes.delete(sym_key)
          @ui_texts[sym_key]&.remove
          @ui_texts.delete(sym_key)
        end
      end
    end
    
    # Удаляем UI элементы для мертвых боссов
    dead_bosses = @enemies.select { |e| e.boss && !e.alive? }
    dead_bosses.each do |dead_boss|
      ["boss_hp_bg_#{dead_boss.object_id}", "boss_hp_#{dead_boss.object_id}", "boss_name_#{dead_boss.object_id}"].each do |key|
        sym_key = key.to_sym
        @ui_shapes[sym_key]&.remove
        @ui_shapes.delete(sym_key)
        @ui_texts[sym_key]&.remove
        @ui_texts.delete(sym_key)
      end
    end
  end
  
  def draw_minimap
    return unless @map && @player
    return if @showing_upgrades
    
    # Обновляем миникарту реже для оптимизации
    @minimap_update_counter ||= 0
    @minimap_update_counter += 1
    update_minimap_objects = (@minimap_update_counter % 5 == 0) # Обновляем объекты каждые 5 кадров
    
    # Размеры миникарты - компактная и читаемая
    minimap_size = 180
    minimap_x = @window_width - minimap_size - 10
    minimap_y = 10
    padding = 4
    
    # Простой темный фон с одной рамкой
    unless @minimap_shapes[:bg]
      @minimap_shapes[:bg] = Rectangle.new(
        x: minimap_x - padding,
        y: minimap_y - padding,
        width: minimap_size + padding * 2,
        height: minimap_size + padding * 2,
        color: [15, 15, 20, 0.98],  # Очень темный фон
        z: 1999
      )
      @minimap_shapes[:border] = Rectangle.new(
        x: minimap_x - padding - 1,
        y: minimap_y - padding - 1,
        width: minimap_size + (padding + 1) * 2,
        height: minimap_size + (padding + 1) * 2,
        color: [150, 150, 150, 1.0],  # Светлая рамка для контраста
        z: 1998
      )
    end
    
    # Масштаб для преобразования мировых координат в координаты миникарты
    scale_x = minimap_size.to_f / @map.width
    scale_y = minimap_size.to_f / @map.height
    
    # Рисуем игрока на миникарте (всегда обновляем)
    player_minimap_x = minimap_x + (@player.x + @map.width / 2) * scale_x
    player_minimap_y = minimap_y + (@player.y + @map.height / 2) * scale_y
    @minimap_shapes[:player] ||= Circle.new(
      x: player_minimap_x,
      y: player_minimap_y,
      radius: 5,
      color: '#00FF00',  # Яркий зеленый для игрока
      z: 2002
    )
    @minimap_shapes[:player].x = player_minimap_x
    @minimap_shapes[:player].y = player_minimap_y
    
    # Обновляем точки объектов только периодически
    if update_minimap_objects
      # Удаляем старые точки
      if @minimap_shapes[:points]
        @minimap_shapes[:points].each(&:remove)
        @minimap_shapes[:points].clear
      else
        @minimap_shapes[:points] = []
      end
      
      # Используем кэшированный список интерактивных объектов
      # Показываем только активные (не открытые/разрушенные) объекты
      @map.interactive_objects.each do |obj|
        next if (obj.destroyed && obj.type != :free_chest) || (obj.opened && obj.type != :barrel)
        
        # Простые контрастные цвета на темном фоне
        color = case obj.type
        when :chest, :free_chest
          '#FFD700'  # Золотой - хорошо видно на темном
        when :barrel
          '#CD853F'  # Коричневый - хорошо видно
        when :altar
          '#9370DB'  # Фиолетовый - хорошо видно
        when :portal
          '#FF4444'  # Красный - хорошо видно
        else
          next
        end
        
        minimap_obj_x = minimap_x + (obj.x + @map.width / 2) * scale_x
        minimap_obj_y = minimap_y + (obj.y + @map.height / 2) * scale_y
        
        # Создаем точку на миникарте - больше размер для читаемости
        point = Circle.new(
          x: minimap_obj_x,
          y: minimap_obj_y,
          radius: 3,
          color: color,
          z: 2001
        )
        @minimap_shapes[:points] << point
      end
    end
  end
end

