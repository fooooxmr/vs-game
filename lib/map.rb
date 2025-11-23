require_relative 'map_object'

class Map
  attr_accessor :width, :height, :objects, :tile_size, :background_tiles, :interactive_objects

  MAP_WIDTH = 3333  # Уменьшено еще в 2 раза (было 6667)
  MAP_HEIGHT = 3333  # Уменьшено еще в 2 раза (было 6667)
  TILE_SIZE = 50
  WALL_THICKNESS = 20
  BUILDING_COUNT = 25 # Увеличено количество мини-зданий для большой карты

  def initialize
    @width = MAP_WIDTH
    @height = MAP_HEIGHT
    @objects = []
    @tile_size = TILE_SIZE
    @background_tiles = []
    @rooms = []
    @buildings = [] # Список зданий
    @interactive_objects = [] # Кэш интерактивных объектов для миникарты
    generate_map
    # Кэшируем интерактивные объекты после генерации
    cache_interactive_objects
  end
  
  def cache_interactive_objects
    @interactive_objects = @objects.select { |obj| obj.interactive }
  end

  def generate_map
    @objects.clear
    @background_tiles.clear
    @rooms.clear
    @buildings.clear
    @interactive_objects = []
    
    generate_background
    generate_map_border
    generate_mini_buildings
    generate_natural_obstacles
    generate_interactive_objects
    generate_decorations
    
    # Кэшируем интерактивные объекты после генерации
    cache_interactive_objects
  end
  
  def generate_map_border
    # Создаем сплошные границы карты
    wall_size = WALL_THICKNESS
    
    # Для меньшей карты создаем сплошные границы с меньшим шагом
    step_size = wall_size # Используем размер стены как шаг для сплошных границ
    
    # Верхняя и нижняя границы
    (-@width / 2..@width / 2).step(step_size) do |x|
      @objects << MapObject.new(x, -@height / 2, :wall)
      @objects << MapObject.new(x, @height / 2, :wall)
    end
    
    # Левая и правая границы
    (-@height / 2..@height / 2).step(step_size) do |y|
      @objects << MapObject.new(-@width / 2, y, :wall)
      @objects << MapObject.new(@width / 2, y, :wall)
    end
  end
  
  def generate_background
    # Фон будет рисоваться динамически в Game.draw
  end
  
  def generate_mini_buildings
    # Генерируем несколько мини-зданий с комнатами и коридорами
    building_spacing = 400 # Минимальное расстояние между зданиями
    
    BUILDING_COUNT.times do |i|
      attempts = 0
      max_attempts = 50
      
      while attempts < max_attempts
        attempts += 1
        
        # Позиция здания (не слишком близко к центру)
        building_x = rand(@width) - @width / 2
        building_y = rand(@height) - @height / 2
        
        distance_from_center = Math.sqrt(building_x**2 + building_y**2)
        next if distance_from_center < 300 # Не создаем здания слишком близко к старту
        
        # Проверяем, не слишком ли близко к другим зданиям
        too_close = @buildings.any? do |building|
          distance = Math.sqrt((building[:x] - building_x)**2 + (building[:y] - building_y)**2)
          distance < building_spacing
        end
        
        next if too_close
        
        # Создаем здание
        building = create_mini_building(building_x, building_y)
        @buildings << building if building
        break
      end
    end
  end
  
  def create_mini_building(center_x, center_y)
    # Создаем мини-здание: несколько комнат, соединенных коридорами
    # Структура: входная комната -> коридор -> несколько комнат -> дальняя комната с сундуком
    
    building_rooms = []
    building_corridors = []
    
    # Размеры здания
    building_width = 200 + rand(150) # 200-350
    building_height = 200 + rand(150) # 200-350
    
    # Количество комнат в здании (3-5)
    room_count = 3 + rand(3)
    
    # 1. Создаем входную комнату (вход снаружи)
    entrance_room_size = 80 + rand(40) # 80-120
    entrance_x = center_x - building_width / 2 + entrance_room_size / 2
    entrance_y = center_y
    
    entrance_room = create_room(entrance_x, entrance_y, entrance_room_size, entrance_room_size)
    building_rooms << entrance_room
    
    # 2. Создаем дальнюю комнату (где будет сундук) - в противоположном конце здания
    end_room_size = 80 + rand(40)
    end_room_x = center_x + building_width / 2 - end_room_size / 2
    end_room_y = center_y + (rand < 0.5 ? -1 : 1) * (building_height / 2 - end_room_size / 2)
    
    end_room = create_room(end_room_x, end_room_y, end_room_size, end_room_size)
    building_rooms << end_room
    
    # 3. Создаем промежуточные комнаты
    (room_count - 2).times do |i|
      room_size = 60 + rand(40) # 60-100
      
      # Размещаем комнаты между входной и дальней
      progress = (i + 1).to_f / (room_count - 1)
      room_x = entrance_x + (end_room_x - entrance_x) * progress + rand(-30..30)
      room_y = entrance_y + (end_room_y - entrance_y) * progress + rand(-30..30)
      
      # Проверяем, не пересекается ли с другими комнатами
      too_close = building_rooms.any? do |room|
        distance = Math.sqrt((room[:x] - room_x)**2 + (room[:y] - room_y)**2)
        distance < room_size + 40
      end
      
      next if too_close
      
      room = create_room(room_x, room_y, room_size, room_size)
      building_rooms << room
    end
    
    # 4. Соединяем комнаты коридорами (линейная структура)
    (building_rooms.length - 1).times do |i|
      room1 = building_rooms[i]
      room2 = building_rooms[i + 1]
      corridor = create_corridor_between_rooms(room1, room2)
      building_corridors << corridor if corridor
    end
    
    # 5. Добавляем несколько боковых коридоров для разнообразия
    if building_rooms.length >= 3
      side_connections = [building_rooms.length / 3, 2].min
      side_connections.times do
        room1 = building_rooms.sample
        room2 = (building_rooms - [room1]).sample
        
        # Соединяем только если комнаты не слишком далеко
        distance = Math.sqrt((room1[:x] - room2[:x])**2 + (room1[:y] - room2[:y])**2)
        if distance < 150 && rand < 0.5
          corridor = create_corridor_between_rooms(room1, room2)
          building_corridors << corridor if corridor
        end
      end
    end
    
    # Сохраняем информацию о здании
    {
      x: center_x,
      y: center_y,
      width: building_width,
      height: building_height,
      rooms: building_rooms,
      corridors: building_corridors,
      entrance_room: entrance_room,
      end_room: end_room # Комната для сундука
    }
  end
  
  def create_room(x, y, width, height)
    # Создаем прямоугольную комнату со стенами
    walls = []
    
    # Верхняя стена
    (width / WALL_THICKNESS).to_i.times do |i|
      wall_x = x - width / 2 + i * WALL_THICKNESS
      wall_y = y - height / 2
      wall_obj = MapObject.new(wall_x, wall_y, :wall)
      @objects << wall_obj
      walls << { obj: wall_obj, x: wall_x, y: wall_y, side: :top, index: i }
    end
    
    # Нижняя стена
    (width / WALL_THICKNESS).to_i.times do |i|
      wall_x = x - width / 2 + i * WALL_THICKNESS
      wall_y = y + height / 2
      wall_obj = MapObject.new(wall_x, wall_y, :wall)
      @objects << wall_obj
      walls << { obj: wall_obj, x: wall_x, y: wall_y, side: :bottom, index: i }
    end
    
    # Левая стена
    (height / WALL_THICKNESS).to_i.times do |i|
      wall_x = x - width / 2
      wall_y = y - height / 2 + i * WALL_THICKNESS
      wall_obj = MapObject.new(wall_x, wall_y, :wall)
      @objects << wall_obj
      walls << { obj: wall_obj, x: wall_x, y: wall_y, side: :left, index: i }
    end
    
    # Правая стена
    (height / WALL_THICKNESS).to_i.times do |i|
      wall_x = x + width / 2
      wall_y = y - height / 2 + i * WALL_THICKNESS
      wall_obj = MapObject.new(wall_x, wall_y, :wall)
      @objects << wall_obj
      walls << { obj: wall_obj, x: wall_x, y: wall_y, side: :right, index: i }
    end
    
    room_data = {
      x: x,
      y: y,
      width: width,
      height: height,
      walls: walls
    }
    
    @rooms << room_data
    room_data
  end
  
  def create_corridor_between_rooms(room1, room2)
    # Создаем L-образный коридор между двумя комнатами
    corridor_width = 50
    
    # Находим точки выхода из комнат
    exit1 = find_room_exit(room1, room2)
    exit2 = find_room_exit(room2, room1)
    
    # Создаем L-образный коридор
    corridor_walls = []
    
    # Горизонтальная часть
    if (exit1[:x] - exit2[:x]).abs > 20
      start_x = [exit1[:x], exit2[:x]].min
      end_x = [exit1[:x], exit2[:x]].max
      mid_y = exit1[:y]
      
      # Стены коридора (по бокам)
      (start_x..end_x).step(WALL_THICKNESS) do |x|
        # Верхняя стена коридора
        if can_place_object?(x, mid_y - corridor_width / 2, WALL_THICKNESS)
          wall_obj = MapObject.new(x, mid_y - corridor_width / 2, :wall)
          @objects << wall_obj
          corridor_walls << wall_obj
        end
        # Нижняя стена коридора
        if can_place_object?(x, mid_y + corridor_width / 2, WALL_THICKNESS)
          wall_obj = MapObject.new(x, mid_y + corridor_width / 2, :wall)
          @objects << wall_obj
          corridor_walls << wall_obj
        end
      end
    end
    
    # Вертикальная часть
    if (exit1[:y] - exit2[:y]).abs > 20
      start_y = [exit1[:y], exit2[:y]].min
      end_y = [exit1[:y], exit2[:y]].max
      mid_x = exit2[:x]
      
      # Стены коридора (по бокам)
      (start_y..end_y).step(WALL_THICKNESS) do |y|
        # Левая стена коридора
        if can_place_object?(mid_x - corridor_width / 2, y, WALL_THICKNESS)
          wall_obj = MapObject.new(mid_x - corridor_width / 2, y, :wall)
          @objects << wall_obj
          corridor_walls << wall_obj
        end
        # Правая стена коридора
        if can_place_object?(mid_x + corridor_width / 2, y, WALL_THICKNESS)
          wall_obj = MapObject.new(mid_x + corridor_width / 2, y, :wall)
          @objects << wall_obj
          corridor_walls << wall_obj
        end
      end
    end
    
    # Удаляем стены комнат в местах выходов
    remove_wall_at(room1, exit1[:x], exit1[:y])
    remove_wall_at(room2, exit2[:x], exit2[:y])
    
    { walls: corridor_walls }
  end
  
  def find_room_exit(room, target_room)
    # Находим ближайшую точку на стене комнаты к целевой комнате
    room_x = room[:x]
    room_y = room[:y]
    room_width = room[:width]
    room_height = room[:height]
    target_x = target_room[:x]
    target_y = target_room[:y]
    
    dx = target_x - room_x
    dy = target_y - room_y
    
    if dx.abs > dy.abs
      if dx > 0
        { x: room_x + room_width / 2, y: room_y, side: :right }
      else
        { x: room_x - room_width / 2, y: room_y, side: :left }
      end
    else
      if dy > 0
        { x: room_x, y: room_y + room_height / 2, side: :bottom }
      else
        { x: room_x, y: room_y - room_height / 2, side: :top }
      end
    end
  end
  
  def remove_wall_at(room, exit_x, exit_y)
    # Удаляем стену комнаты в указанной точке
    removal_radius = WALL_THICKNESS * 2.5
    
    room[:walls].each do |wall_info|
      wall = wall_info[:obj]
      distance = Math.sqrt((wall.x - exit_x)**2 + (wall.y - exit_y)**2)
      
      if distance < removal_radius
        @objects.delete(wall)
        wall.remove
      end
    end
  end
  
  def inside_any_room?(x, y)
    @rooms.each do |room|
      room_x = room[:x]
      room_y = room[:y]
      room_width = room[:width]
      room_height = room[:height]
      
      padding = 30
      if (x - room_x).abs < room_width / 2 - padding && (y - room_y).abs < room_height / 2 - padding
        return true
      end
    end
    false
  end
  
  def inside_any_building?(x, y)
    # Проверяем, находится ли точка внутри какого-либо здания
    @buildings.each do |building|
      building_x = building[:x]
      building_y = building[:y]
      building_width = building[:width]
      building_height = building[:height]
      
      if (x - building_x).abs < building_width / 2 && (y - building_y).abs < building_height / 2
        return true
      end
    end
    false
  end
  
  def generate_natural_obstacles
    generate_tree_groves(4)
    generate_rock_fields(3)
    generate_meadows(4)
  end
  
  def generate_tree_groves(count)
    count.times do
      grove_x = rand(@width) - @width / 2
      grove_y = rand(@height) - @height / 2
      
      distance_from_center = Math.sqrt(grove_x**2 + grove_y**2)
      next if distance_from_center < 200
      next if inside_any_room?(grove_x, grove_y)
      next if inside_any_building?(grove_x, grove_y)
      
      grove_size = 6 + rand(10)
      grove_radius = 50 + rand(40)
      
      grove_size.times do
        angle = rand * Math::PI * 2
        distance = rand * grove_radius
        x = grove_x + Math.cos(angle) * distance
        y = grove_y + Math.sin(angle) * distance
        
        next if inside_any_room?(x, y)
        next if inside_any_building?(x, y)
        
        type = rand < 0.2 ? :big_tree : :tree
        if can_place_object?(x, y, type == :big_tree ? 40 : 30)
          @objects << MapObject.new(x, y, type)
        end
      end
    end
  end
  
  def generate_rock_fields(count)
    count.times do
      field_x = rand(@width) - @width / 2
      field_y = rand(@height) - @height / 2
      
      distance_from_center = Math.sqrt(field_x**2 + field_y**2)
      next if distance_from_center < 150
      next if inside_any_room?(field_x, field_y)
      next if inside_any_building?(field_x, field_y)
      
      field_size = 6 + rand(10)
      field_radius = 40 + rand(30)
      
      field_size.times do
        angle = rand * Math::PI * 2
        distance = rand * field_radius
        x = field_x + Math.cos(angle) * distance
        y = field_y + Math.sin(angle) * distance
        
        next if inside_any_room?(x, y)
        next if inside_any_building?(x, y)
        
        type = rand < 0.3 ? :big_rock : :rock
        if can_place_object?(x, y, type == :big_rock ? 35 : 25)
          @objects << MapObject.new(x, y, type)
        end
      end
    end
  end
  
  def generate_meadows(count)
    count.times do
      meadow_x = rand(@width) - @width / 2
      meadow_y = rand(@height) - @height / 2
      
      distance_from_center = Math.sqrt(meadow_x**2 + meadow_y**2)
      next if distance_from_center < 100
      next if inside_any_room?(meadow_x, meadow_y)
      next if inside_any_building?(meadow_x, meadow_y)
      
      meadow_size = 15 + rand(25)
      meadow_radius = 60 + rand(40)
      
      meadow_size.times do
        angle = rand * Math::PI * 2
        distance = rand * meadow_radius
        x = meadow_x + Math.cos(angle) * distance
        y = meadow_y + Math.sin(angle) * distance
        
        next if inside_any_room?(x, y)
        next if inside_any_building?(x, y)
        
        type = [:grass_patch, :flower, :bush].sample
        size = case type
        when :grass_patch then 15
        when :flower then 10
        when :bush then 20
        end
        
        if can_place_object?(x, y, size, check_solid_only: true)
          @objects << MapObject.new(x, y, type)
        end
      end
    end
  end
  
  def generate_interactive_objects
    generate_chests_structured
    generate_lamps_structured
    generate_barrels_structured
    generate_tombstones_structured
    generate_altars
    generate_portal
  end
  
  def generate_chests_structured
    # Сундуки размещаем в дальних комнатах зданий
    chest_count = @buildings.length # По одному сундуку на здание
    
    @buildings.each do |building|
      end_room = building[:end_room]
      next unless end_room
      
      # Размещаем сундук в дальнем углу комнаты
      corner = rand(4)
      case corner
      when 0 # Верхний левый
        chest_x = end_room[:x] - end_room[:width] * 0.3
        chest_y = end_room[:y] - end_room[:height] * 0.3
      when 1 # Верхний правый
        chest_x = end_room[:x] + end_room[:width] * 0.3
        chest_y = end_room[:y] - end_room[:height] * 0.3
      when 2 # Нижний левый
        chest_x = end_room[:x] - end_room[:width] * 0.3
        chest_y = end_room[:y] + end_room[:height] * 0.3
      when 3 # Нижний правый
        chest_x = end_room[:x] + end_room[:width] * 0.3
        chest_y = end_room[:y] + end_room[:height] * 0.3
      end
      
      if can_place_object?(chest_x, chest_y, 25)
        @objects << MapObject.new(chest_x, chest_y, :chest)
        chest_count += 1
      end
    end
    
    # Дополнительные сундуки в открытых областях (редкость, но не слишком мало)
    additional_chests = 8  # Уменьшено для баланса
    additional_chests.times do
      x = rand(@width) - @width / 2
      y = rand(@height) - @height / 2
      
      distance_from_center = Math.sqrt(x**2 + y**2)
      next if distance_from_center < 200
      next if inside_any_room?(x, y)
      next if inside_any_building?(x, y)
      
      if can_place_object?(x, y, 25)
        @objects << MapObject.new(x, y, :chest)
        chest_count += 1
      end
    end
  end
  
  def generate_barrels_structured
    # Ящики размещаем по пути к сундукам (в коридорах и промежуточных комнатах)
    barrel_count = 0
    
    @buildings.each do |building|
      # Ящики в коридорах (по пути к сундуку)
      building[:corridors].each do |corridor|
        # Размещаем 1-2 ящика в каждом коридоре
        (1 + rand(2)).times do
          # Находим центр коридора (приблизительно)
          # Для простоты размещаем ящики в промежуточных комнатах
          next
        end
      end
      
      # Ящики в промежуточных комнатах (не в входной и не в дальней)
      intermediate_rooms = building[:rooms] - [building[:entrance_room], building[:end_room]]
      intermediate_rooms.each do |room|
        # 1-2 ящика в каждой промежуточной комнате
        (1 + rand(2)).times do
          side = rand(4)
          case side
          when 0 # Верхняя стена
            barrel_x = room[:x] + (rand - 0.5) * room[:width] * 0.5
            barrel_y = room[:y] - room[:height] * 0.3
          when 1 # Нижняя стена
            barrel_x = room[:x] + (rand - 0.5) * room[:width] * 0.5
            barrel_y = room[:y] + room[:height] * 0.3
          when 2 # Левая стена
            barrel_x = room[:x] - room[:width] * 0.3
            barrel_y = room[:y] + (rand - 0.5) * room[:height] * 0.5
          when 3 # Правая стена
            barrel_x = room[:x] + room[:width] * 0.3
            barrel_y = room[:y] + (rand - 0.5) * room[:height] * 0.5
          end
          
          if can_place_object?(barrel_x, barrel_y, 20)
            @objects << MapObject.new(barrel_x, barrel_y, :barrel)
            barrel_count += 1
          end
        end
      end
    end
    
    # Дополнительные ящики в открытых областях (редкость, но не слишком мало)
    remaining = [15 - barrel_count, 0].max
    remaining.times do
      x = rand(@width) - @width / 2
      y = rand(@height) - @height / 2
      
      distance_from_center = Math.sqrt(x**2 + y**2)
      next if distance_from_center < 150
      next if inside_any_room?(x, y)
      next if inside_any_building?(x, y)
      
      if can_place_object?(x, y, 20)
        @objects << MapObject.new(x, y, :barrel)
      end
    end
  end
  
  def generate_lamps_structured
    lamp_count = 20
    
    @rooms.each do |room|
      (1 + rand(2)).times do
        side = rand(4)
        case side
        when 0
          lamp_x = room[:x] + (rand - 0.5) * room[:width] * 0.6
          lamp_y = room[:y] - room[:height] * 0.4
        when 1
          lamp_x = room[:x] + (rand - 0.5) * room[:width] * 0.6
          lamp_y = room[:y] + room[:height] * 0.4
        when 2
          lamp_x = room[:x] - room[:width] * 0.4
          lamp_y = room[:y] + (rand - 0.5) * room[:height] * 0.6
        when 3
          lamp_x = room[:x] + room[:width] * 0.4
          lamp_y = room[:y] + (rand - 0.5) * room[:height] * 0.6
        end
        
        if can_place_object?(lamp_x, lamp_y, 15)
          @objects << MapObject.new(lamp_x, lamp_y, :lamp)
        end
      end
    end
  end
  
  def generate_tombstones_structured
    cemetery_count = 30  # Увеличено для большой карты
    cemetery_count.times do
      cemetery_x = rand(@width) - @width / 2
      cemetery_y = rand(@height) - @height / 2
      
      distance_from_center = Math.sqrt(cemetery_x**2 + cemetery_y**2)
      next if distance_from_center < 150
      next if inside_any_room?(cemetery_x, cemetery_y)
      next if inside_any_building?(cemetery_x, cemetery_y)
      
      cemetery_size = 3 + rand(5)
      cemetery_size.times do
        x = cemetery_x + (rand - 0.5) * 60
        y = cemetery_y + (rand - 0.5) * 60
        
        next if inside_any_room?(x, y)
        next if inside_any_building?(x, y)
        
        if can_place_object?(x, y, 20)
          @objects << MapObject.new(x, y, :tombstone)
        end
      end
    end
  end

  def generate_decorations
    decoration_count = 200  # Уменьшено для оптимизации производительности
    
    decoration_count.times do
      x = rand(@width) - @width / 2
      y = rand(@height) - @height / 2
      
      distance_from_center = Math.sqrt(x**2 + y**2)
      next if distance_from_center < 50
      next if inside_any_room?(x, y)
      next if inside_any_building?(x, y)
      
      type = [:grass_patch, :flower, :bush].sample
      size = case type
      when :grass_patch then 15
      when :flower then 10
      when :bush then 20
      end
      
      if can_place_object?(x, y, size, check_solid_only: true)
        @objects << MapObject.new(x, y, type)
      end
    end
  end

  def can_place_object?(x, y, size, check_solid_only: false)
    @objects.each do |obj|
      next if check_solid_only && !obj.solid
      
      distance = Math.sqrt((obj.x - x)**2 + (obj.y - y)**2)
      min_distance = (obj.size + size) / 2 + 5
      
      return false if distance < min_distance
    end
    true
  end

  def get_collisions(x, y, size)
    collisions = []
    @objects.each do |obj|
      if obj.collides_with?(x, y, size)
        collisions << obj
      end
    end
    collisions
  end

  def get_visible_objects(camera)
    # Оптимизация: используем прямой перебор вместо select для лучшей производительности
    # Преобразуем экранные координаты в мировые для быстрой проверки
    screen_min_x, screen_min_y = 0, 0
    screen_max_x, screen_max_y = camera.window_width, camera.window_height
    
    world_min_x, world_min_y = camera.screen_to_world(screen_min_x, screen_min_y)
    world_max_x, world_max_y = camera.screen_to_world(screen_max_x, screen_max_y)
    
    # Добавляем запас для объектов, которые частично видны
    margin = 100
    world_min_x -= margin
    world_min_y -= margin
    world_max_x += margin
    world_max_y += margin
    
    # Быстрая проверка по границам (без вычисления расстояния)
    # Используем прямой перебор для лучшей производительности
    visible = []
    @objects.each do |obj|
      if obj.x >= world_min_x && obj.x <= world_max_x && 
         obj.y >= world_min_y && obj.y <= world_max_y
        visible << obj
      end
    end
    visible
  end

  def generate_altars
    # Алтари размещаем в специальных местах (далеко от центра, в труднодоступных местах)
    altar_count = 15  # Увеличено для большой карты
    
    altar_count.times do
      # Пробуем разместить алтарь
      attempts = 0
      placed = false
      
      while attempts < 50 && !placed
        x = rand(@width) - @width / 2
        y = rand(@height) - @height / 2
        
        # Алтари должны быть далеко от центра
        distance_from_center = Math.sqrt(x**2 + y**2)
        next if distance_from_center < 300
        
        # Не должны быть в зданиях или комнатах
        next if inside_any_room?(x, y) || inside_any_building?(x, y)
        
        # Проверяем, что можно разместить
        if can_place_object?(x, y, 50)
          @objects << MapObject.new(x, y, :altar)
          placed = true
        end
        
        attempts += 1
      end
    end
  end
  
  def generate_portal
    # Портал размещаем в самом дальнем углу карты
    # Выбираем случайный угол
    corner = rand(4)
    case corner
    when 0 # Верхний левый
      portal_x = -@width / 2 + 100
      portal_y = -@height / 2 + 100
    when 1 # Верхний правый
      portal_x = @width / 2 - 100
      portal_y = -@height / 2 + 100
    when 2 # Нижний левый
      portal_x = -@width / 2 + 100
      portal_y = @height / 2 - 100
    when 3 # Нижний правый
      portal_x = @width / 2 - 100
      portal_y = @height / 2 - 100
    end
    
    # Проверяем, что можно разместить
    if can_place_object?(portal_x, portal_y, 70)
      @objects << MapObject.new(portal_x, portal_y, :portal)
    end
  end

  def remove
    @objects.each(&:remove)
    @objects.clear
  end
end
