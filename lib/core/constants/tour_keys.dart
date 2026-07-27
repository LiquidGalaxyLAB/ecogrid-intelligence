import 'package:flutter/widgets.dart';

/// Central registry of [GlobalKey]s used by [Showcase] widgets across
/// screens to anchor coachmarks during the FTUE tour.
///
/// Keys are grouped by the screen they belong to.
abstract final class TourKeys {
  // ── Home screen ─────────────────────────────────────────────────────────
  /// Settings / LG connection pill in the header.
  static final GlobalKey settings = GlobalKey(debugLabel: 'tour_settings');

  /// First region card in the Quick Explore grid.
  static final GlobalKey region = GlobalKey(debugLabel: 'tour_region');

  /// "Show Infrastructure Map" button at the bottom.
  static final GlobalKey infraMap = GlobalKey(debugLabel: 'tour_infra_map');

  // ── LG Connection screen ───────────────────────────────────────────────
  /// Connection tab in the TabBar.
  static final GlobalKey connectionTab =
      GlobalKey(debugLabel: 'tour_connection_tab');

  /// Connect button on the Connection tab.
  static final GlobalKey connect = GlobalKey(debugLabel: 'tour_connect');

  // ── Explore screen ─────────────────────────────────────────────────────
  /// Regional AI Insight FAB.
  static final GlobalKey exploreAiFab =
      GlobalKey(debugLabel: 'tour_explore_ai_fab');

  /// First power plant list tile.
  static final GlobalKey plant = GlobalKey(debugLabel: 'tour_plant');

  /// Compare Power Plants FAB.
  static final GlobalKey compareFab =
      GlobalKey(debugLabel: 'tour_compare_fab');

  /// Compare button inside the compare bottom bar.
  static final GlobalKey compareBtn =
      GlobalKey(debugLabel: 'tour_compare_btn');

  // ── Compare screen ─────────────────────────────────────────────────────
  /// Element on the comparison screen.
  static final GlobalKey compareScreenInfo =
      GlobalKey(debugLabel: 'tour_compare_screen_info');

  // ── Plant Detail screen ────────────────────────────────────────────────
  /// Plant Insight FAB.
  static final GlobalKey plantInsightFab =
      GlobalKey(debugLabel: 'tour_plant_insight_fab');

  // ── Infrastructure Map screen ──────────────────────────────────────────
  /// Explanatory overlay / map widget.
  static final GlobalKey mapExplain =
      GlobalKey(debugLabel: 'tour_map_explain');
}
