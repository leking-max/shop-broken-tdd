#!/usr/bin/env bash
# Возвращает рабочее дерево к состоянию последнего коммита.
# Нужен, чтобы переделать часть 1 с нуля или начать лабораторную заново.
#
#   ./scripts/reset.sh --force
#
# ВНИМАНИЕ: все незакоммиченные изменения и новые файлы будут удалены.

set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
cd "$REPO_ROOT"

if [ "${1:-}" != "--force" ]; then
  cat <<'USAGE'
Использование: ./scripts/reset.sh --force

  Удалит все незакоммиченные изменения и новые файлы.
  В .venv, кэшах и в файлах, которые уже закоммичены, изменений не будет.
USAGE
  exit 2
fi

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Это не git-репозиторий"

unpushed="$(git log --oneline --branches --not --remotes 2>/dev/null || true)"
if [ -n "$unpushed" ]; then
  warn "Есть коммиты, которых нет ни в одном удалённом репозитории:"
  printf '%s\n' "$unpushed" | sed 's/^/    /' >&2
  warn "Если это ваша работа, сначала сделайте форк или git push"
fi

dirty="$(git status --porcelain)"
if [ -n "$dirty" ]; then
  warn "Будет удалено:"
  printf '%s\n' "$dirty" | sed 's/^/    /' >&2
fi

git reset --hard HEAD >/dev/null
git clean -fd >/dev/null

printf '%sРабочее дерево возвращено к последнему коммиту.%s\n' "$C_GREEN" "$C_RESET"
printf 'Окружение (.venv) не тронуто. Проверить состояние: ./scripts/check.sh\n'
