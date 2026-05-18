---
name: russian-titles
description: All user-facing titles created by the agent must be in Russian. Applies to spawned tasks (mcp__ccd_session__spawn_task), chapter markers (mcp__ccd_session__mark_chapter), TodoWrite items, git commit messages, PR titles/bodies, scheduled task names, and any other titles or labels the agent emits. Active at all times — no trigger phrase required.
---

# Russian Titles

Все заголовки, которые я создаю и которые увидит пользователь, должны быть на русском языке.

## Где это применяется

Каждый раз, когда вызываю любой из тулов ниже, поля `title` / `description` / `summary` / `name` / `content` / `activeForm` пишу по-русски:

- `mcp__ccd_session__spawn_task` — поля `title`, `tldr`, `prompt` (prompt можно оставить детально на русском или mix, главное — заголовок на русском)
- `mcp__ccd_session__mark_chapter` — поля `title`, `summary`
- `TodoWrite` — поля `content`, `activeForm`
- `Bash` tool — поле `description` (когда команда выполняется в интересах русскоязычного пользователя)
- `mcp__scheduled-tasks__create_scheduled_task` — название задачи
- `gh pr create` — `--title` и `--body` на русском
- `git commit -m` — сообщение на русском
- `Write` / `Edit` при создании markdown-документов для пользователя — заголовки H1/H2 на русском, если документ предназначен для чтения пользователем

## Что НЕ контролирую

- Заголовок самого чата в сайдбаре Claude Code — генерируется харнессом из первого сообщения пользователя, инструмент `rename_session` агенту не выдан. Если пользователь хочет переименовать существующий чат — он делает это в UI (карандаш / правый клик → Rename).
- Имена скиллов и тулов — это фиксированные технические идентификаторы (`russian-titles`, `Bash`, и т.д.), их латиница не нарушает правило.
- Имена файлов в коде — это технические идентификаторы, английский норм.

## Стиль

- Без эмодзи, если пользователь явно не попросил.
- Короткие, на 2–6 слов: «Исправление бага в auth», «Установка скилла», «Проверка деплоя».
- Императив или существительное-фраза, не вопрос.
- Технические термины можно оставлять английскими, если так привычнее: «Деплой staging», «Обновление CI», «Фикс CORS».
- Имена файлов, переменных, команд — латиницей внутри русского заголовка («Фикс баги в `useAuth`», «Удаление `node_modules`»).

## Поведение при новой сессии

Если вижу, что текущий чат имеет английский auto-сгенерённый заголовок, и пользователь явно русскоязычный — могу один раз предложить русский вариант + напомнить, как переименовать вручную в UI. Без навязчивости — только в первом ответе сессии.

## Примеры

**TodoWrite — правильно:**
```
content: "Поставить плагин windows-shell"
activeForm: "Ставлю плагин windows-shell"
```

**Bash description — правильно:**
```
description: "Клонирую репо и копирую SKILL.md"
```

**spawn_task — правильно:**
```
title: "Удалить мёртвый импорт"
tldr: "Убрать неиспользуемый импорт lodash из api/server.ts"
```

**mark_chapter — правильно:**
```
title: "Установка скиллов"
summary: "Поставил matt-pocock skills + windows-shell"
```

**Commit message — правильно:**
```
Добавить russian-titles скилл

Co-Authored-By: ...
```
