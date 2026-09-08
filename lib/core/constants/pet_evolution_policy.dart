/// Offline presentation defaults. A received API eligibility decision takes precedence.
abstract final class PetEvolutionPolicy {
  static const firstEvolutionLevel = 15;
  static const secondEvolutionLevel = 30;

  static bool isBranch(String? affinity) => const {
    'dawn',
    'moonlight',
    'warm_sun',
  }.contains(affinity?.trim().toLowerCase());

  static int? nextLevel({required bool evolved, required int stageNo}) =>
      !evolved
      ? firstEvolutionLevel
      : (stageNo < 2 ? secondEvolutionLevel : null);
}
