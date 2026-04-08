# BinaryWars

![CI](https://github.com/iblochko/BinaryWars/actions/workflows/ci.yml/badge.svg)

Пошаговая стратегия на движке [Godot 4](https://godotengine.org/), разрабатываемая в рамках учебного курса.


<img width="1153" height="647" alt="image" src="https://github.com/user-attachments/assets/907a544f-ee5f-4e8d-b90a-cd8e97516a4c" />

---

## Описание игры

Два игрока управляют отрядами юнитов на тайловой карте. Каждый ход игрок перемещает своих воинов и атакует противника. Победа — уничтожение всех вражеских юнитов.

**Текущий статус:** реализованы движение, боевая система, смена ходов, UI панели действий и отображение HP.

---

## Требования

| Компонент | Версия |
|-----------|--------|
| [Godot Engine](https://godotengine.org/download/) | **4.4+** (проверено на 4.6) |
| ОС | Windows 10/11 |
| GPU | Поддержка Vulkan / DirectX 12 (Forward+ рендерер) |

---

## Запуск проекта

```bash
# 1. Клонируй репозиторий
git clone https://github.com/iblochko/BinaryWars.git
cd BinaryWars

# 2. Открой Godot Editor
# File → Import → укажи папку bw/ (или файл bw/project.godot)

# 3. Нажми F5 или кнопку Play
# Запустится сцена bw/scenes/game/Game.tscn
```

> **Важно:** папка проекта — `bw/`, а не корень репозитория. При импорте указывай путь до `bw/project.godot`.

---

## Управление

| Действие | Клавиша / кнопка |
|----------|-----------------|
| Выбрать юнита | ЛКМ по юниту |
| Переместить юнита | ЛКМ по подсвеченной клетке |
| Включить режим атаки | Кнопка «Атака» в панели действий |
| Атаковать врага | ПКМ по вражескому юниту (в режиме атаки) |
| Отменить выбор | ПКМ по пустой клетке |
| Завершить ход | Кнопка «Завершить ход» в UI |
| Камера (движение) | WASD или стрелки |
| Камера (зум) | Колёсико мыши |

---

## Структура проекта

```
BinaryWars/
├── bw/                               # Godot-проект
│   ├── assets/
│   │   └── sprites/
│   │       ├── tiles/                # Тайлы карты (bus, field)
│   │       ├── units/                # Спрайты юнитов и предметов
│   │       └── ui/                   # UI иконки (next_turn и др.)
│   ├── scenes/
│   │   ├── game/
│   │   │   ├── Game.tscn             # Главная сцена
│   │   │   └── Map.tscn              # Карта (TileMap + менеджеры)
│   │   ├── ui/
│   │   │   ├── ActionPanel.tscn      # Панель действий юнита
│   │   │   └── TurnUI.tscn           # UI смены ходов
│   │   └── units/
│   │       └── Onerrior.tscn         # Сцена юнита-воина
│   ├── scripts/
│   │   ├── managers/
│   │   │   ├── MapManager.gd         # Карта, поиск пути, обработка кликов
│   │   │   ├── TurnManager.gd        # Логика смены ходов и фракций
│   │   │   ├── TurnUI.gd             # UI отображение текущего хода
│   │   │   └── CameraManager.gd      # Управление камерой
│   │   ├── ui/
│   │   │   └── ActionPanel.gd        # Панель действий (атака, защита, пропуск)
│   │   └── units/
│   │       ├── Unit.gd               # Базовый класс юнита (HP, движение, атака)
│   │       └── Onerrior.gd           # Воин
│   ├── node.gd                       # Unit-тесты
│   └── project.godot
├── .github/
│   └── workflows/
│       └── ci.yml                    # GitHub Actions: автотесты при каждом PR
├── architecture.md                   # Архитектура As-is / To-be
├── duetProgramming.md                # Отчёт по парному программированию
└── README.md
```

---

## Архитектура компонентов

```
Game.tscn
├── Map (MapManager.gd)       — карта, BFS поиск пути, клики
│   ├── TileMap               — тайловая карта
│   ├── Camera2D (CameraManager.gd)
│   └── Onerrior (Unit.gd)    — юниты игрока
├── TurnManager.gd            — смена ходов PLAYER ↔ ENEMY
├── TurnUI.gd                 — отображение хода и кнопка завершения
└── ActionPanel.gd            — панель действий выбранного юнита
```

**Поток событий при выборе юнита:**
```
ЛКМ по юниту
  → MapManager._input()
  → unit.select_unit()
  → ActionPanel.show_panel(unit)
  → MapManager.highlight_available_cells()
```

**Поток событий при атаке:**
```
ActionPanel: кнопка «Атака»
  → unit.enable_attack_mode()
  → MapManager.highlight_attack_cells()  [красная подсветка]
ПКМ по врагу
  → MapManager.handle_right_click()
  → unit.attack_target(target)
  → target.take_damage()
```

---

## Запуск тестов

```bash
# Headless (без GUI):
godot --headless --path bw/ -s node.gd
```

Пример вывода:
```
🧪 Запуск Unit-тестов...
✅ PASS: Урон меньше брони (3 < 5)
✅ PASS: Урон больше брони (10 - 5 = 5)
✅ PASS: Смерть юнита: здоровье не уходит в минус
✅ Итоги: Пройдено - 3, Провалено - 0
```

---

## CI/CD

При каждом `push` в `main` и при открытии `pull request` автоматически запускается GitHub Actions — запускает тесты в headless Godot. Статус отображается в бейдже вверху README.

---

## Команда

- Хомутов Максим
- Тарашкевич Даниил
- Тимофеюк Владислав
