.PHONY: help setup check part1 part2 doctor tdd-history reset

help: ## список доступных целей
	@grep -E '^[a-z0-9-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

setup: ## установить uv, нужный Python и зависимости
	@./scripts/setup.sh

check: ## прогнать все проверки CI локально
	@./scripts/check.sh

part1: ## только часть 1: формат, линт, типы, тесты
	@./scripts/check-part1.sh

part2: ## только часть 2: тесты, покрытие, порядок TDD
	@./scripts/check-part2.sh

doctor: ## диагностика окружения
	@./scripts/doctor.sh

tdd-history: ## проверить, что тесты написаны раньше кода
	@uv run python scripts/check_tdd_history.py

reset: ## подсказка как вернуть дерево к последнему коммиту
	@echo "Это удалит все незакоммиченные изменения и новые файлы:"
	@echo "    ./scripts/reset.sh --force"
