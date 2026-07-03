import 'package:flutter/material.dart';
import '../../config/theme/app_theme.dart';
import '../../domain/model/power_plant.dart';
import '../../domain/model/cvs_result.dart';
import '../../core/enums/plant_type.dart';
import '../../core/enums/risk_level.dart';

class PlantMapBottomSheet extends StatelessWidget {
  final PowerPlant plant;
  final CVSResult cvs;
  const PlantMapBottomSheet({
    super.key,
    required this.plant,
    required this.cvs,
  });
  IconData _getIconForFuel(PlantType fuelType) {
    switch (fuelType) {
      case PlantType.hydro:
        return Icons.water_drop;
      case PlantType.solar:
        return Icons.wb_sunny;
      case PlantType.wind:
        return Icons.air;
      case PlantType.coal:
        return Icons.factory;
      case PlantType.gas:
        return Icons.local_fire_department;
      case PlantType.nuclear:
        return Icons.science;
      case PlantType.biomass:
        return Icons.eco;
      case PlantType.geothermal:
        return Icons.thermostat;
      case PlantType.waste:
        return Icons.delete;
      case PlantType.storage:
        return Icons.battery_charging_full;
      case PlantType.cogeneration:
        return Icons.sync;
      default:
        return Icons.bolt;
    }
  }

  Color _getRiskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.high:
        return AppTheme.riskHigh;
      case RiskLevel.medium:
        return AppTheme.riskMedium;
      case RiskLevel.low:
        return AppTheme.riskLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(cvs.riskLevel);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForFuel(plant.primaryFuel),
                    color: riskColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plant.name, style: AppTheme.headingMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${plant.countryLong ?? plant.country} • ${plant.primaryFuel.displayName}',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLG),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Capacity',
                    '${plant.capacityMw?.toStringAsFixed(0) ?? '?'} MW',
                    Icons.bolt,
                    AppTheme.primary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: _buildStatCard(
                    'Risk Level',
                    cvs.riskLevel.label,
                    Icons.shield,
                    riskColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Climate Vulnerability Score',
                        style: AppTheme.labelLarge,
                      ),
                      Text(
                        cvs.score.toStringAsFixed(1),
                        style: AppTheme.headingMedium.copyWith(
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: cvs.score / 100,
                      backgroundColor: AppTheme.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spacingSM),
          Text(label, style: AppTheme.caption),
          const SizedBox(height: 2),
          Text(value, style: AppTheme.headingSmall),
        ],
      ),
    );
  }
}
