require_relative 'ui_enhancer'

class UpgradeScreen
  attr_accessor :selected_index, :available_upgrades, :shapes, :texts

  def initialize(window_width, window_height, upgrade_system, audio_manager = nil)
    @window_width = window_width
    @window_height = window_height
    @upgrade_system = upgrade_system
    @audio_manager = audio_manager
    @selected_index = 0
    @available_upgrades = {}
    @vs_upgrades = []
    @shapes = {}
    @texts = {}
    @title_text = nil
    @using_vs_system = false
    @window_shapes = {}
    @card_shapes = {}
    initialize_shapes
  end

  def show_vs_upgrades(upgrades, vs_system)
    @vs_upgrades = upgrades
    @vs_system = vs_system
    @selected_index = 0
    @using_vs_system = true
    create_window_background
    create_title_and_hint
    update_vs_upgrade_display
  end

  def create_window_background
    # Удаляем старые формы окна
    @window_shapes.values.each(&:remove) if @window_shapes
    @card_shapes.values.each { |cards| cards.values.each(&:remove) } if @card_shapes
    
    @window_shapes = UIEnhancer.create_upgrade_window(@window_width, @window_height)
    @card_shapes = {}
  end

  def show_upgrades(upgrades)
    @available_upgrades = upgrades
    @selected_index = 0
    create_title_and_hint
    update_upgrade_display
  end

  def hide
    @available_upgrades = {}
    @vs_upgrades = []
    @using_vs_system = false
    
    # Удаляем все тексты
    @title_text&.remove
    @hint_text&.remove
    @title_text = nil
    @hint_text = nil
    
    # Удаляем все тексты из @texts
    @texts.each do |key, text|
      text.remove if text.respond_to?(:remove)
    end
    @texts.clear
    
    # Удаляем все формы окна
    if @window_shapes
      @window_shapes.each do |key, shape|
        shape.remove if shape.respond_to?(:remove)
      end
      @window_shapes.clear
    end
    
    # Удаляем все карточки
    if @card_shapes
      @card_shapes.each do |index, cards|
        if cards.is_a?(Hash)
          cards.each do |key, shape|
            shape.remove if shape.respond_to?(:remove)
          end
        end
      end
      @card_shapes.clear
    end
  end

  def available_upgrades
    @using_vs_system ? @vs_upgrades : @available_upgrades
  end

  def initialize_shapes
    @title_text = nil
    @hint_text = nil
  end

  def create_title_and_hint
    return if @title_text && @hint_text

    # Заголовок в классическом стиле - черный для читаемости
    @title_text = Text.new(
      'LEVEL UP!',
      x: @window_width / 2,
      y: 80,
      size: 64,
      color: '#000000',
      font: nil,
      z: 2010
    )
    @title_text.x = @window_width / 2 - @title_text.width / 2

    # Подсказка - черный для читаемости
    @hint_text = Text.new(
      '↑/↓ Выбор | Enter Подтвердить',
      x: @window_width / 2,
      y: @window_height - 40,
      size: 20,
      color: '#000000',
      font: nil,
      z: 2010
    )
    @hint_text.x = @window_width / 2 - @hint_text.width / 2
  end

  def update_upgrade_display
    return if @available_upgrades.empty?

    # Удаляем старые тексты
    @texts.select { |k, _| k.to_s.start_with?('upgrade_') }.each do |_, text|
      text.remove
    end
    @texts.reject! { |k, _| k.to_s.start_with?('upgrade_') }

    # Создаем новые тексты для улучшений
    @available_upgrades.each_with_index do |(key, data), index|
      y_pos = 200 + index * 120
      level = @upgrade_system.get_upgrade_level(key)
      max_level = UpgradeSystem::UPGRADES[key][:max_level]
      
      # Название улучшения - черный для читаемости
      name_text = Text.new(
        "#{data[:icon]} #{data[:name]}",
        x: @window_width / 2,
        y: y_pos,
        size: 40,
        color: '#000000',
        font: nil,
        z: 2010
      )
      name_text.x = @window_width / 2 - name_text.width / 2
      @texts["upgrade_#{index}_name"] = name_text

      # Уровень - черный для читаемости
      level_text = Text.new(
        "Уровень: #{level}/#{max_level}",
        x: @window_width / 2,
        y: y_pos + 45,
        size: 24,
        color: '#000000',
        font: nil,
        z: 2010
      )
      level_text.x = @window_width / 2 - level_text.width / 2
      @texts["upgrade_#{index}_level"] = level_text

      # Описание - черный для читаемости
      desc_text = Text.new(
        data[:description],
        x: @window_width / 2,
        y: y_pos + 75,
        size: 20,
        color: '#000000',
        font: nil,
        z: 2010
      )
      desc_text.x = @window_width / 2 - desc_text.width / 2
      @texts["upgrade_#{index}_desc"] = desc_text
    end
  end

  def update
    if @using_vs_system
      update_vs_upgrade_display
    else
      update_upgrade_display
    end
  end

  def draw
    # Все рисуется через тексты
  end

  def handle_key_down(key)
    case key
    when 'up', 'w'
      if @using_vs_system
        @selected_index = (@selected_index - 1) % @vs_upgrades.length
      else
        @selected_index = (@selected_index - 1) % @available_upgrades.length
      end
    when 'down', 's'
      if @using_vs_system
        @selected_index = (@selected_index + 1) % @vs_upgrades.length
      else
        @selected_index = (@selected_index + 1) % @available_upgrades.length
      end
    when 'return', 'enter'
      return select_upgrade
    end
    nil
  end

  def select_upgrade
    # Звук выбора улучшения
    @audio_manager&.play_sound(:upgrade_select)
    
    if @using_vs_system
      return nil if @vs_upgrades.empty?
      upgrade_data = @vs_upgrades[@selected_index]
      @vs_system.apply_upgrade(upgrade_data)
      :upgrade_selected
    else
      return nil if @available_upgrades.empty?
      upgrade_key = @available_upgrades.keys[@selected_index]
      @upgrade_system.upgrade(upgrade_key)
      :upgrade_selected
    end
  end

  def handle_mouse_click(x, y)
    return nil unless @using_vs_system || !@available_upgrades.empty?
    
    upgrades = @using_vs_system ? @vs_upgrades : @available_upgrades.keys
    upgrades.each_with_index do |upgrade, index|
      y_pos = 200 + index * 120
      if y >= y_pos && y <= y_pos + 100
        @selected_index = index
        return select_upgrade
      end
    end
    nil
  end

  def update_vs_upgrade_display
    return if @vs_upgrades.empty?

    # Удаляем старые тексты и карточки
    @texts.select { |k, _| k.to_s.start_with?('upgrade_') }.each do |_, text|
      text.remove
    end
    @texts.reject! { |k, _| k.to_s.start_with?('upgrade_') }
    
    @card_shapes.values.each do |cards|
      cards.values.each(&:remove)
    end
    @card_shapes.clear

    # Создаем карточки и тексты для улучшений в классическом стиле
    @vs_upgrades.each_with_index do |upgrade_data, index|
      y_pos = 200 + index * 140
      level = upgrade_data[:level] || 0
      max_level = upgrade_data[:max_level] || 8
      selected = index == @selected_index
      
      # Создаем карточку в классическом стиле
      @card_shapes[index] = UIEnhancer.create_classic_upgrade_card(@window_width, @window_height, y_pos, selected)
      
      # Большая иконка слева - черный для читаемости
      icon_size = selected ? 60 : 50
      icon = upgrade_data[:icon] || '[W]'
      icon_text = Text.new(
        icon,
        x: @window_width / 2 - 300,
        y: y_pos + 30,
        size: icon_size,
        color: '#000000',
        font: nil,
        z: 2010
      )
      @texts["upgrade_#{index}_icon"] = icon_text
      
      # Название улучшения - черный для читаемости
      name = upgrade_data[:name] || 'Улучшение'
      name_text = Text.new(
        name,
        x: @window_width / 2 - 200,
        y: y_pos + 20,
        size: 38,
        color: '#000000',
        font: nil,
        z: 2010
      )
      # Ограничиваем ширину названия
      if name_text.width > 300
        name_text.size = 28
        name_text.x = @window_width / 2 - 200
      end
      @texts["upgrade_#{index}_name"] = name_text

      # Тип улучшения - черный для читаемости
      type_text = Text.new(
        upgrade_data[:type] == :weapon_upgrade || upgrade_data[:type] == :new_weapon ? 'Оружие' : 'Пассив',
        x: @window_width / 2 - 200,
        y: y_pos + 60,
        size: 20,
        color: '#000000',
        font: nil,
        z: 2010
      )
      @texts["upgrade_#{index}_type"] = type_text

      # Рарность (если есть)
      if upgrade_data[:rarity]
        rarity_name = @vs_system.get_rarity_name(upgrade_data[:rarity])
        rarity_color = @vs_system.get_rarity_color(upgrade_data[:rarity])
        rarity_text = Text.new(
          rarity_name,
          x: @window_width / 2 - 200,
          y: y_pos + 85,
          size: 20,
          color: rarity_color,
          font: nil,
          z: 2010
        )
        @texts["upgrade_#{index}_rarity"] = rarity_text
      end
      
      # Уровень - черный для читаемости
      if level > 0
        level_text = Text.new(
          "Уровень: #{level}/#{max_level}",
          x: @window_width / 2 - 200,
          y: y_pos + 110,
          size: 18,
          color: '#000000',
          font: nil,
          z: 2010
        )
        @texts["upgrade_#{index}_level"] = level_text
      end

      # Описание справа (удаляем старые описания)
      @texts.select { |k, _| k.to_s.start_with?("upgrade_#{index}_desc") }.each do |_, text|
        text.remove
      end
      @texts.reject! { |k, _| k.to_s.start_with?("upgrade_#{index}_desc") }
      
      desc = get_upgrade_description(upgrade_data)
      max_width = 250
      desc_x = @window_width / 2 + 100
      desc_y = y_pos + 30
      
      # Перенос строки если описание длинное
      words = desc.split(' ')
      lines = []
      current_line = ''
      words.each do |word|
        test_line = current_line.empty? ? word : "#{current_line} #{word}"
        test_text = Text.new(test_line, size: 18)
        if test_text.width > max_width
          lines << current_line unless current_line.empty?
          current_line = word
        else
          current_line = test_line
        end
      end
      lines << current_line unless current_line.empty?
      
      # Ограничиваем количество строк, чтобы не выходить за рамки карточки
      max_lines = 4
      lines = lines.first(max_lines)
      
      lines.each_with_index do |line, line_idx|
        line_text = Text.new(
          line,
          x: desc_x,
          y: desc_y + line_idx * 25,
          size: 18,
          color: '#000000',  # Черный для читаемости
          font: nil,
          z: 2010
        )
        # Ограничиваем позицию, чтобы не выходить за правую границу
        if line_text.x + line_text.width > @window_width - 20
          line_text.x = @window_width - line_text.width - 20
        end
        @texts["upgrade_#{index}_desc_#{line_idx}"] = line_text
      end
    end
  end

  def get_upgrade_description(upgrade_data)
    rarity_multiplier = upgrade_data[:rarity_multiplier] || 1.0
    
    case upgrade_data[:type]
    when :weapon_upgrade
      weapon = upgrade_data[:weapon]
      if weapon
        # Текущие значения
        current_damage = weapon.damage.round(1)
        current_range = weapon.range.round(0)
        current_cooldown = weapon.cooldown.round(2)
        
        # Симулируем улучшение для получения новых значений
        # Создаем временную копию оружия для расчета
        temp_level = weapon.level
        levels_to_add = case rarity_multiplier
        when 1.0
          1
        when 1.2
          1
        when 1.5
          2
        when 2.0
          2
        else
          1
        end
        
        # Рассчитываем новые значения вручную (на основе логики из recalculate_with_level_bonuses)
        new_level = [temp_level + levels_to_add, weapon.max_level].min
        level_diff = new_level - temp_level
        
        if level_diff > 0
          # Урон: +0.5% за уровень
          damage_bonus = 1.0 + (level_diff * 0.005)
          new_damage = (weapon.instance_variable_get(:@base_damage) * (1.0 + (new_level * 0.005))).round(1)
          
          # Кулдаун: -0.3% за уровень
          base_cooldown = weapon.instance_variable_get(:@base_cooldown)
          cooldown_reduction = new_level * 0.003
          new_cooldown = [base_cooldown * (1.0 - cooldown_reduction), base_cooldown * 0.7].max.round(2)
          
          # Дальность: +0.5% за уровень (максимум +5%)
          base_range = weapon.instance_variable_get(:@base_range)
          range_bonus = 1.0 + (new_level * 0.005)
          new_range = (base_range * [range_bonus, 1.05].min).round(0)
          
          "Урон: #{current_damage} → #{new_damage}\nДальность: #{current_range} → #{new_range}\nКулдаун: #{current_cooldown}с → #{new_cooldown}с"
        else
          "Урон: #{current_damage} | Дальность: #{current_range} | Кулдаун: #{current_cooldown}с"
        end
      else
        "Улучшение оружия"
      end
    when :passive_upgrade, :new_passive
      passive = upgrade_data[:passive]
      if passive
        bonus_per_level = passive.instance_variable_get(:@bonus_per_level)
        
        # Текущий бонус (без рарности для существующих пассивок)
        if passive.respond_to?(:get_bonus_without_rarity)
          current_bonus = passive.get_bonus_without_rarity
        else
          current_bonus = passive.level * bonus_per_level
        end
        
        # Новый бонус с учетом рарности
        new_level = passive.level + 1
        new_bonus = new_level * bonus_per_level * rarity_multiplier
        
        case passive.type
        when :damage_boost, :damage
          "Урон: +#{current_bonus * 100}% → +#{new_bonus.round(1) * 100}%"
        when :speed_boost, :move_speed
          "Скорость: +#{current_bonus * 100}% → +#{new_bonus.round(1) * 100}%"
        when :health_boost, :max_health
          "Здоровье: +#{current_bonus * 100}% → +#{new_bonus.round(1) * 100}%"
        when :regen
          "Регенерация: #{current_bonus.round(2)} → #{new_bonus.round(2)} HP/с"
        when :crit
          "Крит: #{current_bonus * 100}% → #{new_bonus.round(1) * 100}%"
        when :armor
          "Броня: +#{current_bonus * 100}% → +#{new_bonus.round(1) * 100}%"
        when :cooldown_reduction
          "Кулдаун: -#{current_bonus * 100}% → -#{new_bonus.round(1) * 100}%"
        when :area
          "Область: +#{current_bonus * 100}% → +#{new_bonus.round(1) * 100}%"
        when :duration
          "Длительность: +#{current_bonus * 100}% → +#{new_bonus.round(1) * 100}%"
        when :amount, :weapon_amount
          "Снарядов: +#{current_bonus.round(1)} → +#{new_bonus.round(1)}"
        when :magnet
          # Для магнита бонус умножается на 20 для отображения
          current_magnet = (current_bonus * 20).round(0)
          new_magnet = (new_bonus * 20).round(0)
          "Радиус подбора: +#{current_magnet} → +#{new_magnet}"
        when :luck
          "Удача: +#{current_bonus * 100}% → +#{new_bonus.round(1) * 100}%"
        when :growth
          "Опыт: +#{current_bonus * 100}% → +#{new_bonus.round(1) * 100}%"
        when :vampirism
          "Вампиризм: +#{current_bonus * 100}% → +#{new_bonus.round(1) * 100}%"
        when :drop_chance
          "Шанс дропа: +#{current_bonus * 100}% → +#{new_bonus.round(1) * 100}%"
        when :weapon_area
          "Размер оружия: +#{current_bonus * 100}% → +#{new_bonus.round(1) * 100}%"
        when :weapon_range
          "Дальность оружия: +#{current_bonus * 100}% → +#{new_bonus.round(1) * 100}%"
        else
          "Пассивное улучшение: +#{current_bonus * 100}% → +#{new_bonus.round(1) * 100}%"
        end
      else
        "Улучшение пассива"
      end
    when :new_weapon
      "Новое оружие: #{upgrade_data[:name]}"
    else
      "Улучшение"
    end
  end

  def remove
    @title_text&.remove
    @hint_text&.remove
    @texts.values.each(&:remove)
  end
end
