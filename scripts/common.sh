#!/usr/bin/env bash
# Общие помощники для скриптов репозитория. Подключается через `source`.
# Не запускается сам по себе.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
else
  C_RESET=""
  C_BOLD=""
  C_DIM=""
  C_RED=""
  C_GREEN=""
  C_YELLOW=""
fi

info() { printf '%s==>%s %s\n' "$C_DIM" "$C_RESET" "$*"; }
warn() { printf '%s[внимание]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
fail() { printf '%s[ошибка]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die() {
  fail "$*"
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Не найдена команда '$1'. $2"
}

# Версия uv в PATH не ниже $1 (сравнение как в sort -V).
uv_at_least() {
  local wanted="$1" current
  current="$(uv --version 2>/dev/null | awk '{print $2}')" || return 1
  [ -n "$current" ] || return 1
  [ "$(printf '%s\n%s\n' "$wanted" "$current" | sort -V | head -n 1)" = "$wanted" ]
}

# Результаты проверок для сводки в конце скрипта.
declare -a RESULTS=()
FAILED_GATES=0

run_step() {
  local name="$1"
  shift
  printf '\n%s=== %s ===%s\n' "$C_BOLD" "$name" "$C_RESET"
  printf '%s$ %s%s\n' "$C_DIM" "$*" "$C_RESET"
  if "$@"; then
    RESULTS+=("ok|$name")
  else
    RESULTS+=("fail|$name")
    FAILED_GATES=$((FAILED_GATES + 1))
  fi
}

print_summary() {
  local title="${1:-Итог}"
  printf '\n%s%s%s\n' "$C_BOLD" "$title" "$C_RESET"
  local row status name
  for row in "${RESULTS[@]:-}"; do
    status="${row%%|*}"
    name="${row#*|}"
    if [ "$status" = "ok" ]; then
      printf '  %sуспех%s  %s\n' "$C_GREEN" "$C_RESET" "$name"
    else
      printf '  %sпровал%s %s\n' "$C_RED" "$C_RESET" "$name"
    fi
  done
  if [ "$FAILED_GATES" -eq 0 ]; then
    printf '\n%sВсе проверки зелёные.%s\n' "$C_GREEN" "$C_RESET"
  else
    printf '\n%sПровалено проверок: %s.%s\n' "$C_RED" "$FAILED_GATES" "$C_RESET"
  fi
}

summary_exit_code() {
  [ "$FAILED_GATES" -eq 0 ]
}

# Проверки, общие для всех скриптов. Каждая запускает ровно одну команду из CI.
gate_format() { run_step "Форматирование (ruff format)" uv run ruff format --check .; }
gate_lint() { run_step "Линт (ruff check)" uv run ruff check .; }
gate_types() { run_step "Типы (mypy)" uv run mypy src tests; }
gate_tests() { run_step "Тесты (pytest)" uv run pytest; }

# Тесты части 1. Smoke-тест части 2 заведомо красный, поэтому в первой части он
# не проверяется: полный набор всегда гоняет check.sh и джоба part2-ci.
gate_part1_tests() {
  run_step "Тесты (pytest, часть 1)" \
    uv run pytest tests/test_money.py tests/test_inventory.py tests/test_reporting.py
}
gate_checkout_tests() {
  run_step "Тесты расчёта заказа + покрытие >= 90%" \
    uv run pytest tests/test_checkout.py \
    --cov=shop.checkout --cov-report=term-missing --cov-fail-under=90
}
gate_tdd_history() { run_step "Порядок TDD (тесты раньше кода)" uv run python scripts/check_tdd_history.py; }
