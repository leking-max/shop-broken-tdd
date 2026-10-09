#!/usr/bin/env bash
# Только часть 2: тесты расчёта заказа, порог покрытия и порядок TDD.
# Запускайте часто: это быстрый цикл RED -> GREEN -> REFACTOR.
#
#   ./scripts/check-part2.sh

set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
cd "$REPO_ROOT"

gate_checkout_tests
gate_tdd_history

print_summary "Итог: часть 2 (TDD + агент)"
summary_exit_code || exit 1
