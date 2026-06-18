# claude-skills

Личная коллекция скиллов для Claude Code. Шарится между моими машинами и с друзьями через симлинки/junction-ы из этого репо в `~/.claude/skills/`.

## Что внутри

Папка `skills/` — каждый подкаталог это один скилл (формат [Anthropic Skills](https://github.com/anthropics/skills): `SKILL.md` с YAML-фронтматтером + опциональные ресурсы).

Папка `scripts/`:
- `sync.{ps1,sh}` — **consumer-режим**: репо это источник правды, в `~/.claude/skills/<имя>` создаются junction-ы / симлинки на репо. Для свежих машин и друзей.
- `link-from-local.{ps1,sh}` — **publisher-режим**: `~/.claude/skills/` остаётся источником правды, в репо `skills/` подменяется на junction → `~/.claude/skills/`. Для машины, где уже наработан локальный набор скиллов и его нельзя трогать.

## Два режима

```
consumer (для друзей, свежих машин)        publisher (для машины с уже наработанными скиллами)

  repo/skills/<X>     ← реальные файлы       repo/skills/         ← junction
        ▲                                            │
        │ junction                                    ▼
  ~/.claude/skills/<X>                       ~/.claude/skills/<X>  ← реальные файлы
```

В **consumer-режиме** правки делаются в `~/.claude/skills/<X>/...`, но физически правят файлы в репо (через junction). `git push` отправляет на GitHub.

В **publisher-режиме** правки делаются в `~/.claude/skills/<X>/...` напрямую, и через единый junction `repo/skills` git видит их в репо. `git push` отправляет на GitHub.

Снаружи (на GitHub) оба режима выглядят одинаково — реальные файлы в `skills/<имя>/`.

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

### Publisher-режим (на машине с уже наработанными скиллами)

Если на машине уже есть `~/.claude/skills/<...>` и менять их не хочется, а в репо нужно складывать те же файлы:

```powershell
# Windows
git clone https://github.com/comandante4e/claude-skills.git $HOME\claude-skills
cd $HOME\claude-skills
.\scripts\link-from-local.ps1 -Force
```

```bash
# macOS / Linux
git clone https://github.com/comandante4e/claude-skills.git ~/claude-skills
cd ~/claude-skills
./scripts/link-from-local.sh --force
```

После этого `repo/skills/` — это junction / симлинк на `~/.claude/skills/`, и обычный `git add -A && git commit -m '...' && git push` отправит локальные правки на GitHub.

> **Важно:** в publisher-режиме `sync.{ps1,sh}` намеренно откажется работать — он определит, что `skills/` это симлинк/junction, и попросит использовать `link-from-local` вместо себя.

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

### void-workflow

Оркестрация разработки фичи поверх **SpecKit** (`$speckit-*`) и **Superpowers / superb** (`$speckit-superb-*`). Скилл — не исполнитель, а дирижёр: держит правильный порядок команд, гейты и правила параллелизма, а саму работу делают `$speckit-*` команды.

Проводит через 8 фаз: `superb-check` → `specify` → `brainstorm` / `clarify` / `checklist` → `plan` → `tasks` → `superb-review` (🚦 главный planning gate) → `implement` (строго RED → GREEN → REFACTOR, последовательно) → `superb-verify` (🚦 обязательный completion gate) → `critique` / `respond` → `finish`. Различает обязательные и опциональные шаги, описывает happy path и два уровня спеки (базовая `docs/tech` + `docs/prd.md` → спека под конкретный эпик).

Два нерушимых правила: каждая команда запускается **новым агентом/субагентом с минимальным промптом** (входы команды читаются с диска, историю не пересказываем); `implement` — всегда последовательный, а остальное параллелится **аккуратно** — команды создают/читают артефакты, и зависимые шаги (напр. `critique`→`respond`) конфликтуют за общий файл. Независимые slice изолируют через `git worktree` (в идеале + свой инстанс приложения на дерево) и потом собирают в одну ветку.

**Как вызвать:** кодовая фраза **«метод Void»** (`метод Void`, `по методу Void`, `погнали по методу Void`) — по ней скилл активируется автоматически. Либо слэш-команда `/void-workflow` (после `./scripts/sync.sh`).

Триггеры: разработка фичи/эпика/bounded slice на этом пайплайне, вопросы «какую speckit-команду звать дальше», «в каком порядке specify/plan/tasks/implement/verify», «что обязательно, а что опционально», «можно ли параллелить», просьба провести по воркфлоу разработки. Источник — Notion «Расписать воркфлоу разработки Void».

Версия под **Codex CLI** (GPT под капотом) — `skills/void-workflow/CODEX.md`: тот же пайплайн, но с поправкой на механику Codex (нет нативных субагентов и harness-worktree — отдельные сессии / `codex exec` на команду, отдельные инстансы Codex на worktree, правило кладётся в `AGENTS.md`).
