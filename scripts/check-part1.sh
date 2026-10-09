#!/usr/bin/env bash
# Только часть 1: форматирование, линт, типы и тесты части 1.
# Полный набор тестов (включая часть 2) гоняют ./scripts/check-part2.sh и check.sh.
# Годится для быстрого цикла «починил — прогнал».
#
#   ./scripts/check-part1.sh

set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
cd "$REPO_ROOT"

gate_format
gate_lint
gate_types
gate_part1_tests

print_summary "Итог: часть 1 (красный CI)"
summary_exit_code || exit 1
