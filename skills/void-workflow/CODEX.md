# Void Workflow — версия для Codex CLI (GPT под капотом)

Адаптация скилла `void-workflow` под **Codex CLI** (OpenAI, модели GPT-Codex). Логика пайплайна, гейты, правило артефактов и happy path — **те же, что в [SKILL.md](SKILL.md)**. Здесь только дельта механики под Codex.

## Куда положить и как активировать

Codex автоматически читает `AGENTS.md`. Вставь это правило в:
- `AGENTS.md` в корне проекта (или нужного пакета), **либо**
- `~/.codex/AGENTS.md` — глобально на все проекты.

Активация — кодовой фразой **«метод Void»** в чате: Codex видит правило в `AGENTS.md` и идёт по воркфлоу ниже. Авто-триггера по `description` (как у Claude-скиллов) у Codex нет — правило живёт в `AGENTS.md`, поэтому фразу обрабатывает именно загруженный `AGENTS.md`-блок.

Минимальный блок для `AGENTS.md`:

```md
## Метод Void (workflow разработки)
Когда пользователь говорит «метод Void» — веди разработку фичи по пайплайну
SpecKit + Superpowers: superb-check → specify → brainstorm/clarify/checklist →
plan → tasks → superb-review (gate) → implement (RED→GREEN→REFACTOR, последовательно)
→ superb-verify (gate) → critique/respond → finish.
Каждую команду — отдельным запуском Codex (свежий контекст). Нет команды — не выдумывай,
остановись и сообщи. Параллель — только независимые slice, каждый в своём git worktree
со своим инстансом приложения; потом merge в integration.
Полная версия — skills/void-workflow/CODEX.md.
```

## Что меняется против Claude-версии

### 1. «Свежий агент/субагент на команду» → новая сессия / `codex exec` на команду
У Codex **нет встроенного спавна субагентов** (как Task у Claude Code). Свежий и минимальный контекст обеспечивается так:
- каждую `$speckit-*` / `$speckit-superb-*` команду запускай в **отдельном запуске Codex** — новая интерактивная сессия, либо `codex exec "<команда> ..."` для скриптового прогона;
- между шагами **не тащи историю**; входы команда читает с диска (`spec.md`, `plan.md`, `tasks.md`, …);
- не дожимай несколько команд в одной сессии «за компанию» — это и есть накопление контекста, от которого уходим.

### 2. Параллель через worktree → несколько инстансов Codex
Харнесс worktree-изоляцию за тебя здесь **не делает**. Поэтому:
- `git worktree` создаёшь и убираешь **руками**;
- один worktree = **один отдельный инстанс Codex** в этом каталоге + свой инстанс приложения (свой порт/env/БД, для NUCEX — `just dev`);
- разные slice = разные деревья + разные инстансы Codex параллельно, сборка в `integration` по очереди.

### 3. «Нет команды — не выдумывай» (под Codex критичнее)
SpecKit ставит свои команды под Codex при инициализации с агентом `codex` (`specify init --ai codex`); **superb-слой может отсутствовать**. Если нужной `$speckit-*` / `$speckit-superb-*` команды на машине нет — **остановись и сообщи пользователю**, не имитируй её поведение.

### 4. GPT-специфика
- Держи шаги **явными и по чек-листу**; не перепрыгивай гейты `superb-review` и `superb-verify` без явного PASS.
- `implement` — строго task-by-task, RED → GREEN → REFACTOR, последовательно.
- Для воспроизводимых прогонов в CI/скриптах используй `codex exec` (неинтерактивно), интерактив — для исследовательских шагов.

## Пайплайн (тот же)

```
superb-check → specify → brainstorm → clarify (если надо) → checklist
  → plan → tasks → superb-review → analyze (опц.)
  → implement → superb-verify → critique (опц.) → respond (если надо) → finish
```

Обязательное/опциональное, два гейта и правило «параллель — только то, что не пишет/не читает один артефакт» — как в [SKILL.md](SKILL.md).

## Рецепт: per-slice worktree (Codex)

```bash
# 1. дерево под slice
git worktree add ../<repo>-slice-x -b slice/x
cd ../<repo>-slice-x

# 2. свой инстанс приложения (порт/env/БД). Команда — из AGENTS.md проекта;
#    для NUCEX канон:
PORT=3101 DATABASE_URL=postgres://.../slice_x  just dev

# 3. отдельный инстанс Codex в этом дереве; пайплайн slice — ПОСЛЕДОВАТЕЛЬНО,
#    каждая команда новым запуском:
codex                                   # интерактивно, шаг за шагом
#   или скриптом, по одной команде на запуск:
codex exec "$speckit-specify ..."
codex exec "$speckit-plan ..."
# ... → superb-review → implement → superb-verify → superb-finish

# 4. verify PASS + finish → сборка:
git switch integration && git merge --no-ff slice/x        # или PR

# 5. уборка
git worktree remove ../<repo>-slice-x && git branch -d slice/x
```

Разные `slice/x`, `slice/y` — разные деревья + разные инстансы Codex параллельно; сходятся в `integration` на шаге 4 по очереди.
