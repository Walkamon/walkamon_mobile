import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/data/models/pet_evolution_models.dart';

void main() {
  group('evolution models', () {
    test('parses pet overview and evolution stages from API payload', () {
      final overview = PetOverviewResponse.fromJson({
        'petId': 'pet-1',
        'nickname': 'chothanh',
        'formName': 'Tinh Linh Nắng Ấm',
        'affinityCode': 'warm_sun',
        'level': 15,
        'currentExp': 240,
        'maxExp': 500,
        'currentEnergy': 80,
        'maxEnergy': 100,
        'currentLifeForce': 90,
        'maxLifeForce': 100,
        'currentBond': 100,
        'maxBond': 100,
        'stageNo': 1,
        'stageName': 'Dạng Chói',
        'animationType': 'idle',
        'canEvolve': true,
        'nextEvolutionLevel': 15,
      });

      expect(overview.nickname, 'chothanh');
      expect(overview.canEvolve, isTrue);
      expect(overview.nextEvolutionLevel, 15);

      final stages = [
        PetEvolutionStageResponse.fromJson({
          'stageId': 'stage-1',
          'stageNo': 1,
          'stageName': 'Dạng Chói',
          'stateUrl': 'https://example.com/1.png',
          'requiredLevel': 5,
          'isCurrent': true,
          'isUnlocked': true,
          'animations': [
            {
              'typeAnimation': 'idle',
              'animationUrl': 'https://example.com/idle.json',
            },
          ],
        }),
      ];

      expect(stages.single.stageName, 'Dạng Chói');
      expect(
        stages.single.animations.single.animationUrl,
        'https://example.com/idle.json',
      );
    });
  });
}
