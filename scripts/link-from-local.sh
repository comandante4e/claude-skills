#!/usr/bin/env bash
#
# Publisher-режим: делает ~/.claude/skills/ источником правды.
#
# Заменяет repo/skills/ на симлинк → ~/.claude/skills/. После этого
# правки в ~/.claude/skills/<имя>/SKILL.md сразу видны git-у в репо.
#
# Флаги:
#   --dry-run    показать план, ничего не менять
#   --force      если repo/skills/ это реальная папка — переименовать в бэкап и заменить
#
# Примеры:
#   ./scripts/link-from-local.sh --dry-run
#   ./scripts/link-from-local.sh --force

set -euo pipefail

DRY_RUN=0
FORCE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --force) FORCE=1; shift ;;
        -h|--help) sed -n '3,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Неизвестный флаг: $1" >&2; exit 2 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_REPO="$REPO_ROOT/skills"
SKILLS_LOCAL="$HOME/.claude/skills"

if [[ -t 1 ]]; then
    C_CYAN=$'\033[36m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
    C_MAGENTA=$'\033[35m'; C_RST=$'\033[0m'
else
    C_CYAN=""; C_GREEN=""; C_YELLOW=""; C_MAGENTA=""; C_RST=""
fi

if [[ ! -d "$SKILLS_LOCAL" ]]; then
    echo "Нет $SKILLS_LOCAL. На этой машине пока нет локальных скиллов — используй sync.sh (consumer-режим)." >&2
    exit 1
fi

if [[ -e "$SKILLS_REPO" || -L "$SKILLS_REPO" ]]; then
    if [[ -L "$SKILLS_REPO" ]]; then
        current="$(readlink "$SKILLS_REPO")"
        if [[ "$current" == "$SKILLS_LOCAL" ]]; then
            echo "${C_GREEN}Уже в publisher-режиме: $SKILLS_REPO → $current${C_RST}"
            exit 0
        fi
        echo "${C_YELLOW}skills/ существует как симлинк → $current${C_RST}"
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "${C_YELLOW}[dry-run] пересоздал бы симлинк → $SKILLS_LOCAL${C_RST}"
            exit 0
        fi
        rm "$SKILLS_REPO"
        ln -s "$SKILLS_LOCAL" "$SKILLS_REPO"
        echo "${C_GREEN}Пересоздал симлинк $SKILLS_REPO → $SKILLS_LOCAL${C_RST}"
        exit 0
    fi

    if [[ $FORCE -ne 1 ]]; then
        echo "${C_YELLOW}skills/ существует как реальная папка. Используй --force чтобы переименовать в бэкап и заменить симлинком.${C_RST}"
        exit 1
    fi

    backup="$SKILLS_REPO.backup-$(date +%Y%m%d-%H%M%S)"
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "${C_YELLOW}[dry-run] переименовал бы $SKILLS_REPO → $backup и создал симлинк → $SKILLS_LOCAL${C_RST}"
        exit 0
    fi
    mv "$SKILLS_REPO" "$backup"
    echo "${C_MAGENTA}Бэкап: $backup${C_RST}"
fi

if [[ $DRY_RUN -eq 1 ]]; then
    echo "${C_YELLOW}[dry-run] создал бы симлинк $SKILLS_REPO → $SKILLS_LOCAL${C_RST}"
    exit 0
fi

ln -s "$SKILLS_LOCAL" "$SKILLS_REPO"
echo "${C_GREEN}Создал симлинк $SKILLS_REPO → $SKILLS_LOCAL${C_RST}"
echo ""
echo "${C_CYAN}Дальше:${C_RST}"
echo "  git status      # проверить что чисто (или увидеть локальные изменения)"
echo "  git add -A"
echo "  git commit -m '...'"
echo "  git push"
