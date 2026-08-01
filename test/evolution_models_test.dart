import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/data/models/pet_evolution_models.dart';
import 'package:walkamon_mobile/widgets/pet_runtime/pet_runtime_preview.dart';

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

    test('parses pet runtime logical references from evolution APIs', () {
      final reference = parsePetRuntimeAssetReference(
        'asset://pet-runtime-v7.2/dawn/stage2/idle_front',
      );

      expect(reference, isNotNull);
      expect(reference!.affinityCode, 'dawn');
      expect(reference.stageNo, 2);
      expect(reference.animationType, 'idle_front');
      expect(
        parsePetRuntimeAssetReference(
          'assets/Mobile/Tinh Linh Bình Minh/stage2/pvp/race/race_F01.png',
        ),
        isNull,
      );
    });

    test('keeps preview logical stage image for runtime resolution', () {
      final preview = PetEvolutionPreviewResponse.fromJson({
        'petId': 'pet-dawn',
        'petName': 'Lumina Bình Minh',
        'stages': [
          {
            'stageNo': 1,
            'stageName': 'Bình Minh Stage 1',
            'stageImage': 'asset://pet-runtime-v7.2/dawn/stage1/idle_front',
            'requiredLevel': 5,
            'animations': const [],
          },
        ],
      });

      final stage = preview.stages.single;
      final reference = parsePetRuntimeAssetReference(stage.stageImage);
      expect(reference?.affinityCode, 'dawn');
      expect(reference?.stageNo, stage.stageNo);
    });

    test('resolves a logical evolution stage to its runtime clip', () {
      final reference = parsePetRuntimeAssetReference(
        'asset://pet-runtime-v7.2/dawn/stage1/idle_front',
      );
      final formKey = resolvePetRuntimeFormKey(
        reference!.affinityCode,
        reference.stageNo,
      );
      final clipKey = resolvePetRuntimeClipKey(
        animations: const {'dawn_stage1_idle_front': <String, dynamic>{}},
        formKey: formKey,
        affinityCode: reference.affinityCode,
        animationType: reference.animationType,
      );

      expect(formKey, 'dawn_stage1');
      expect(clipKey, 'dawn_stage1_idle_front');
    });
  });
}
