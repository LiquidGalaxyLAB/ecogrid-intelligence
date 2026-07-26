/// Phases of the first-time-user-experience (FTUE) guided tour.
///
/// Each phase maps to one or more UI steps in the 19-step tour sequence.
/// Navigation-only transitions (steps 1, 3, 5, 6, 8, 11, 13, 16, 17)
/// don't have a dedicated phase — the phase advances automatically
/// when the destination screen's [addPostFrameCallback] fires.
enum TourPhase {
  /// Step 2 — Highlight the settings/connection pill on the home screen.
  homeSettings,

  /// Step 3 - Highlight the Connection tab in LG Settings
  lgConnectionTab,

  /// Step 4 — Highlight the Connect button (+ "Skip for now") on the
  /// LG connection panel.
  lgConnection,

  /// Step 7 — Highlight the first region card in the Quick Explore grid.
  homeRegion,

  /// Step 9 — Highlight the Regional AI Insight FAB on the explore screen.
  exploreAiFab,

  /// Step 10 — Highlight the first power plant in the list.
  explorePlant,

  /// Step 12 — Highlight the Plant Insight FAB on the plant detail screen.
  plantInsightFab,

  /// Step 14 — Highlight the Compare Power Plants FAB on the explore screen.
  exploreCompareFab,

  /// Step 15 — Highlight the Compare button after 2+ plants are selected.
  exploreCompareSelect,

  /// Step 16 - Highlight an element on the Plant Comparison screen.
  exploreComparison,

  /// Step 18 — Highlight the "Show Infrastructure Map" button on the home screen.
  homeInfraMap,

  /// Step 19 — Explanatory tooltip on the infrastructure map screen.
  infraMapExplain,

  /// Tour completed or dismissed.
  completed,
}
