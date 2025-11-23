require_relative 'ui_enhancer'

class UpgradeScreen
  attr_accessor :selected_index, :available_upgrades, :shapes, :texts

  def initialize(window_width, window_height, upgrade_system)
    @window_width = window_width
    @window_height = window_height
    @upgrade_system = upgrade_system
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
    @title_text&.remove
    @hint_text&.remove
    @title_text = nil
    @hint_text = nil
    @texts.values.each(&:remove)
    @texts.clear
    if @window_shapes
      @window_shapes.values.each(&:remove)
      @window_shapes.clear
    end
    if @card_shapes
      @card_shapes.values.each { |cards| cards.values.each(&:remove) }
      @card_shapes.clear
    end
  end

  def available_upgrades
    @using_vs_system ? @vs_upgrades : @available_upgrades
  end

  def initialize_shapes
    # Заголовок и подсказка создаются только при показе улучшений
    @title_text = nil
    @hint_text = nil
  end

  def create_title_and_hint
    return if @title_text && @hint_text

    # Заголовок с эффектом свечения (как в выборе персонажа)
    @title_text = Text.new(
      'ВЫБЕРИТЕ УЛУЧШЕНИЕ',
      x: @window_width / 2,
      y: @window_height / 2 - 180,
      size: 72,
      color: '#FFD700',
      font: nil
    )
    @title_text.x = @window_width / 2 - @title_text.width / 2

    # Подсказка - светлый цвет для читаемости
    @hint_text = Text.new(
      'Используйте W/S или ↑/↓ для выбора | Enter для подтверждения',
      x: @window_width / 2,
      y: @window_height / 2 + 180,
      size: 22,
      color: '#AAAAAA',
      font: nil
    )
    @hint_text.x = @window_width / 2 - @hint_text.width / 2
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
      y_pos = @window_height / 2 + index * 100
      level = @upgrade_system.get_upgrade_level(key)
      max_level = UpgradeSystem::UPGRADES[key][:max_level]
      
      # Название улучшения
      name_text = Text.new(
        "#{data[:icon]} #{data[:name]} (Ур. #{level}/#{max_level})",
        x: @window_width / 2,
        y: y_pos,
        size: 35,
        color: index == @selected_index ? 'yellow' : 'white',
        font: nil
      )
      name_text.x = @window_width / 2 - name_text.width / 2
      @texts["upgrade_#{index}_name"] = name_text

      # Описание
      desc_text = Text.new(
        data[:description],
        x: @window_width / 2,
        y: y_pos + 40,
        size: 22,
        color: '#CCCCCC',
        font: nil
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
    
    # Проверяем клик по улучшениям
    upgrades = @using_vs_system ? @vs_upgrades : @available_upgrades.keys
    upgrades.each_with_index do |upgrade, index|
      y_pos = @window_height / 2 - 100 + index * 100
      if y >= y_pos && y <= y_pos + 80
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

    # Создаем карточки и тексты для улучшений
    @vs_upgrades.each_with_index do |upgrade_data, index|
      y_pos = @window_height / 2 - 80 + index * 100
      level = upgrade_data[:level]
      max_level = upgrade_data[:max_level]
      selected = index == @selected_index
      
      # Создаем карточку
      @card_shapes[index] = UIEnhancer.create_upgrade_card(@window_width, @window_height, y_pos, selected)
      
      # Название улучшения - яркий контрастный цвет
      name_color = selected ? '#FFD700' : '#FFFFFF' # Белый для невыбранных, золотой для выбранных
      name_size = selected ? 42 : 36
      name_text = Text.new(
        "#{upgrade_data[:icon]} #{upgrade_data[:name]} (Ур. #{level}/#{max_level})",
        x: @window_width / 2,
        y: y_pos + 20,
        size: name_size,
        color: name_color,
        font: nil
      )
      name_text.x = @window_width / 2 - name_text.width / 2
      @texts["upgrade_#{index}_name"] = name_text

      # Описание - светлый контрастный цвет для читаемости
      desc = case upgrade_data[:type]
      when :new_weapon, :weapon_upgrade
        "Оружие: #{upgrade_data[:name]}"
      when :new_passive, :passive_upgrade
        "Пассивное улучшение: #{upgrade_data[:name]}"
      else
        "Улучшение"
      end

      desc_text = Text.new(
        desc,
        x: @window_width / 2,
        y: y_pos + 55,
        size: 20,
        color: selected ? '#FFE080' : '#E0E0E0', # Светло-серый для невыбранных, светло-желтый для выбранных
        font: nil
      )
      desc_text.x = @window_width / 2 - desc_text.width / 2
      @texts["upgrade_#{index}_desc"] = desc_text
    end
  end

  def remove
    @title_text&.remove
    @hint_text&.remove
    @texts.values.each(&:remove)
  end
end

