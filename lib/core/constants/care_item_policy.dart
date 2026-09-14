/// UI guard for the care effects also capped by InventoryService.
/// Unknown effects and unavailable limits remain subject to server validation.
bool isCareItemStatFull({
  required String? effectTypeCode,
  required int energy,
  required int maxEnergy,
  required int lifeForce,
  required int maxLifeForce,
  required int bond,
  required int maxBond,
}) {
  final (current, maximum) = switch (effectTypeCode?.trim().toLowerCase()) {
    'energy' => (energy, maxEnergy),
    'life_force' || 'sml' => (lifeForce, maxLifeForce),
    'bond' => (bond, maxBond),
    _ => (0, 0),
  };
  return maximum > 0 && current >= maximum;
}
