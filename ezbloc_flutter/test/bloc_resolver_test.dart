import 'package:ezbloc_flutter/ezbloc_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

final class IntBloc extends Bloc<int> {
  IntBloc(int value) : super(initialState: value);
}

final class IntBloc2 extends Bloc<int> {
  IntBloc2(int value) : super(initialState: value);
}

void main() => group('BlocResolver', () {
      late BlocResolver<IntBloc, int> intResolver;
      late BlocResolver<IntBloc2, int> intResolver2;

      setUp(() {
        intResolver = BlocResolver((arg) => IntBloc(arg ?? 0));
        intResolver2 = BlocResolver((arg) => IntBloc2(arg ?? 0));
      });

      test('create without cache', () {
        final a = intResolver(arg: 1, useCache: false);
        final b = intResolver(arg: 1, useCache: false);

        expect(identical(a, b), isFalse);
      });

      test('create with cache same arg', () {
        final a = intResolver.create(arg: 1, useCache: true);
        final b = intResolver.create(arg: 1, useCache: true);

        expect(identical(a, b), isTrue);
      });

      test('create with cache different args', () {
        final a = intResolver.create(arg: 1, useCache: true);
        final b = intResolver.create(arg: 2, useCache: true);

        expect(identical(a, b), isFalse);
      });

      test('create with cache different types same arg', () {
        final a = intResolver.create(arg: 1, useCache: true);
        final b = intResolver2.create(arg: 1, useCache: true);

        expect(identical(a, b), isFalse);
      });

      test('clearing cache same type', () {
        final a = intResolver.create(arg: 2, useCache: true);
        final b = intResolver2.create(arg: 2, useCache: true);

        intResolver.clearCache();

        final c = intResolver.create(arg: 2, useCache: true);
        final d = intResolver2.create(arg: 2, useCache: true);

        expect(identical(a, c), isFalse);
        expect(identical(b, d), isTrue);
      });

      test('clearing cache all types', () {
        final a = intResolver.create(arg: 2, useCache: true);
        final b = intResolver2.create(arg: 2, useCache: true);

        BlocResolver.clearAllCaches();

        final c = intResolver.create(arg: 2, useCache: true);
        final d = intResolver2.create(arg: 2, useCache: true);

        expect(identical(a, c), isFalse);
        expect(identical(b, d), isFalse);
      });

      test('always return injected', () {
        intResolver.inject(IntBloc(3));
        final a = intResolver.create(arg: 2, useCache: true);

        expect(a.state, 3);
      });

      test('return normal after remove injected', () {
        intResolver.inject(IntBloc(3));
        final a = intResolver.create(arg: 2, useCache: true);

        intResolver.removeInjection();
        final b = intResolver.create(arg: 2, useCache: true);

        expect(a.state, 3);
        expect(b.state, 2);
      });
    });
