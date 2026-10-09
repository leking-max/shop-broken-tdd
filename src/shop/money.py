"""Money helpers.

Every amount in this project is an integer amount of kopecks: 1 ruble = 100 kopecks.
Never use floats for money, 0.1 + 0.2 != 0.3 in binary floating point.
"""

KOPEKS_IN_RUBBLE = 100


def format_kopecks(value: int) -> str:
    """Render an integer amount of kopecks as a decimal ruble string.

    >>> format_kopecks(1990)
    '19.90'
    """
    sign = "-" if value < 0 else ""
    absolute = abs(value)
    return f"{sign}{absolute // KOPEKS_IN_RUBBLE}.{absolute % KOPEKS_IN_RUBBLE:02d}"


def percent_of(amount: int, percent: int) -> int:
    """Return `percent` percent of a non-negative `amount`, rounded half up.

    Only integer arithmetic is used, so the result is exact.

    >>> percent_of(1055, 10)
    106
    """
    return (amount * percent + 50) // KOPEKS_IN_RUBBLE
