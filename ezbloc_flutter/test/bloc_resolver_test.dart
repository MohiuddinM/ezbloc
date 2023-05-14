import 'package:ezbloc_flutter/ezbloc_flutter.dart';
import 'package:test/test.dart';

class TestBloc extends Bloc<int> {
  TestBloc(int value) : super(initialState: value);
}

void main() => group('BlocResolver', () {
      late BlocResolver<TestBloc> testResolver;

      setUp(() {
        testResolver = BlocResolver((arg) => TestBloc(arg));
      });

      test('create without cache', () {
        final a = testResolver(arg: 1, useCache: false);
        final b = testResolver(arg: 1, useCache: false);

        expect(identical(a, b), isFalse);
      });

      test('create with cache', () {
        final a = testResolver.create(arg: 2, useCache: true);
        final b = testResolver.create(arg: 2, useCache: true);

        expect(identical(a, b), isTrue);
      });
    });
