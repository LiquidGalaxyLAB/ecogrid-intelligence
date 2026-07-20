import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../../../config/theme/design_constants.dart';
import '../../../config/theme/theme_controller.dart';
import '../../../core/enums/plant_type.dart';
import '../../../domain/model/power_plant.dart';

/// The shared plant-result card used anywhere a searchable plant is shown.
class PowerPlantListTile extends StatelessWidget {
  const PowerPlantListTile({
    required this.plant,
    required this.onTap,
    super.key,
  });

  final PowerPlant plant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.isDarkMode;
    final fuel = _PlantFuelPresentation.from(plant.primaryFuel);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? DesignConstants.cardSurface(context) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? DesignConstants.border(context)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? .15 : .03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? DesignConstants.elevatedSurface(context)
                    : fuel.color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(fuel.icon, color: fuel.color, size: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? DesignConstants.primaryText(context)
                          : const Color(0xFF0D1F4A),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${plant.primaryFuel.displayName} • ${plant.capacityMw?.toStringAsFixed(0) ?? '?'} MW',
                    style: TextStyle(
                      color: isDark
                          ? DesignConstants.secondaryText(context)
                          : const Color(0xFF6B80A0),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? DesignConstants.mutedText(context)
                  : const Color(0xFF0066FF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlantFuelPresentation {
  const _PlantFuelPresentation(this.icon, this.color);

  final IconData icon;
  final Color color;

  static _PlantFuelPresentation from(PlantType type) => switch (type) {
        PlantType.hydro => const _PlantFuelPresentation(
            FluentIcons.water_24_filled, Color(0xFF2196F3)),
        PlantType.nuclear => const _PlantFuelPresentation(
            FluentIcons.warning_24_filled, Color(0xFF00BCD4)),
        PlantType.coal => const _PlantFuelPresentation(
            FluentIcons.fire_24_filled, Color(0xFFFF5722)),
        PlantType.solar => const _PlantFuelPresentation(
            FluentIcons.weather_sunny_24_filled, Color(0xFFFFC107)),
        PlantType.wind => const _PlantFuelPresentation(
            FluentIcons.weather_squalls_24_filled, Color(0xFF4CAF50)),
        PlantType.gas => const _PlantFuelPresentation(
            FluentIcons.gas_24_filled, Color(0xFFF44336)),
        PlantType.oil => const _PlantFuelPresentation(
            FluentIcons.drop_24_filled, Color(0xFF795548)),
        PlantType.biomass => const _PlantFuelPresentation(
            FluentIcons.leaf_one_24_filled, Color(0xFF8BC34A)),
        PlantType.geothermal => const _PlantFuelPresentation(
            FluentIcons.temperature_24_filled, Color(0xFFFF9800)),
        PlantType.waste => const _PlantFuelPresentation(
            FluentIcons.delete_24_filled, Color(0xFF9E9E9E)),
        PlantType.wave => const _PlantFuelPresentation(
            FluentIcons.cloud_flow_24_filled, Color(0xFF00ACC1)),
        PlantType.storage => const _PlantFuelPresentation(
            FluentIcons.battery_charge_24_filled, Color(0xFF9C27B0)),
        PlantType.cogeneration => const _PlantFuelPresentation(
            FluentIcons.building_24_filled, Color(0xFF607D8B)),
        PlantType.petcoke => const _PlantFuelPresentation(
            FluentIcons.cube_24_filled, Color(0xFF616161)),
        PlantType.other => const _PlantFuelPresentation(
            FluentIcons.flash_24_filled, Color(0xFF607D8B)),
      };
}
