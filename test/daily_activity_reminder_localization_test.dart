import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/l10n/app_localizations_en.dart';
import 'package:walkamon_mobile/l10n/app_localizations_vi.dart';

void main() {
  test('daily activity reminder has English and Vietnamese inbox labels', () {
    expect(
      AppLocalizationsEn().notificationsTypeDailyStepGoalReminder,
      'Daily activity reminder',
    );
    expect(
      AppLocalizationsVi().notificationsTypeDailyStepGoalReminder,
      'Nhắc mục tiêu vận động hằng ngày',
    );
  });
}
