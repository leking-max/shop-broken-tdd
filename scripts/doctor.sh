#!/usr/bin/env bash
# Диагностика окружения. Ничего не меняет: только показывает, что не так.
# Первое, что стоит запустить, если что-то ведёт себя неожиданно.
#
#   ./scripts/doctor.sh

set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
cd "$REPO_ROOT"

UV_MIN_VERSION="0.9.0"
declare -a RESULTS=()
FAILED_GATES=0

check() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    RESULTS+=("ok|$name")
    printf '  %sуспех%s  %s\n' "$C_GREEN" "$C_RESET" "$name"
  else
    RESULTS+=("fail|$name")
    FAILED_GATES=$((FAILED_GATES + 1))
    printf '  %sпровал%s %s\n' "$C_RED" "$C_RESET" "$name"
  fi
}

printf '%sДиагностика окружения%s\n' "$C_BOLD" "$C_RESET"
printf '%s%s%s\n\n' "$C_DIM" "$REPO_ROOT" "$C_RESET"

check "git установлен" command -v git
check "uv не старше $UV_MIN_VERSION" uv_at_least "$UV_MIN_VERSION"
check "Python $(cat .python-version) установлен через uv" \
  bash -c "uv python find '$(cat .python-version)'"
check "виртуальное окружение .venv существует" test -d .venv
check "uv.lock соответствует pyproject.toml" uv lock --check
check "ruff доступен в .venv" bash -c "uv run ruff --version"
check "mypy доступен в .venv" bash -c "uv run mypy --version"
check "pytest доступен в .venv" bash -c "uv run pytest --version"
check "проект импортируется (uv run python -c 'import shop')" \
  bash -c "uv run python -c 'import shop'"

printf '\n%sСостояние репозитория%s\n' "$C_BOLD" "$C_RESET"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '  ветка: %s\n' "$(git rev-parse --abbrev-ref HEAD)"
  printf '  коммитов: %s\n' "$(git rev-list --count HEAD 2>/dev/null || echo 0)"
  printf '  изменённых файлов: %s\n' "$(git status --porcelain | wc -l | tr -d ' ')"
else
  printf '  это не git-репозиторий\n'
fi
[ -d .venv ] && printf '  размер .venv: %s\n' "$(du -sh .venv 2>/dev/null | cut -f1)"

printf '\n%sСеть%s\n' "$C_BOLD" "$C_RESET"
if curl -sS --max-time 8 -o /dev/null https://pypi.org/simple/ 2>/dev/null; then
  printf '  pypi.org доступен\n'
else
  printf '  %spypi.org недоступен: uv не сможет качать зависимости%s\n' "$C_YELLOW" "$C_RESET"
  printf '  если зависимости уже установлены, работать можно и без сети\n'
fi

printf '\n'
if [ "$FAILED_GATES" -eq 0 ]; then
  printf '%sОкружение готово к работе.%s\n' "$C_GREEN" "$C_RESET"
  printf 'Следующий шаг: ./scripts/check.sh — увидеть красное состояние сборки\n'
  exit 0
fi

printf '%sПроблем: %s. Разбор — docs/troubleshooting.md%s\n' "$C_RED" "$FAILED_GATES" "$C_RESET"
exit 1
