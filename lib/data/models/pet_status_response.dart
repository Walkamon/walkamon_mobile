class PetStatusResponse {
  final int currentEnergy;
  final int maxEnergy;
  final int currentBond;
  final int maxBond;
  final int currentLifeForce;
  final int maxLifeForce;

  PetStatusResponse({
    required this.currentEnergy,
    required this.maxEnergy,
    required this.currentBond,
    required this.maxBond,
    required this.currentLifeForce,
    required this.maxLifeForce,
  });

  factory PetStatusResponse.fromJson(Map<String, dynamic> json) {
    return PetStatusResponse(
      currentEnergy: int.tryParse(json['currentEnergy']?.toString() ?? '0') ?? 0,
      maxEnergy: int.tryParse(json['maxEnergy']?.toString() ?? '100') ?? 100,
      currentBond: int.tryParse(json['currentBond']?.toString() ?? '0') ?? 0,
      maxBond: int.tryParse(json['maxBond']?.toString() ?? '100') ?? 100,
      currentLifeForce: int.tryParse(json['currentLifeForce']?.toString() ?? '0') ?? 0,
      maxLifeForce: int.tryParse(json['maxLifeForce']?.toString() ?? '100') ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentEnergy': currentEnergy,
      'maxEnergy': maxEnergy,
      'currentBond': currentBond,
      'maxBond': maxBond,
      'currentLifeForce': currentLifeForce,
      'maxLifeForce': maxLifeForce,
    };
  }
}
