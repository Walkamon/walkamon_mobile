import 'package:flutter/foundation.dart';

@immutable
class HomePetAmbientCue {
  const HomePetAmbientCue(this.animation, this.duration);

  final String animation;
  final Duration duration;
}

/// Selects a lightweight Home reaction without mutating pet state on the API.
///
/// Needs always win over decorative reactions. Returning null intentionally
/// leaves a rest beat between ambient actions so the pet does not feel busy.
HomePetAmbientCue? selectHomePetAmbientCue({
  required int energy,
  required int energyMax,
  required int lifeForce,
  required int lifeForceMax,
  required int bond,
  required int bondMax,
  required int hour,
  required int cycle,
}) {
  final energyRatio = _ratio(energy, energyMax);
  final lifeRatio = _ratio(lifeForce, lifeForceMax);
  final bondRatio = _ratio(bond, bondMax);

  if (lifeRatio <= 0.25) {
    return const HomePetAmbientCue('sad', Duration(milliseconds: 5200));
  }
  if (energyRatio <= 0.28) {
    return const HomePetAmbientCue('hungry', Duration(milliseconds: 5000));
  }
  if ((hour >= 22 || hour < 6) && energyRatio < 0.75) {
    return const HomePetAmbientCue('sleep', Duration(milliseconds: 6500));
  }

  final normalizedCycle = cycle.abs() % 5;
  if (normalizedCycle == 4) return null;
  if (bondRatio >= 0.75 && normalizedCycle == 1) {
    return const HomePetAmbientCue('excited', Duration(milliseconds: 4300));
  }

  return switch (normalizedCycle) {
    0 => const HomePetAmbientCue('happy', Duration(milliseconds: 4400)),
    1 => const HomePetAmbientCue('tap_hello', Duration(milliseconds: 3400)),
    2 => const HomePetAmbientCue('happy', Duration(milliseconds: 4200)),
    _ => const HomePetAmbientCue('tap_hello', Duration(milliseconds: 3200)),
  };
}

double _ratio(int value, int maximum) {
  if (maximum <= 0) return 1;
  return (value / maximum).clamp(0.0, 1.0).toDouble();
}
