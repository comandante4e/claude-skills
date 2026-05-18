# claude-skills

Личная коллекция скиллов для Claude Code. Шарится между моими машинами и с друзьями через симлинки/junction-ы из этого репо в `~/.claude/skills/`.

## Что внутри

Папка `skills/` — каждый подкаталог это один скилл (формат [Anthropic Skills](https://github.com/anthropics/skills): `SKILL.md` с YAML-фронтматтером + опциональные ресурсы).

Папка `scripts/` — установочные скрипты:
- `sync.ps1` — для Windows (использует Junction, права админа не нужны)
- `sync.sh` — для macOS / Linux (использует обычные симлинки)

## Установка на новой машине

### Windows

```powershell
git clone https://github.com/<your-user>/claude-skills.git $HOME\claude-skills
cd $HOME\claude-skills
.\scripts\sync.ps1
```

`sync.ps1` создаст junction-ы из `skills/<name>` в `~/.claude/skills/<name>` для каждого скилла. Если такая папка уже существует — спросит, перезаписать или пропустить.

Полезные флаги:
- `-DryRun` — показать что будет сделано, ничего не делать
- `-Force` — перезаписать без вопросов
- `-Only caveman,tdd` — синкнуть только конкретные скиллы

### macOS / Linux

```bash
git clone https://github.com/<your-user>/claude-skills.git ~/claude-skills
cd ~/claude-skills
./scripts/sync.sh
```

Те же флаги: `--dry-run`, `--force`, `--only caveman,tdd`.

## Workflow

### Обновить скиллы на этой машине

```bash
cd ~/claude-skills
git pull
```

Поскольку `~/.claude/skills/<name>` это junction/симлинк на `skills/<name>` в репо, после `git pull` все изменения сразу применяются — пересинкать не нужно.

### Изменить скилл и закоммитить

Правишь файлы прямо в `~/.claude/skills/<name>/SKILL.md` (по факту правится файл в репо через симлинк):

```bash
cd ~/claude-skills
git add skills/<name>
git commit -m "<name>: уточнил триггеры"
git push
```

### Добавить новый скилл

1. Создать папку `skills/<имя>/SKILL.md` (см. формат во `skills/write-a-skill/SKILL.md`)
2. Запустить `./scripts/sync.ps1 -Only <имя>` (или `.sh`) — создаст junction
3. Закоммитить

## Использование в других AI-тулах

Формат `SKILL.md` это просто Markdown с фронтматтером — переносимо. Механизм загрузки разный:

| Инструмент | Куда положить |
|---|---|
| Claude Code | `~/.claude/skills/<name>/` (этим занимается `sync.ps1`/`sync.sh`) |
| Cursor | `.cursor/rules/<name>.mdc` в корне проекта |
| Codex CLI | `AGENTS.md` или конфиг проекта |
| Aider | conventions-файл, указанный в `.aider.conf.yml` |
| web Claude / ChatGPT | вставить содержимое `SKILL.md` в Project Knowledge / Custom Instructions |

### Подводный камень

«Толстые» скиллы с bundled Python-скриптами (`ui-ux-pro-max`) или внешними ресурсами не переносятся 1-в-1 в Cursor / Codex / web — там нет механизма автозапуска вспомогательных скриптов. Чисто-инструкционные скиллы (`caveman`, `russian-titles`, `windows-shell`) переезжают без потерь.

## Для друзей

Если хочешь использовать эти скиллы:

```bash
git clone <url> ~/claude-skills
cd ~/claude-skills
./scripts/sync.sh     # или sync.ps1 на Windows
```

Хочешь добавить свой скилл / поправить чужой — форк, PR. Хочешь только себе локально — после `git clone` правь как хочешь, `git pull` будет работать пока не накосячишь с мержем.

Если нужны только некоторые скиллы:

```bash
./scripts/sync.sh --only diagnose,tdd,grill-me
```

## Список скиллов

См. содержимое `skills/`. Кратко по триггерам — в первой строке каждого `SKILL.md`.
