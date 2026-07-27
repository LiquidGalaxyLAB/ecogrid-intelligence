import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/design_constants.dart';
import '../../../config/theme/theme_controller.dart';
import '../../../core/enums/plant_type.dart';
import '../../../core/enums/risk_level.dart';

enum ExploreFilterOption {
  allPlantTypes,
  hydro,
  nuclear,
  coal,
  solar,
  wind,
  gas,
  oil,
  biomass,
  geothermal,
  waste,
  wave,
  storage,
  cogeneration,
  petcoke,
  other,
  allRiskLevels,
  highRisk,
  mediumRisk,
  lowRisk;

  static const plantTypes = [
    allPlantTypes, hydro, nuclear, coal, solar, wind, gas, oil, biomass,
    geothermal, waste, wave, storage, cogeneration, petcoke, other,
  ];
  static const riskLevels = [allRiskLevels, highRisk, mediumRisk, lowRisk];
}

extension ExploreFilterOptionDetails on ExploreFilterOption {
  PlantType? get plantType => switch (this) {
        ExploreFilterOption.hydro => PlantType.hydro,
        ExploreFilterOption.nuclear => PlantType.nuclear,
        ExploreFilterOption.coal => PlantType.coal,
        ExploreFilterOption.solar => PlantType.solar,
        ExploreFilterOption.wind => PlantType.wind,
        ExploreFilterOption.gas => PlantType.gas,
        ExploreFilterOption.oil => PlantType.oil,
        ExploreFilterOption.biomass => PlantType.biomass,
        ExploreFilterOption.geothermal => PlantType.geothermal,
        ExploreFilterOption.waste => PlantType.waste,
        ExploreFilterOption.wave => PlantType.wave,
        ExploreFilterOption.storage => PlantType.storage,
        ExploreFilterOption.cogeneration => PlantType.cogeneration,
        ExploreFilterOption.petcoke => PlantType.petcoke,
        ExploreFilterOption.other => PlantType.other,
        _ => null,
      };

  RiskLevel? get riskLevel => switch (this) {
        ExploreFilterOption.highRisk => RiskLevel.high,
        ExploreFilterOption.mediumRisk => RiskLevel.medium,
        ExploreFilterOption.lowRisk => RiskLevel.low,
        _ => null,
      };

  bool get isAll => this == ExploreFilterOption.allPlantTypes ||
      this == ExploreFilterOption.allRiskLevels;

  String get label => switch (this) {
        ExploreFilterOption.allPlantTypes || ExploreFilterOption.allRiskLevels => 'All',
        ExploreFilterOption.coal => 'Thermal',
        ExploreFilterOption.wave => 'Wave/Tidal',
        ExploreFilterOption.highRisk => 'High',
        ExploreFilterOption.mediumRisk => 'Medium',
        ExploreFilterOption.lowRisk => 'Low',
        _ => plantType!.displayName,
      };

  IconData get icon => switch (this) {
        ExploreFilterOption.allPlantTypes || ExploreFilterOption.allRiskLevels => FluentIcons.grid_24_filled,
        ExploreFilterOption.hydro => FluentIcons.water_24_filled,
        ExploreFilterOption.nuclear => FluentIcons.warning_24_filled,
        ExploreFilterOption.coal => FluentIcons.fire_24_filled,
        ExploreFilterOption.solar => FluentIcons.weather_sunny_24_filled,
        ExploreFilterOption.wind => FluentIcons.weather_squalls_24_filled,
        ExploreFilterOption.gas => FluentIcons.gas_24_filled,
        ExploreFilterOption.oil => FluentIcons.drop_24_filled,
        ExploreFilterOption.biomass => FluentIcons.leaf_one_24_filled,
        ExploreFilterOption.geothermal => FluentIcons.temperature_24_filled,
        ExploreFilterOption.waste => FluentIcons.delete_24_filled,
        ExploreFilterOption.wave => FluentIcons.cloud_flow_24_filled,
        ExploreFilterOption.storage => FluentIcons.battery_charge_24_filled,
        ExploreFilterOption.cogeneration => FluentIcons.building_24_filled,
        ExploreFilterOption.petcoke => FluentIcons.cube_24_filled,
        ExploreFilterOption.other => FluentIcons.flash_24_filled,
        ExploreFilterOption.highRisk || ExploreFilterOption.mediumRisk || ExploreFilterOption.lowRisk => Icons.shield,
      };

  Color get color => switch (this) {
        ExploreFilterOption.hydro => const Color(0xFF2196F3),
        ExploreFilterOption.nuclear => const Color(0xFF00BCD4),
        ExploreFilterOption.coal => const Color(0xFFFF5722),
        ExploreFilterOption.solar => const Color(0xFFFFC107),
        ExploreFilterOption.wind => const Color(0xFF4CAF50),
        ExploreFilterOption.gas => const Color(0xFFF44336),
        ExploreFilterOption.oil => const Color(0xFF795548),
        ExploreFilterOption.biomass => const Color(0xFF8BC34A),
        ExploreFilterOption.geothermal => const Color(0xFFFF9800),
        ExploreFilterOption.waste => const Color(0xFF9E9E9E),
        ExploreFilterOption.wave => const Color(0xFF00ACC1),
        ExploreFilterOption.storage => const Color(0xFF9C27B0),
        ExploreFilterOption.cogeneration || ExploreFilterOption.other => const Color(0xFF607D8B),
        ExploreFilterOption.petcoke => const Color(0xFF616161),
        ExploreFilterOption.highRisk => const Color(0xFFFF3B30),
        ExploreFilterOption.mediumRisk => const Color(0xFFFF9500),
        ExploreFilterOption.lowRisk => const Color(0xFF34C759),
        ExploreFilterOption.allPlantTypes || ExploreFilterOption.allRiskLevels => Colors.white,
      };
}

class ExploreFilterChip extends StatelessWidget {
  const ExploreFilterChip({
    required this.option,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  final ExploreFilterOption option;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final activeColor = option.isAll ? const Color(0xFF0066FF) : option.color;
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? activeColor.withValues(alpha: .2) : activeColor.withValues(alpha: .1))
              : (isDark ? DesignConstants.cardSurface(context) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF00C8FF).withValues(alpha: .6) : activeColor)
                : (isDark ? DesignConstants.border(context) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected && isDark
              ? [BoxShadow(color: const Color(0xFF00C8FF).withValues(alpha: .25), blurRadius: 8)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(option.icon, size: 16, color: isSelected ? (isDark ? Colors.white : activeColor) : option.color),
            const SizedBox(width: 6),
            Text(
              option.label,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : activeColor)
                    : (isDark ? DesignConstants.secondaryText(context) : const Color(0xFF0D1F4A)),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
