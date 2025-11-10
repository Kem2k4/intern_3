import 'package:flutter_test/flutter_test.dart';

import 'package:core_ui/core_ui.dart';

void main() {
  test('AppThemes provides light and dark themes', () {
    expect(AppThemes.lightTheme, isNotNull);
    expect(AppThemes.darkTheme, isNotNull);
  });
}
