require 'ruby2d'
require_relative 'lib/game_state_manager'

# Загружаем настройки для начального размера окна
temp_settings = Settings.new

# Создаем окно
set title: "Vampire Survival Like"
set width: temp_settings.resolution_width
set height: temp_settings.resolution_height
set background: 'black'
set resizable: false

# Создаем менеджер состояний
state_manager = GameStateManager.new(temp_settings.resolution_width, temp_settings.resolution_height)

# Обработка нажатий клавиш
on :key_down do |event|
  state_manager.handle_key_down(event.key)
end

on :key_up do |event|
  state_manager.handle_key_up(event.key)
end

# Обработка мыши
on :mouse_down do |event|
  state_manager.handle_mouse_down(event.x, event.y, event.button)
end

# Игровой цикл
update do
  state_manager.update
  state_manager.draw
end

# Запускаем игру
show

