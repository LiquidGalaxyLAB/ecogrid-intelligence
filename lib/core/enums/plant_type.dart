enum PlantType {
  hydro('Hydro', 'Hydroelectric'),
  nuclear('Nuclear', 'Nuclear'),
  solar('Solar', 'Solar'),
  wind('Wind', 'Wind'),
  coal('Coal', 'Coal/Thermal'),
  gas('Gas', 'Natural Gas'),
  oil('Oil', 'Oil/Petroleum'),
  biomass('Biomass', 'Biomass'),
  geothermal('Geothermal', 'Geothermal'),
  waste('Waste', 'Waste'),
  wave('Wave and Tidal', 'Wave & Tidal'),
  storage('Storage', 'Energy Storage'),
  cogeneration('Cogeneration', 'Cogeneration'),
  petcoke('Petcoke', 'Petroleum Coke'),
  other('Other', 'Other');

  final String csvLabel;
  final String displayName;
  const PlantType(this.csvLabel, this.displayName);
  static PlantType fromCsvFuel(String fuel) {
    final lower = fuel.toLowerCase().trim();
    if (lower.contains('hydro')) return PlantType.hydro;
    if (lower.contains('nuclear')) return PlantType.nuclear;
    if (lower.contains('solar')) return PlantType.solar;
    if (lower.contains('wind')) return PlantType.wind;
    if (lower.contains('coal')) return PlantType.coal;
    if (lower.contains('gas')) return PlantType.gas;
    if (lower.contains('oil') || lower.contains('petrol')) return PlantType.oil;
    if (lower.contains('biomass')) return PlantType.biomass;
    if (lower.contains('geothermal')) return PlantType.geothermal;
    if (lower.contains('waste')) return PlantType.waste;
    if (lower.contains('wave') || lower.contains('tidal')) {
      return PlantType.wave;
    }
    if (lower.contains('storage')) return PlantType.storage;
    if (lower.contains('cogeneration')) return PlantType.cogeneration;
    if (lower.contains('petcoke')) return PlantType.petcoke;
    return PlantType.other;
  }
}
