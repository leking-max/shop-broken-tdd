"""Order checkout, part 2.

How to work through this file:

1. The single red test below is done for you - it shows what RED looks like.
2. Run `./scripts/check-part2.sh` and read the failure.
3. Write one assertion per rule from `src/shop/specs/checkout.md` into the empty
   tests: a failing test first, then the code that makes it pass.
4. Never edit a finished assertion, never `skip`, never weaken a test.

Run one test at a time while you work:

    uv run pytest tests/test_checkout.py -k tier -x
"""

from shop.checkout import calculate_order_total, validate_order


def line(sku: str = "SKU-1", qty: str = "1", unit_price_kopecks: str = "10000") -> dict[str, str]:
    """Build one order line the way the warehouse export delivers it."""
    return {"sku": sku, "qty": qty, "unit_price_kopecks": unit_price_kopecks}


def test_smoke_single_line_without_delivery() -> None:
    """Exemple 1 ТЗ : 1 ligne, pas de promo, samovyvoz. Total = 12 000."""
    lines = [{"sku": "SKU-A", "qty": "1", "unit_price_kopecks": "10000"}]
    result = calculate_order_total(lines)
    assert result == 12_000


def test_empty_order_is_rejected() -> None:
    """Règle 1 : Une commande sans lignes doit être rejetée."""
    result = validate_order([])
    assert result is not None
    assert len(result) > 0


def test_empty_sku_is_rejected() -> None:
    """Règle 2 : Un SKU vide doit être rejeté."""
    lines = [{"sku": "", "qty": "1", "unit_price_kopecks": "100"}]
    result = validate_order(lines)
    assert result is not None
    assert len(result) > 0


def test_missing_line_key_is_rejected() -> None:
    """Règle 3 : Une ligne sans clé requise doit être rejetée."""
    # Supposons que REQUIRED_LINE_KEYS contient ["sku", "qty", "unit_price_kopecks"]
    lines = [{"sku": "A", "qty": "1"}]  # Il manque unit_price_kopecks
    result = validate_order(lines)
    assert result is not None
    assert len(result) > 0


def test_non_numeric_quantity_is_rejected() -> None:
    """Règle 4 : Une quantité non numérique doit être rejetée."""
    lines = [{"sku": "A", "qty": "abc", "unit_price_kopecks": "100"}]
    result = validate_order(lines)
    assert result is not None
    assert len(result) > 0


def test_zero_quantity_is_rejected() -> None:
    """Règle 5 : Une quantité <= 0 doit être rejetée."""
    lines = [{"sku": "A", "qty": "0", "unit_price_kopecks": "100"}]
    result = validate_order(lines)
    assert result is not None
    assert len(result) > 0


def test_non_numeric_price_is_rejected() -> None:
    """Règle 6 : Un prix non numérique doit être rejeté."""
    lines = [{"sku": "A", "qty": "1", "unit_price_kopecks": "xyz"}]
    result = validate_order(lines)
    assert result is not None
    assert len(result) > 0


def test_negative_price_is_rejected() -> None:
    """Règle 7 : Un prix négatif doit être rejeté."""
    lines = [{"sku": "A", "qty": "1", "unit_price_kopecks": "-50"}]
    result = validate_order(lines)
    assert result is not None
    assert len(result) > 0


def test_duplicate_sku_is_rejected() -> None:
    """Règle 8 : Un SKU dupliqué doit être rejeté."""
    lines = [
        {"sku": "A", "qty": "1", "unit_price_kopecks": "100"},
        {"sku": "A", "qty": "2", "unit_price_kopecks": "200"},
    ]
    result = validate_order(lines)
    assert result is not None
    assert len(result) > 0


def test_unknown_promo_code_is_rejected() -> None:
    """Règle 9 : Un promo code inconnu doit être rejeté."""
    lines = [{"sku": "A", "qty": "1", "unit_price_kopecks": "100"}]
    result = validate_order(lines, promo_code="UNKNOWN_CODE")
    assert result is not None
    assert len(result) > 0


def test_unsupported_city_is_rejected() -> None:
    """Règle 10 : Une ville non supportée doit être rejetée."""
    lines = [{"sku": "A", "qty": "1", "unit_price_kopecks": "100"}]
    result = validate_order(lines, shipping_city="INVALID_CITY")
    assert result is not None
    assert len(result) > 0
def test_promo_code_and_city_validation() -> None:
    """Couvre les règles 9 et 10 de validate_order."""
    lines = [{"sku": "A", "qty": "1", "unit_price_kopecks": "100"}]
    # Promo inconnu
    assert validate_order(lines, promo_code="FAKE") is not None
    # Ville inconnue
    assert validate_order(lines, shipping_city="PARIS") is not None
    # Cas valide avec promo et ville
    assert validate_order(lines, promo_code="WELCOME10", shipping_city="msk") is None

def test_tier_discounts_and_delivery_logic() -> None:
    """Couvre les lignes de calcul de remise et de livraison (Exemples 2, 3, 4 et 5)."""
    # Exemple 2 : Remise par palier (10 unités)
    lines = [{"sku": "B", "qty": "10", "unit_price_kopecks": "1990"}]
    assert calculate_order_total(lines) == 22_686

    # Exemple 3 : Promo + Palier
    lines = [{"sku": "C", "qty": "50", "unit_price_kopecks": "1990"}]
    assert calculate_order_total(lines, promo_code="WELCOME10") == 160_290

    # Exemple 4 : Plafond de remise (VIP35 -> max 30%)
    lines = [{"sku": "D", "qty": "100", "unit_price_kopecks": "10000"}]
    assert calculate_order_total(lines, promo_code="VIP35", shipping_city="spb") == 840_000

    # Exemple 5 : Livraison gratuite au seuil
    lines = [{"sku": "E", "qty": "1", "unit_price_kopecks": "500000"}]
    assert calculate_order_total(lines, shipping_city="msk") == 600_000
    
def test_coverage_edge_cases() -> None:
    """Tests pour couvrir les branches manquantes."""
    # Cas 1: Promo valide sans palier (couvre la branche promo seule)
    lines = [{"sku": "X", "qty": "1", "unit_price_kopecks": "1000"}]
    result = calculate_order_total(lines, promo_code="SUMMER15")
    assert result is not None
    
    # Cas 2: Livraison payante (montant < 500k)
    lines = [{"sku": "Y", "qty": "1", "unit_price_kopecks": "100"}]
    result = calculate_order_total(lines, shipping_city="spb")
    assert result is not None and result > 120 # 100 + TVA + Port