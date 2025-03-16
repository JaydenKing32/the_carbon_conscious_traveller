enum CarSize {
  smallCar,
  mediumCar,
  largeCar,
  mini,
  supermini,
  lowerMedium,
  upperMedium,
  executive,
  luxury,
  sports,
  dualPurpose4x4,
  mpv,
  label,
}

extension CarSizeExtension on CarSize {
  String get name {
    switch (this) {
      case CarSize.smallCar:
        return "Small car";
      case CarSize.mediumCar:
        return "Medium car";
      case CarSize.largeCar:
        return "Large car";
      case CarSize.mini:
        return "Mini";
      case CarSize.supermini:
        return "Supermini";
      case CarSize.lowerMedium:
        return "Lower medium";
      case CarSize.upperMedium:
        return "Upper medium";
      case CarSize.executive:
        return "Executive";
      case CarSize.luxury:
        return "Luxury";
      case CarSize.sports:
        return "Sports";
      case CarSize.dualPurpose4x4:
        return "Dual purpose 4X4";
      case CarSize.mpv:
        return "MPV";
      default:
        return "Select";
    }
  }
}

String carFuelTypeToString(CarFuelType fuelType) => fuelType.toString();

/// Convert a MotorcycleSize to string, e.g., "MotorcycleSize.medium"
String motorcycleSizeToString(MotorcycleSize size) => size.toString();

/// Convert back from string to MotorcycleSize, defaulting to MotorcycleSize.label if not found
MotorcycleSize stringToMotorcycleSize(String sizeStr) {
  return MotorcycleSize.values.firstWhere(
    (e) => e.toString() == sizeStr,
    orElse: () => MotorcycleSize.label,
  );
}

CarSize stringToCarSize(String carSizeStr) {
  return CarSize.values.firstWhere(
    (e) => e.toString() == carSizeStr,
    orElse: () => CarSize.smallCar, // Default to first valid value
  );
}

CarFuelType stringToCarFuelType(String fuelTypeStr) {
  return CarFuelType.values.firstWhere(
    (e) => e.toString() == fuelTypeStr,
    orElse: () => CarFuelType.petrol, // Default to first valid value
  );
}

enum CarFuelType {
  diesel,
  petrol,
  hybrid,
  cng,
  lpg,
  phev,
  bev,
  label,
}

extension CarFuelTypeExtension on CarFuelType {
  String get name {
    switch (this) {
      case CarFuelType.diesel:
        return "Diesel";
      case CarFuelType.petrol:
        return "Petrol";
      case CarFuelType.hybrid:
        return "Hybrid";
      case CarFuelType.cng:
        return "CNG";
      case CarFuelType.lpg:
        return "LPG";
      case CarFuelType.phev:
        return "Plug-in Hybrid Electric Vehicle";
      case CarFuelType.bev:
        return "Battery Electric Vehicle";
      default:
        return "Select";
    }
  }
}

const List<List<double>> carValuesMatrix = [
  [
    0.139306448880537,
    0.140798534228188,
    0.101498857718121,
    0.0,
    0.0,
    0.0540229932885906,
    0.0482282859060403
  ],
  [
    0.167156448880537,
    0.178188534228188,
    0.109038436241611,
    0.156604197315436,
    0.176070597315436,
    0.0850073342281879,
    0.0526663489932886
  ],
  [
    0.208586448880537,
    0.272238534228188,
    0.1524358,
    0.238454197315436,
    0.269140597315436,
    0.101584382550336,
    0.05737
  ],
  [
    0.107746448880537,
    0.130298534228188,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0443381932885906
  ],
  [
    0.132146448880537,
    0.141688534228188,
    0.0,
    0.0,
    0.0,
    0.0540229932885906,
    0.0490671785234899
  ],
  [
    0.143456448880537,
    0.164728534228188,
    0.0,
    0.0,
    0.0,
    0.0831183489932886,
    0.0525663489932886
  ],
  [
    0.160496448880537,
    0.192108534228188,
    0.0,
    0.0,
    0.0,
    0.0868662268456376,
    0.0547703154362416
  ],
  [
    0.173096448880537,
    0.212318534228188,
    0.0,
    0.0,
    0.0,
    0.0888617973154363,
    0.0500662563758389
  ],
  [
    0.211196448880537,
    0.318088534228188,
    0.0,
    0.0,
    0.0,
    0.115139275167785,
    0.0583732120805369
  ],
  [
    0.169436448880537,
    0.237158534228188,
    0.0,
    0.0,
    0.0,
    0.0996696416107383,
    0.0834804456375839
  ],
  [
    0.201946448880537,
    0.204048534228188,
    0.0,
    0.0,
    0.0,
    0.103275582550336,
    0.0610424751677852
  ],
  [
    0.176596448880537,
    0.184258534228188,
    0.0,
    0.0,
    0.0,
    0.0990220751677852,
    0.0793324751677852
  ]
];

//Set up MotorcycleSize class
enum MotorcycleSize {
  small,
  medium,
  large,
  label,
}

extension MotorcycleSizeExtension on MotorcycleSize {
  String get name {
    switch (this) {
      case MotorcycleSize.small:
        return "Small";
      case MotorcycleSize.medium:
        return "Medium";
      case MotorcycleSize.large:
        return "Large";
      default:
        return "Size";
    }
  }
}

extension MotorcycleValues on MotorcycleSize {
  double get value {
    switch (this) {
      case MotorcycleSize.small:
        return 0.0831851865771812;
      case MotorcycleSize.medium:
        return 0.10107835704698;
      case MotorcycleSize.large:
        return 0.13251915704698;
      default:
        return 0.0;
    }
  }
}

enum BusType {
  averageLocalBus,
  coach,
  trolleybus,
}

extension BusTypeExtension on BusType {
  String get name {
    switch (this) {
      case BusType.averageLocalBus:
        return "Average local bus";
      case BusType.coach:
        return "Coach";
      case BusType.trolleybus:
        return "Trolleybus";
      default:
        return "Average local bus";
    }
  }
}

extension BusValues on BusType {
  double get value {
    switch (this) {
      case BusType.averageLocalBus:
        return 0.102150394630872;
      case BusType.coach:
        return 0.0271814013422819;
      case BusType.trolleybus:
        return 0.00699;
      default:
        return 0.0;
    }
  }
}

enum RailType {
  nationalRail,
  lightRailAndTram,
  londonUnderground,
}

extension RailTypeExtension on RailType {
  String get name {
    switch (this) {
      case RailType.nationalRail:
        return "National rail";
      case RailType.lightRailAndTram:
        return "Light rail and tram";
      case RailType.londonUnderground:
        return "London Underground";
      default:
        return "National rail";
    }
  }
}

extension RailValues on RailType {
  double get value {
    switch (this) {
      case RailType.nationalRail:
        return 0.0354629637583893;
      case RailType.lightRailAndTram:
        return 0.028603267114094;
      case RailType.londonUnderground:
        return 0.027802067114094;
      default:
        return 0.0;
    }
  }
}

enum FerryType {
  footPassenger,
  carPassenger,
  averageAllPassenger,
}

extension FerryTypeExtension on FerryType {
  String get name {
    switch (this) {
      case FerryType.footPassenger:
        return "Foot passenger";
      case FerryType.carPassenger:
        return "Car passenger";
      case FerryType.averageAllPassenger:
        return "Average (all passenger)";
      default:
        return "Foot passenger";
    }
  }
}

extension FerryValues on FerryType {
  double get value {
    switch (this) {
      case FerryType.footPassenger:
        return 0.0187108139597315;
      case FerryType.carPassenger:
        return 0.129328875436242;
      case FerryType.averageAllPassenger:
        return 0.112698080805369;
      default:
        return 0.0;
    }
  }
}

// CO2e kg/km per passenger
const double cableCarValue = 0.0269;
const double trolleybusValue = 0.00699;
