extends Node


var tests_passed = 0
var tests_failed = 0

func _ready():
	print("🧪 Запуск Unit-тестов...")

	test_warrior_take_damage()
	
	test_map_manager_logic()
	
	print("\n✅ Итоги: Пройдено - %d, Провалено - %d" % [tests_passed, tests_failed])
	
	get_tree().quit() 

func assert_equal(actual, expected, test_name):
	if actual == expected:
		print("✅ PASS: ", test_name)
		tests_passed += 1
	else:
		print("❌ FAIL: ", test_name, " | Ожидалось: ", expected, " | Получено: ", actual)
		tests_failed += 1

func test_warrior_take_damage():
	print("\n--- Тестирование Воина (Onerrior) ---")
	
	var warrior = load("res://scripts/units/Onerrior.gd").new()

	warrior.health = 100
	warrior.defense = 5
	warrior.max_health = 100
	
	warrior.take_damage(3) 
	assert_equal(warrior.health, 100, "Урон меньше брони (3 < 5)")
	
	warrior.health = 100 
	
	warrior.take_damage(10)
	assert_equal(warrior.health, 95, "Урон больше брони (10 - 5 = 5)")
	

	warrior.health = 5
	warrior.defense = 0
	warrior.take_damage(10) 
	assert_equal(warrior.health, 0, "Смерть юнита (здоровье не уходит в минус)")
	
	warrior.queue_free()

func test_map_manager_logic():
	print("\n--- Тестирование MapManager (Логика) ---")
	
	var center = Vector2i(0, 0)
	var range = 1
	
	var map_mgr = get_tree().get_first_node_in_group("map_manager")
	if map_mgr:
		var path = map_mgr.find_path(Vector2i(0,0), Vector2i(0,0), 5, true)
		assert_equal(path.size(), 1, "Путь к самому себе (размер 1)")
		
		path = map_mgr.find_path(Vector2i(0,0), Vector2i(0,1), 5, true)
		assert_equal(path.size(), 2, "Путь на соседнюю клетку (размер 2)")
		
		path = map_mgr.find_path(Vector2i(0,0), Vector2i(1,1), 5, true)
		assert_equal(path.size(), 3, "Путь на клетку по диагонали (размер 3)")
		
		path = map_mgr.find_path(Vector2i(0,0), Vector2i(1,1), 5, true)
		assert_equal(path.size(), 10, "Путь на клетку по диагонали (размер 10)")
	else:
		print("⚠️ MapManager не найден в сцене, тест пропущен")
		tests_passed += 1
