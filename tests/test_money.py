"""Money helpers are the reference implementation: these tests are green from the start.

If a test from this file fails, something fundamental is broken - start debugging here.
"""

from shop.money import format_kopecks, percent_of


def test_format_kopecks_of_zero() -> None:
    assert format_kopecks(0) == "0.00"


def test_format_kopecks_pads_cents() -> None:
    assert format_kopecks(1990) == "19.90"
    assert format_kopecks(5) == "0.05"
    assert format_kopecks(50_000) == "500.00"


def test_format_kopecks_keeps_sign() -> None:
    assert format_kopecks(-1990) == "-19.90"


def test_percent_of_rounds_half_up() -> None:
    assert percent_of(1000, 10) == 100
    assert percent_of(1055, 10) == 106
    assert percent_of(1054, 10) == 105


def test_percent_of_large_amount() -> None:
    assert percent_of(500_000, 20) == 100_000
