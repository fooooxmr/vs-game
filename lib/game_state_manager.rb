require_relative 'settings'
require_relative 'menu'
require_relative 'settings_screen'
require_relative 'game'
require_relative 'hero_selection'
require_relative 'audio_manager'

class GameStateManager
  STATES = {
    menu: :menu,
    hero_selection: :hero_selection,
    game: :game,
    settings: :settings
  }.freeze

  attr_accessor :current_state, :settings, :menu, :settings_screen, :game, :window_width, :window_height, :hero_selection, :selected_hero, :audio_manager

  def initialize(window_width, window_height)
    @window_width = window_width
    @window_height = window_height
    @settings = Settings.new
    @audio_manager = AudioManager.new(@settings)
    @current_state = :menu
    @selected_hero = nil
    initialize_state(:menu)
  end

  def initialize_state(state)
    case state
    when :menu
      @menu = Menu.new(@window_width, @window_height)
    when :hero_selection
      @hero_selection = HeroSelection.new(@window_width, @window_height)
    when :settings
      @settings_screen = SettingsScreen.new(@window_width, @window_height, @settings)
    when :game
      @game = Game.new(@settings, @selected_hero, @audio_manager)
    end
  end

  def update
    current_time = Time.now.to_f
    @last_update_time ||= current_time
    delta_time = current_time - @last_update_time
    @last_update_time = current_time

    case @current_state
    when :menu
      @menu.update
    when :hero_selection
      @hero_selection.update(delta_time)
    when :settings
      @settings_screen.update
    when :game
      @game.update
    end
  end

  def draw
    case @current_state
    when :menu
      @menu.draw
    when :settings
      @settings_screen.draw
    when :game
      @game.draw
    end
  end

  def handle_key_down(key)
    case @current_state
    when :menu
      action = @menu.handle_key_down(key)
      handle_menu_action(action) if action
    when :hero_selection
      hero_data = @hero_selection.handle_key_down(key)
      if hero_data
        @selected_hero = hero_data
        switch_to_state(:game)
      end
    when :settings
      action = @settings_screen.handle_key_down(key)
      handle_settings_action(action) if action
    when :game
      @game.handle_key_down(key)
      # ESC для возврата в меню (только если игрок мертв или не показываются улучшения)
      if key == 'escape' && (!@game.player.alive? || !@game.showing_upgrades || @game.game_completed)
        switch_to_state(:menu)
        # Обновляем отображение рекорда в меню
        @menu.refresh_high_score if @menu
      end
    end
  end

  def handle_key_up(key)
    @game.handle_key_up(key) if @current_state == :game
  end

  def handle_mouse_down(x, y, button)
    case @current_state
    when :hero_selection
      hero_data = @hero_selection.handle_mouse_click(x, y)
      if hero_data
        @selected_hero = hero_data
        switch_to_state(:game)
      end
    when :game
      @game.handle_mouse_down(x, y, button)
    when :menu
      # Можно добавить клики по меню
    when :settings
      # Можно добавить клики по настройкам
    end
  end

  def handle_menu_action(action)
    case action
    when :new_game
      switch_to_state(:hero_selection)
    when :settings
      switch_to_state(:settings)
    when :exit
      exit
    end
  end

  def handle_settings_action(action)
    case action
    when :back
      @settings.save_to_file
      @audio_manager.update_settings(@settings) if @audio_manager
      switch_to_state(:menu)
    end
  end

  def switch_to_state(new_state)
    # Очищаем текущее состояние
    case @current_state
    when :menu
      @menu&.remove
      @menu = nil
    when :hero_selection
      @hero_selection&.remove
      @hero_selection = nil
    when :settings
      @settings_screen&.remove
      @settings_screen = nil
    when :game
      # Полная очистка игры перед переключением состояния
      if @game
        @game.remove_shapes
        # Дополнительная очистка: убеждаемся, что все враги удалены
        if @game.enemies
          @game.enemies.each do |enemy|
            # Удаляем health bars
            enemy.instance_variable_get(:@health_bar_bg)&.remove if enemy.instance_variable_defined?(:@health_bar_bg)
            enemy.instance_variable_get(:@health_bar)&.remove if enemy.instance_variable_defined?(:@health_bar)
            # Удаляем спрайт
            if enemy.sprite
              enemy.sprite.remove if enemy.sprite.respond_to?(:remove)
              enemy.sprite = nil
            end
            enemy.remove if enemy.respond_to?(:remove)
          end
          @game.enemies.clear
        end
        @game.alive_enemies_cache = nil if @game.respond_to?(:alive_enemies_cache=)
      end
      @game = nil
    end

    @current_state = new_state
    initialize_state(new_state)
  end

end

