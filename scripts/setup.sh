#!/usr/bin/env bash
# Готовит рабочее окружение: uv, нужная версия Python и зависимости проекта.
#
#   ./scripts/setup.sh           установка и проверка
#   ./scripts/setup.sh --check   только проверка, ничего не устанавливает (режим CI)
#
# Скрипт идемпотентен: его можно запускать повторно.

set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
cd "$REPO_ROOT"

CHECK_ONLY=0
UV_MIN_VERSION="0.9.0"
INSTALL_SCRIPT="https://astral.sh/uv/install.sh"

usage() {
  cat <<'USAGE'
Использование: ./scripts/setup.sh [--check]

  (без аргументов)  установить uv и зависимости, если их ещё нет
  --check           ничего не устанавливать, только проверить и выйти с кодом 0 или 1
USAGE
}

case "${1:-}" in
  --check) CHECK_ONLY=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  "") ;;
  *) usage >&2
    die "Неизвестный аргумент: $1"
    ;;
esac

info "Python, который требуется проекту: $(cat .python-version)"
info "Минимальная версия uv: $UV_MIN_VERSION"

# ---------------------------------------------------------------------------
# 1. uv
# ---------------------------------------------------------------------------
if ! command -v uv >/dev/null 2>&1; then
  if [ "$CHECK_ONLY" -eq 1 ]; then
    die "uv не установлен. Выполните: ./scripts/setup.sh"
  fi
  info "uv не найден, устанавливаю официальным установщиком"
  need_cmd curl "Установите curl: sudo apt install -y curl"
  curl -LsSf "$INSTALL_SCRIPT" | sh
  # Установщик кладёт бинарники сюда; добавляем в PATH для текущего процесса.
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
  command -v uv >/dev/null 2>&1 || die "Установщик отработал, но uv в PATH не появился. Откройте новый терминал и повторите."
  warn "Если новый терминал всё ещё не видит uv, добавьте строку в ~/.bashrc:"
  warn "    export PATH=\"\$HOME/.local/bin:\$PATH\""
else
  info "uv уже установлен: $(uv --version)"
fi

uv_at_least "$UV_MIN_VERSION" || die "Нужен uv $UV_MIN_VERSION или новее. Обновите: uv self update"

# ---------------------------------------------------------------------------
# 2. Python нужной версии
# ---------------------------------------------------------------------------
if [ "$CHECK_ONLY" -eq 1 ]; then
  uv python find "$(cat .python-version)" >/dev/null 2>&1 ||
    die "Python $(cat .python-version) не найден. Выполните: ./scripts/setup.sh"
  info "Python $(cat .python-version) доступен"
else
  info "Ставлю Python $(cat .python-version) через uv (системный Python не трогаем)"
  uv python install "$(cat .python-version)"
fi

# ---------------------------------------------------------------------------
# 3. Зависимости и виртуальное окружение
# ---------------------------------------------------------------------------
if [ "$CHECK_ONLY" -eq 1 ]; then
  uv lock --check >/dev/null 2>&1 || die "uv.lock устарел относительно pyproject.toml. Выполните: uv sync"
  info "uv.lock актуален"
else
  info "Создаю .venv и ставлю зависимости"
  uv sync
fi

[ -d .venv ] || die "Каталог .venv не создан. Выполните: ./scripts/setup.sh"

# ---------------------------------------------------------------------------
# 4. Проверка инструментов
# ---------------------------------------------------------------------------
info "Инструменты внутри .venv:"
uv run ruff --version | sed 's/^/    /'
uv run mypy --version | sed 's/^/    /'
uv run pytest --version | sed 's/^/    /'
uv run python --version | sed 's/^/    /'

printf '\n%sГотово.%s Дальше:\n' "$C_GREEN" "$C_RESET"
printf '  ./scripts/check.sh   — прогнать все проверки (сейчас будет красным, это нормально)\n'
printf '  ./scripts/doctor.sh  — диагностика окружения, если что-то не так\n'
printf '  README.md            — о проекте и с чего начать\n'
