# Troubleshooting

Начните с диагностики — она ничего не меняет и сразу показывает проблему:

```bash
./scripts/doctor.sh
```

## uv не найден после установки

```text
bash: uv: command not found
```

Установщик кладёт бинарники в `~/.local/bin`, а текущий терминал этот путь ещё
не знает:

```bash
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
```

Чтобы не повторять, добавьте строку в `~/.bashrc` и откройте новый терминал.
Проверка: `uv --version`.

## «uv.lock устарел относительно pyproject.toml»

Вы изменили зависимости в `pyproject.toml`. Обновите lock-файл:

```bash
uv sync
```

В CI lock-файл не пересобирается (там `uv sync --frozen`), поэтому случайно
закоммитить рассинхронизированный lock нельзя.

## Нет доступа к сети

```text
error: Failed to fetch: `https://pypi.org/...`
```

Зависимости качаются один раз. Если они уже установлены, работать можно и без
сети — `uv run` и pytest обращаются к сети только при установке пакетов.
За корпоративным прокси помогает:

```bash
export HTTPS_PROXY=http://user:pass@proxy.example.com:3128
```

Кэш пакетов лежит в `~/.cache/uv`, его можно переносить между машинами.

## Нет места на диске

```bash
df -h .
uv cache prune        # почистить кэш пакетов
uv python uninstall 3.11   # убрать неиспользуемые версии Python
```

## `error: externally-managed-environment`

Вы попытались сделать `pip install` в системный Python. Не надо так: зависимости
ставятся только через `uv sync`, а запускаются через `uv run`. Системный
Python в проекте не участвует.

## VS Code подсвечивает ошибки, которых нет

Редактор смотрит на свой интерпретатор. Выберите `.venv/bin/python`
(`Python: Select Interpreter`) и включите расширения Ruff и Mypy — тогда
подсветка совпадёт с выводом инструментов.

## `pytest` не находит модуль `shop`

```text
ModuleNotFoundError: No module named 'shop'
```

Не установлены зависимости: `./scripts/setup.sh`. Пакет ставится в режиме
редактируемой установки, поэтому изменения в `src/shop` видны сразу.

## Линтер ругается на то, что не является ошибкой

Проверьте, не подавлена ли диагностика ранее: `grep -rn "noqa\|type: ignore" src tests`.
Если `noqa` стоит на месте, где вы ничего не отключали, — верните строку на место
и почините причину.

## Хочу начать с нуля

```bash
git status                 # посмотрите, что собираетесь потерять
git diff > /tmp/moi-work.txt   # сохранить черновик, если нужно
./scripts/reset.sh --force
```

Окружение `.venv` при этом не трогается.

## Хочу проверить, что именно запускает CI

```bash
./scripts/check.sh
```

Команды в `scripts/common.sh` совпадают с шагами в `.github/workflows/`.
Для локального запуска самих workflow нужен [act](https://github.com/nektos/act),
но он требует Docker — обычно достаточно `./scripts/check.sh`.
