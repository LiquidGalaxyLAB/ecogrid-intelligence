import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import '../core/enums/tour_phase.dart';
import '../core/constants/tour_keys.dart';

/// Lightweight singleton service that manages FTUE (first-time-user-experience)
/// tour state.
///
/// Tracks the current tour phase, persists completion via [SharedPreferences],
/// and coordinates cross-screen showcase triggers.
class TourService {
  static const _prefKey = 'has_completed_ftue_tour';

  /// Whether the tour is currently active.
  final ValueNotifier<bool> isTourActive = ValueNotifier(false);

  /// The current phase of the tour.
  final ValueNotifier<TourPhase> currentPhase =
      ValueNotifier(TourPhase.completed);

  // ── Lifecycle ───────────────────────────────────────────────────────────

  /// Checks [SharedPreferences] and starts the tour if this is the first
  /// launch (i.e. [_prefKey] is false or absent).
  ///
  /// Directly sets [isTourActive] = true so that listeners (e.g. the home
  /// page) are notified immediately.
  Future<void> checkAndStartTour() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_prefKey) ?? false;
    if (!completed) {
      currentPhase.value = TourPhase.homeSettings;
      isTourActive.value = true;
    }
  }

  /// Advances to the next [TourPhase] in sequence.
  ///
  /// If the current phase is already [TourPhase.completed] this is a no-op.
  void advancePhase() {
    final phases = TourPhase.values;
    final currentIndex = phases.indexOf(currentPhase.value);
    if (currentIndex < phases.length - 1) {
      currentPhase.value = phases[currentIndex + 1];
    }
    if (currentPhase.value == TourPhase.completed) {
      completeTour();
    }
  }

  /// Marks the tour as completed, persists the flag, and dismisses any
  /// active showcase overlay.
  Future<void> completeTour() async {
    isTourActive.value = false;
    currentPhase.value = TourPhase.completed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  /// Alias for [completeTour] — called when the user taps "Skip tour".
  Future<void> skipTour() => completeTour();

  /// Resets the completion flag and restarts the tour from the beginning.
  ///
  // TODO(tour): Wire this to a "Take the tour" entry in the settings
  // screen once that UI is built. For now the method is available but
  // not exposed in any settings UI.
  Future<void> restartTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, false);
    currentPhase.value = TourPhase.homeSettings;
    isTourActive.value = true;
  }

  // ── Showcase helpers ────────────────────────────────────────────────────

  /// Starts a single-step showcase targeting the given [TourKeys] key,
  /// only if the tour is active and the current phase matches [phase].
  ///
  /// Returns `true` if the showcase was started; `false` otherwise.
  bool showIfPhase(BuildContext context, TourPhase phase, List<GlobalKey> keys) {
    if (!isTourActive.value || currentPhase.value != phase) return false;
    try {
      ShowCaseWidget.of(context).startShowCase(keys, delay: const Duration(milliseconds: 500));
      return true;
    } catch (_) {
      return false;
    }
  }
}
