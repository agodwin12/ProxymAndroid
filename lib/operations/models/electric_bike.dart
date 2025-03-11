import 'package:flutter/material.dart';

class ElectricBike {
  final String id;
  final String name;
  final String model;
  final String vin;
  final IconData icon;
  final String batteryLevel;
  final bool isSelected;

  ElectricBike({
    required this.id,
    required this.name,
    required this.model,
    required this.vin,
    required this.icon,
    required this.batteryLevel,
    this.isSelected = false,
  });

  int get batteryPercentage {
    return int.tryParse(batteryLevel.replaceAll('%', '').trim()) ?? 0;
  }

  ElectricBike copyWith({bool? isSelected}) {
    return ElectricBike(
      id: id,
      name: name,
      model: model,
      vin: vin,
      icon: icon,
      batteryLevel: batteryLevel,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  factory ElectricBike.fromJson(Map<String, dynamic> json) {
    return ElectricBike(
      id: json['bike']['id'].toString(),
      name: "Electric Bike",
      model: json['bike']['model'],
      vin: json['bike']['vin'],
      icon: Icons.electric_bike,
      batteryLevel: json['battery']['soc'].toString() + "%",
    );
  }
}
