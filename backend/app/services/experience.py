"""Experience classification layer.

Decouples "how good is this place" (Yelp star rating) from "how fun / high-energy
is this experience" (arousal, fun_factor). A 5-star gallery and a 3.5-star
paintball venue should NOT be scored the same way — paintball is high arousal /
high fun regardless of its star rating, and a gallery is low arousal / low fun
regardless of how well-reviewed it is.

Static lookup only — no network calls, no LLM calls. Safe to call once per
candidate, per slot, per request.

MATCHING NOTE: services/yelp.py stores each category as its Yelp *title*
(c["title"], e.g. "Art Galleries", "Escape Games", "Cocktail Bars"), and the OSM
fallback stores raw OSM subtypes (e.g. "escape_game", "amusement_arcade",
"restaurant"). Neither is a clean Yelp alias/slug. So we normalise each category
string (lowercase, strip non-alphanumerics) and match by keyword *substring*
rather than exact slug equality. KEYWORD_PROFILES is ordered specific/high-energy
first so, e.g., "amusement_arcade" matches "arcade" (not "amusement"), and
"amusement park" still matches "amusement" before the generic "park".
"""
import re

# (arousal 1-5, fun_factor 1-5). ORDER MATTERS — first substring hit wins, so
# put specific / high-energy keywords before generic ones.
KEYWORD_PROFILES: dict[str, tuple[float, float]] = {
    # --- high energy / high hype -------------------------------------------
    "paintball":   (5.0, 5.0),
    "kart":        (5.0, 5.0),   # gokarts / karting
    "arcade":      (3.5, 4.5),   # before "amusement" so amusement_arcade = arcade
    "amusement":   (4.5, 4.5),   # amusement park
    "waterpark":   (4.5, 4.5),
    "trampoline":  (4.5, 4.5),
    "laser":       (5.0, 4.5),   # laser tag
    "escape":      (4.0, 4.5),   # escape games / escape_game
    "axethrow":    (4.0, 4.5),
    "climb":       (4.0, 4.0),   # rock climbing
    "karaoke":     (4.0, 4.5),
    "comedy":      (3.5, 4.5),
    "musicvenue":  (4.0, 4.5),
    "nightclub":   (3.5, 4.0),
    "bowl":        (3.0, 4.0),   # bowling / bowling_alley
    "golf":        (3.0, 4.0),   # mini golf / miniature_golf (and courses)
    # --- moderate / curious ------------------------------------------------
    "aquarium":    (2.5, 4.0),
    "zoo":         (2.5, 4.0),
    "cinema":      (2.5, 3.5),
    "theatre":     (2.5, 3.5),
    "theater":     (2.5, 3.5),
    "beach":       (2.5, 3.5),
    "attraction":  (2.5, 3.5),
    # --- nightlife / drink -------------------------------------------------
    "cocktail":    (2.5, 3.5),   # before "bar"
    "hookah":      (2.0, 3.5),
    "lounge":      (2.0, 3.0),
    "winer":       (2.0, 3.5),   # wineries
    "pub":         (2.5, 3.5),
    "bar":         (3.0, 3.5),   # generic bars (after cocktail/hookah/wine)
    # --- calm / low energy -------------------------------------------------
    "museum":      (2.0, 3.0),
    "galler":      (1.5, 2.5),   # art galleries
    "observ":      (1.5, 3.0),
    "landmark":    (1.5, 3.0),
    "waterfall":   (2.0, 3.5),
    "naturereserve": (1.5, 3.0),
    "park":        (1.5, 3.0),   # plain parks (after amusement/water/trampoline)
    # --- food / cafe -------------------------------------------------------
    "icecream":    (1.5, 3.0),
    "dessert":     (1.5, 3.0),
    "bakery":      (1.5, 2.5),
    "coffee":      (1.0, 2.0),
    "cafe":        (1.0, 2.0),
    "restaurant":  (2.0, 3.0),
    "fastfood":    (1.5, 2.5),
}

DEFAULT_PROFILE: tuple[float, float] = (2.5, 3.0)  # neutral fallback


def _norm(s: str) -> str:
    return re.sub(r"[^a-z0-9]", "", s.lower())


def profile_for(categories: list[str] | None) -> tuple[float, float]:
    """Return (arousal, fun_factor) for the first category whose normalised text
    contains a known keyword. Neutral default if nothing matches (or no
    categories — OSM fallback candidates often have none)."""
    for cat in categories or []:
        if not cat:
            continue
        n = _norm(cat)
        for kw, prof in KEYWORD_PROFILES.items():
            if kw in n:
                return prof
    return DEFAULT_PROFILE


def arousal_for(categories: list[str] | None) -> float:
    return profile_for(categories)[0]


def fun_factor_for(categories: list[str] | None) -> float:
    return profile_for(categories)[1]
