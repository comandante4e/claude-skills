#!/usr/bin/env bash
#
# Раскладывает симлинки из skills/<name> в ~/.claude/skills/<name>.
#
# Флаги:
#   --dry-run         показать, ничего не менять
#   --force           заменить реальные папки (с бэкапом)
#   --only a,b,c      только эти скиллы
#
# Примеры:
#   ./scripts/sync.sh
#   ./scripts/sync.sh --dry-run
#   ./scripts/sync.sh --force --only caveman,tdd

set -euo pipefail

DRY_RUN=0
FORCE=0
ONLY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --force) FORCE=1; shift ;;
        --only) ONLY="$2"; shift 2 ;;
        --only=*) ONLY="${1#*=}"; shift ;;
        -h|--help)
            sed -n '3,15p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "Неизвестный флаг: $1" >&2; exit 2 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_SRC="$REPO_ROOT/skills"
SKILLS_DST="$HOME/.claude/skills"

# Цвета
if [[ -t 1 ]]; then
    C_CYAN=$'\033[36m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
    C_RED=$'\033[31m'; C_MAGENTA=$'\033[35m'; C_GRAY=$'\033[90m'; C_RST=$'\033[0m'
else
    C_CYAN=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_MAGENTA=""; C_GRAY=""; C_RST=""
fi

if [[ ! -d "$SKILLS_SRC" ]]; then
    echo "Не найдена папка $SKILLS_SRC. Запускай из клонированного репо." >&2
    exit 1
fi

# Предохранитель: если skills/ это симлинк — мы в publisher-режиме, sync.sh не применим
if [[ -L "$SKILLS_SRC" ]]; then
    target="$(readlink "$SKILLS_SRC")"
    echo "skills/ это симлинк → $target. Похоже, мы в publisher-режиме. sync.sh не применим. Используй link-from-local.sh или удали симлинк вручную." >&2
    exit 1
fi

if [[ ! -d "$SKILLS_DST" ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "${C_YELLOW}[dry-run] создал бы $SKILLS_DST${C_RST}"
    else
        mkdir -p "$SKILLS_DST"
        echo "${C_GREEN}Создал $SKILLS_DST${C_RST}"
    fi
fi

declare -A ONLY_SET=()
if [[ -n "$ONLY" ]]; then
    IFS=',' read -ra parts <<< "$ONLY"
    for p in "${parts[@]}"; do
        ONLY_SET["${p// /}"]=1
    done
fi

created=0
replaced=0
skipped=0
backed_up=0
errors=0

for src_dir in "$SKILLS_SRC"/*/; do
    [[ -d "$src_dir" ]] || continue
    name="$(basename "$src_dir")"
    src="${src_dir%/}"
    dst="$SKILLS_DST/$name"

    if [[ ${#ONLY_SET[@]} -gt 0 && -z "${ONLY_SET[$name]:-}" ]]; then
        continue
    fi

    echo ""
    echo "${C_CYAN}[$name]${C_RST}"

    if [[ -L "$dst" ]]; then
        current="$(readlink "$dst")"
        if [[ "$current" == "$src" ]]; then
            echo "  ${C_GRAY}уже синкнут (симлинк → $src)${C_RST}"
            skipped=$((skipped + 1))
            continue
        fi
        echo "  ${C_YELLOW}существует симлинк → $current${C_RST}"
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "  ${C_YELLOW}[dry-run] пересоздал бы симлинк → $src${C_RST}"
            continue
        fi
        rm "$dst"
        ln -s "$src" "$dst"
        echo "  ${C_GREEN}пересоздал симлинк → $src${C_RST}"
        replaced=$((replaced + 1))
        continue
    fi

    if [[ -d "$dst" ]]; then
        if [[ $FORCE -ne 1 ]]; then
            echo "  ${C_YELLOW}существует реальная папка. Пропускаю (используй --force чтобы заменить с бэкапом).${C_RST}"
            skipped=$((skipped + 1))
            continue
        fi
        backup="$dst.backup-$(date +%Y%m%d-%H%M%S)"
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "  ${C_YELLOW}[dry-run] переименовал бы в $backup и создал симлинк → $src${C_RST}"
            continue
        fi
        mv "$dst" "$backup"
        echo "  ${C_MAGENTA}бэкап: $backup${C_RST}"
        backed_up=$((backed_up + 1))
        ln -s "$src" "$dst"
        echo "  ${C_GREEN}создал симлинк → $src${C_RST}"
        created=$((created + 1))
        continue
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  ${C_YELLOW}[dry-run] создал бы симлинк $dst → $src${C_RST}"
        continue
    fi

    if ln -s "$src" "$dst"; then
        echo "  ${C_GREEN}создал симлинк → $src${C_RST}"
        created=$((created + 1))
    else
        echo "  ${C_RED}ошибка${C_RST}"
        errors=$((errors + 1))
    fi
done

echo ""
echo "${C_CYAN}Итого:${C_RST}"
echo "  создано:    $created"
echo "  пересоздано: $replaced"
echo "  пропущено:  $skipped"
echo "  бэкапов:    $backed_up"
echo "  ошибок:     $errors"

if [[ $DRY_RUN -eq 1 ]]; then
    echo ""
    echo "${C_YELLOW}Это был dry-run. Запусти без --dry-run чтобы применить.${C_RST}"
fi
