---
name: void-workflow
description: Оркестрация разработки фичи через SpecKit + Superpowers (speckit-команды). КЛЮЧЕВАЯ ФРАЗА АКТИВАЦИИ — «метод Void» (Void method, «по методу Void», «погнали по методу Void»): как только пользователь её произносит, запускай этот скилл. Также используй, когда пользователь разрабатывает фичу/эпик/bounded slice на этом пайплайне, спрашивает «какую speckit-команду звать дальше», в каком порядке идут specify/plan/tasks/implement/verify, что обязательно а что опционально, можно ли параллелить, или просит провести его по воркфлоу разработки. Проводит через 8 фаз: superb-check → specify → brainstorm/clarify/checklist → plan → tasks → superb-review (главный planning gate) → implement (строго RED→GREEN→REFACTOR, последовательно) → superb-verify (обязательный completion gate) → critique/respond → finish. Ключевое правило: каждая команда запускается НОВЫМ агентом/субагентом со свежим минимальным контекстом; параллелить можно, но аккуратно — команды создают/читают артефакты на диске (напр. critique→файл→respond), зависимые шаги дают конфликты; implement всегда последовательный.
---

# Void Workflow — оркестрация разработки через SpecKit + Superpowers

Пайплайн разработки фичи поверх **SpecKit** (`$speckit-*`) и **Superpowers / superb** (`$speckit-superb-*`). Скилл — не исполнитель, а дирижёр: он держит правильный порядок команд, гейты и правила параллелизма. Сами `$speckit-*` команды делают работу.

> **Кодовая фраза активации — «метод Void».** Услышал её («метод Void», «по методу Void», «погнали по методу Void») — запускай этот скилл. Альтернативно: слэш-команда `/void-workflow` (после `sync` в `~/.claude/skills/`).

## Два нерушимых правила

1. **Свежий и минимальный контекст на каждую команду.** Каждая `$speckit-*` / `$speckit-superb-*` команда запускается **новым агентом/субагентом со свежим контекстом**. Субагенту дают **минимальный промпт** — какую команду выполнить и над каким slice/артефактом, без пересказа всей истории: сами команды читают нужные входы (`spec.md`, `plan.md`, `tasks.md`, …) с диска. Субагент по умолчанию и так не видит родительский диалог — он получает только переданный промпт; задача не «чистить» контекст, а **не засорять этот промпт** лишним. Не тяни накопленный контекст из шага в шаг — это размывает спеку и плодит дрейф.
2. **Implement — последовательный.** `$speckit-implement` идёт строго task-by-task, RED → GREEN → REFACTOR. Остальное параллелить можно, но **аккуратно** — см. «Параллелизм».

## Два уровня спеки

- **Базовая спека** — `docs/tech/*` + `docs/prd.md`, делится на эпики. Делается один раз на проект (попутно — `grill-me` / `grill-with-docs` из [mattpocock/skills](https://github.com/mattpocock/skills)). Обычно уже готова к старту фич.
- **Спека под фичу** — каждый эпик прогоняется через SpecKit + superb, формируя спеку под конкретный эпик, которую и имплементируешь. Это и есть цикл ниже.

## Параллелизм — аккуратно

Это **не** «всё кроме implement». Команды **создают и читают артефакты на диске**, между ними есть зависимости по данным — параллельный запуск зависимых шагов даёт конфликты (гонка за один файл).

- ✅ **Независимые единицы** — разные slice / эпики со своими каталогами артефактов: параллелятся свободно. `grill-me` тоже.
- ⚠️ **Зависимые по артефактам шаги одного slice — НЕ параллелить.** Писатель должен закончить раньше, чем стартует читатель того же файла. Пример: `$speckit-superb-critique` складывает правки в конкретный файл, а `$speckit-superb-respond` читает именно его → конфликт. Такую пару гоняем последовательно.
- ❌ `$speckit-implement` — всегда последовательно, task-by-task (RED → GREEN → REFACTOR).

Правило, которое проще держать в голове: **параллель — только то, что не пишет и не читает один и тот же артефакт.**

## Конвейер — 8 фаз

### 1. Перед новой фичей — `$speckit-superb-check`
- **Когда:** после bootstrap/setup; после изменений в `.agents/skills`, `.specify`, `bridge/hooks`.
- **Зачем:** убедиться, что SpecKit + Superpowers реально готовы. Зовётся периодически.

### 2. Создание spec — `$speckit-specify`
- **Когда:** старт нового bounded slice.
- **Результат:** `spec.md`.

### 3. Уточнение spec (опционально, но часто полезно)
- `$speckit-superb-brainstorm` — сразу после specify, если slice архитектурно важный (почти всегда полезно). Результат: refinement `spec.md`.
- `$speckit-clarify` — если после specify/brainstorm остались **реальные** ambiguity. Скип, если decisions уже жёстко зафиксированы.
- `$speckit-checklist` — после стабилизации spec. Проверка completeness/clarity требований.

### 4. Планирование
- `$speckit-plan` — когда spec понятен. Результат: `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`.
- `$speckit-tasks` — после plan. Результат: `tasks.md`.

### 5. Проверка planning-пакета — `$speckit-superb-review` 🚦 главный planning gate
- **Когда:** сразу после tasks.
- **Зачем:** coverage spec → tasks, TDD readiness, поймать gaps **до** имплементации.
- `$speckit-analyze` (опционально) — после зелёного review: non-destructive consistency check между `spec.md` / `plan.md` / `tasks.md`. Не обязателен, если review уже жёсткий.

### 6. Реализация — `$speckit-implement`
- **Когда:** только после review PASS.
- **Что происходит:** идёшь по `tasks.md`, строго **RED → GREEN → REFACTOR**, task-by-task. Последовательно.
- `$speckit-superb-tdd` — формально pre-implement gate. Вручную обычно не нужен (implement flow это учитывает); зови только если хочешь дополнительный TDD-гейт до старта.

### 7. После реализации — `$speckit-superb-verify` 🚦 обязательный completion gate
- **Когда:** сразу после завершения имплементации.
- **Зачем:** full repo gates, spec verification checklist, evidence archive, статус → Verified.
- `$speckit-superb-critique` (опционально) — независимый spec-aligned review: ловит отклонения кода от spec/plan/tasks.
- `$speckit-superb-respond` — если critique (или другой review) нашёл проблемы: аккуратно обработать feedback, **не чинить вслепую**.

### 8. Закрытие slice — `$speckit-superb-finish`
- **Когда:** только после успешного verify.
- **Зачем:** закрыть dev-branch flow; выбрать merge / PR / keep / discard.

## Нормальный путь (happy path)

```
superb-check → specify → brainstorm → clarify (если надо) → checklist
  → plan → tasks → superb-review → analyze (опц.)
  → implement → superb-verify → critique (опц.) → respond (если надо) → finish
```

## Обязательно vs опционально

**Обязательно / почти обязательно:**
`superb-check` (периодически) · `specify` · `plan` · `tasks` · `superb-review` · `implement` · `superb-verify` · `superb-finish`

**Опционально, но часто полезно:**
`superb-brainstorm` · `clarify` · `checklist` · `analyze` · `superb-critique` · `superb-respond`

## При активации

1. Пойми, на какой фазе пользователь, и какой артефакт уже есть (`spec.md` / `plan.md` / `tasks.md`).
2. Назови следующую команду из happy path и **запусти её новым агентом/субагентом** с минимальным промптом (какая команда + над каким slice/артефактом), без пересказа истории.
3. Не проходи сквозь гейты (`superb-review`, `superb-verify`) без явного PASS.
4. На `implement` — не параллель, иди task-by-task RED→GREEN→REFACTOR.
5. Если slice несколько — параллель **только независимые** (свои каталоги артефактов). Зависимые по файлам шаги (напр. critique→respond) — последовательно.
