import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/screen/home/home_pet_ambient.dart';

void main() {
  HomePetAmbientCue? cue({
    int energy = 100,
    int life = 100,
    int bond = 50,
    int hour = 12,
    int cycle = 0,
  }) => selectHomePetAmbientCue(
    energy: energy,
    energyMax: 100,
    lifeForce: life,
    lifeForceMax: 100,
    bond: bond,
    bondMax: 100,
    hour: hour,
    cycle: cycle,
  );

  test('needs override decorative ambient reactions', () {
    expect(cue(life: 20)?.animation, 'sad');
    expect(cue(energy: 20)?.animation, 'hungry');
  });

  test('late low-energy pet eases into sleep', () {
    expect(cue(energy: 60, hour: 23)?.animation, 'sleep');
    expect(cue(energy: 100, hour: 23)?.animation, isNot('sleep'));
  });

  test('high bond unlocks an excited ambient beat', () {
    expect(cue(bond: 90, cycle: 1)?.animation, 'excited');
  });

  test('cycle includes a rest beat', () {
    expect(cue(cycle: 4), isNull);
  });
}
