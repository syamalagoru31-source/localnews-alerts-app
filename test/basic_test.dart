import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Addition test', () {
    int a = 10;
    int b = 20;

    int result = a + b;

    expect(result, 30);
  });
}
