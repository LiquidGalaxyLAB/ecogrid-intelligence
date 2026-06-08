/// Report generated after CSV dataset ingestion.
///
/// Tracks row-level parsing outcomes to allow verification
/// and debugging of the data pipeline without coupling
/// reporting logic into the data source itself.
class IngestionReport {
  final int totalRows;
  final int validPlants;
  final int skippedMissingCoordinates;
  final int skippedMissingName;
  final int skippedMalformed;
  final int duplicatesDetected;
  final Duration elapsed;
  final List<String> warnings;

  const IngestionReport({
    required this.totalRows,
    required this.validPlants,
    required this.skippedMissingCoordinates,
    required this.skippedMissingName,
    required this.skippedMalformed,
    required this.duplicatesDetected,
    required this.elapsed,
    this.warnings = const [],
  });

  int get totalSkipped =>
      skippedMissingCoordinates + skippedMissingName + skippedMalformed;

  double get successRate => totalRows > 0 ? (validPlants / totalRows) * 100 : 0;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln('═══════════════════════════════════════════════')
      ..writeln('  EcoGrid Dataset Ingestion Report')
      ..writeln('═══════════════════════════════════════════════')
      ..writeln('  Total CSV rows:          $totalRows')
      ..writeln('  Valid plants ingested:   $validPlants')
      ..writeln('  ─────────────────────────────────────────────')
      ..writeln('  Skipped (no coords):     $skippedMissingCoordinates')
      ..writeln('  Skipped (no name):       $skippedMissingName')
      ..writeln('  Skipped (malformed):     $skippedMalformed')
      ..writeln('  Duplicates detected:     $duplicatesDetected')
      ..writeln('  ─────────────────────────────────────────────')
      ..writeln('  Success rate:            ${successRate.toStringAsFixed(1)}%')
      ..writeln('  Elapsed:                 ${elapsed.inMilliseconds}ms')
      ..writeln('═══════════════════════════════════════════════');

    if (warnings.isNotEmpty) {
      buffer.writeln('  Warnings (first 10):');
      for (final w in warnings.take(10)) {
        buffer.writeln('    ⚠ $w');
      }
    }

    return buffer.toString();
  }
}
