import 'package:ezbloc_flutter/ezbloc_flutter.dart';
import 'package:test/test.dart';

import 'bloc_container_test.dart';

void main() => group('TypeAndArg', () {
  test('list equality works', () {
    final list1 = <int>[1, 2, 3];
    final list2 = <int>[1, 2, 3];

    final ta1 = TypeAndArg(CounterBloc, list1);
    final ta2 = TypeAndArg(CounterBloc, list2);

    expect(ta1.hashCode, isNot(ta2.hashCode));
    expect(ta1, ta2);
  });

  test('set equality works', () {
    final set1 = <int>{1, 2, 3};
    final set2 = <int>{1, 2, 3};

    final ta1 = TypeAndArg(CounterBloc, set1);
    final ta2 = TypeAndArg(CounterBloc, set2);

    expect(ta1.hashCode, isNot(ta2.hashCode));
    expect(ta1, ta2);
  });

  test('set equality works', () {
    final map1 = <String, int>{'1': 1, '2': 2, '3': 3};
    final map2 = <String, int>{'1': 1, '2': 2, '3': 3};

    final ta1 = TypeAndArg(CounterBloc, map1);
    final ta2 = TypeAndArg(CounterBloc, map2);

    expect(ta1.hashCode, isNot(ta2.hashCode));
    expect(ta1, ta2);
  });
});