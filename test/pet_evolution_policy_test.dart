import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/constants/pet_evolution_policy.dart';

void main() {
  test('starter becomes eligible at 15, not automatically evolved', () {
    expect(PetEvolutionPolicy.nextLevel(evolved: false, stageNo: 1), 15);
    expect(PetEvolutionPolicy.isBranch('sprout'), isFalse);
  });
  test('branch first stage targets 30 and second stage is final', () {
    expect(PetEvolutionPolicy.nextLevel(evolved: true, stageNo: 1), 30);
    expect(PetEvolutionPolicy.nextLevel(evolved: true, stageNo: 2), isNull);
    for (final affinity in ['dawn', 'moonlight', 'warm_sun']) {
      expect(PetEvolutionPolicy.isBranch(affinity), isTrue);
    }
  });
}
