import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/motion/pet_progression_change.dart';

void main() {
  PetProgressionSnapshot snap(int level, {String pet = 'one', int exp = 20}) =>
      PetProgressionSnapshot(petId: pet, level: level, exp: exp, maxExp: 100);
  test(
    'first load is silent and a multi-level batch produces one actual change',
    () {
      final tracker = PetProgressionTracker();
      tracker.accept(snap(8));
      expect(tracker.latest, isNull);
      tracker.accept(snap(11, exp: 42));
      expect(tracker.latest!.before.level, 8);
      expect(tracker.latest!.after.level, 11);
      expect(tracker.latest!.after.exp, 42);
      final id = tracker.latest!.id;
      tracker.accept(snap(11, exp: 42));
      expect(tracker.latest!.id, id);
    },
  );
  test('pet switch and logout reset the baseline', () {
    final tracker = PetProgressionTracker();
    tracker.accept(snap(1));
    tracker.accept(snap(2));
    tracker.accept(snap(30, pet: 'two'));
    expect(tracker.latest, isNull);
    tracker.reset();
    tracker.accept(snap(50));
    expect(tracker.latest, isNull);
  });
  test('negative corrections and EXP-only updates never celebrate a level', () {
    final tracker = PetProgressionTracker();
    tracker.accept(snap(8));
    tracker.accept(snap(7));
    tracker.accept(snap(7, exp: 90));
    expect(tracker.latest, isNull);
  });
}
