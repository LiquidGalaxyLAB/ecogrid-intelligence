import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:logger/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/theme/app_theme.dart';
import '../../domain/model/climate_data.dart';
import '../plant_detail/bloc/plant_detail_bloc.dart';
import '../plant_detail/bloc/plant_detail_data.dart';
import '../plant_detail/bloc/plant_detail_event.dart';
import '../../core/resources/app_state.dart';

class HistoricalTrendsSheet extends StatelessWidget {
  final List<ClimateData> historicalData;
  const HistoricalTrendsSheet({super.key, required this.historicalData});
  @override
  Widget build(BuildContext context) {
    Logger().i('[UI] Opened HistoricalTrendsSheet');
    if (historicalData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: const Center(child: Text('No historical data available')),
      );
    }
    final validData = historicalData
        .where(
          (d) =>
              d.temperature != null ||
              d.precipitation != null ||
              d.windSpeed != null,
        )
        .toList();
    if (validData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Center(
          child: Text(
            'No valid historical data available',
            style: AppTheme.bodyMedium,
          ),
        ),
      );
    }
    double sumTemp = 0, sumPrecip = 0, sumWind = 0;
    int countTemp = 0, countPrecip = 0, countWind = 0;
    for (final d in validData) {
      if (d.temperature != null) {
        sumTemp += d.temperature!;
        countTemp++;
      }
      if (d.precipitation != null) {
        sumPrecip += d.precipitation!;
        countPrecip++;
      }
      if (d.windSpeed != null) {
        sumWind += d.windSpeed!;
        countWind++;
      }
    }
    final avgTemp = countTemp > 0 ? sumTemp / countTemp : 1.0;
    final avgPrecip = countPrecip > 0 ? sumPrecip / countPrecip : 1.0;
    final avgWind = countWind > 0 ? sumWind / countWind : 1.0;
    final tempSpots = <FlSpot>[];
    final precipSpots = <FlSpot>[];
    final windSpots = <FlSpot>[];
    for (int i = 0; i < validData.length; i++) {
      final x = i.toDouble();
      final d = validData[i];
      double tempVal = 0;
      if (d.temperature != null && avgTemp.abs() > 0.01) {
        tempVal = ((d.temperature! - avgTemp) / avgTemp) * 100;
      }
      double precipVal = 0;
      if (d.precipitation != null && avgPrecip.abs() > 0.01) {
        precipVal = ((d.precipitation! - avgPrecip) / avgPrecip) * 100;
      }
      double windVal = 0;
      if (d.windSpeed != null && avgWind.abs() > 0.01) {
        windVal = ((d.windSpeed! - avgWind) / avgWind) * 100;
      }
      tempSpots.add(FlSpot(x, tempVal));
      precipSpots.add(FlSpot(x, precipVal));
      windSpots.add(FlSpot(x, windVal));
    }
    final allYValues = [
      ...tempSpots.map((s) => s.y),
      ...precipSpots.map((s) => s.y),
      ...windSpots.map((s) => s.y),
    ];
    double dataMinY = allYValues.reduce((a, b) => a < b ? a : b);
    double dataMaxY = allYValues.reduce((a, b) => a > b ? a : b);
    final yPadding = ((dataMaxY - dataMinY) * 0.15).clamp(5.0, double.infinity);
    double minY = (dataMinY - yPadding).floorToDouble();
    double maxY = (dataMaxY + yPadding).ceilToDouble();
    double minX = 0;
    double maxX = (validData.length - 1).toDouble();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: AppTheme.sheetDecoration,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Historical Climate Trends',
                      style: AppTheme.headingMedium,
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingMD),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendItem(
                      color: const Color(0xFFFF5252),
                      label: 'Temp (% dev)',
                    ),
                    const SizedBox(width: 16),
                    _LegendItem(
                      color: const Color(0xFF448AFF),
                      label: 'Precip (% dev)',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendItem(
                      color: const Color(0xFF69F0AE),
                      label: 'Wind (% dev)',
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingLG),
                SizedBox(
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      minX: minX,
                      maxX: maxX,
                      minY: minY,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: ((maxY - minY) / 5)
                            .ceilToDouble()
                            .clamp(1, double.infinity),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppTheme.cardBorder.withValues(alpha: 0.3),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 2,
                            getTitlesWidget: (value, meta) {
                              if (value < 0 || value >= validData.length) {
                                return const SizedBox.shrink();
                              }
                              final date = validData[value.toInt()].timestamp;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  date.year.toString(),
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            interval: ((maxY - minY) / 5).ceilToDouble().clamp(
                              1,
                              double.infinity,
                            ),
                            getTitlesWidget: (value, meta) => Text(
                              '${value > 0 ? "+" : ""}${value.toInt()}%',
                              style: AppTheme.caption.copyWith(fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: tempSpots,
                          isCurved: false,
                          color: const Color(0xFFFF5252),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                        ),
                        LineChartBarData(
                          spots: precipSpots,
                          isCurved: false,
                          color: const Color(0xFF448AFF),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                        ),
                        LineChartBarData(
                          spots: windSpots,
                          isCurved: false,
                          color: const Color(0xFF69F0AE),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppTheme.spacingLG),
                BlocBuilder<PlantDetailBloc, AppState<PlantDetailData>>(
                  builder: (context, state) {
                    if (state is! AppSuccess<PlantDetailData>) {
                      return const SizedBox.shrink();
                    }
                    if (state.data!.isLoadingTrendInsight) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: LinearProgressIndicator(
                            color: AppTheme.secondary,
                            backgroundColor: AppTheme.surfaceLight,
                          ),
                        ),
                      );
                    }
                    if (state.data!.trendInsight != null) {
                      return Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMD),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.secondary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: AppTheme.secondary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Trend Analysis',
                                  style: AppTheme.labelLarge.copyWith(
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.data!.trendInsight!,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<PlantDetailBloc>().add(
                            const PlantDetailTrendInsightRequested(),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Explain This Trend'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: AppTheme.spacingXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTheme.bodySmall.copyWith(color: color)),
      ],
    );
  }
}
