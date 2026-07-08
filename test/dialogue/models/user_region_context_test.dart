import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/models/user_region_context.dart';

void main() {
  test('stores approximate region only without GPS or address fields', () {
    const context = UserRegionContext(
      countryCode: 'KR',
      regionLabel: '서울',
      precision: 'province',
      source: 'user_selected',
    );

    expect(context.countryCode, 'KR');
    expect(context.regionLabel, '서울');
    expect(context.localityLabel, isNull);
    expect(context.precision, 'province');
    expect(context.source, 'user_selected');

    final fieldNames = File(
      'lib/dialogue/models/user_region_context.dart',
    ).readAsStringSync().toLowerCase();

    expect(fieldNames, isNot(contains('latitude')));
    expect(fieldNames, isNot(contains('longitude')));
    expect(fieldNames, isNot(contains('gps')));
    expect(fieldNames, isNot(contains('address')));
    expect(fieldNames, isNot(contains('street')));
    expect(fieldNames, isNot(contains('home')));
  });
}
