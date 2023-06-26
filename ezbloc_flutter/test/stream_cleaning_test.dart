import 'package:ezbloc_flutter/ezbloc_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'stream_cleaning_test.mocks.dart';

@GenerateNiceMocks([MockSpec<BlocMonitor<CounterBloc, int>>()])
void main() {
  late MockBlocMonitor mockBlocMonitor;

  setUp(() {
    mockBlocMonitor = MockBlocMonitor();
  });

  testWidgets(
    'stream should get cleaned after there are no listeners',
    (tester) async {
      final bloc = CounterBloc(monitor: mockBlocMonitor);
      final key = GlobalKey<MultipleBuildersState>();

      await tester.pumpWidget(
        MaterialApp(
          home: MultipleBuilders(
            key: key,
            bloc: bloc,
          ),
        ),
      );

      expect(bloc.hasState, isTrue);
      verify(mockBlocMonitor.onInit(bloc, 0)).called(1);
      verifyNever(mockBlocMonitor.onStreamDispose(any));
      verifyNever(mockBlocMonitor.onStreamListener(any));

      key.currentState!.setBuilders(3);
      await tester.pumpAndSettle();

      verifyNever(mockBlocMonitor.onStreamDispose(any));
      verify(mockBlocMonitor.onStreamListener(any)).called(3);

      key.currentState!.setBuilders(1);
      await tester.pumpAndSettle();

      verifyNever(mockBlocMonitor.onStreamDispose(any));

      key.currentState!.setBuilders(0);
      await tester.pumpAndSettle();

      await tester.pump(Duration(seconds: 5));

      verify(mockBlocMonitor.onStreamDispose(any)).called(1);
    },
  );
}

final class CounterBloc extends Bloc<int> {
  CounterBloc({super.monitor}) : super(initialState: 0);

  void increment() => setState(state + 1);

  void decrement() => setState(state - 1);
}

class MultipleBuilders extends StatefulWidget {
  const MultipleBuilders({super.key, required this.bloc});

  final CounterBloc bloc;

  @override
  State<MultipleBuilders> createState() => MultipleBuildersState();
}

class MultipleBuildersState extends State<MultipleBuilders> {
  int nBuilders = 0;

  void setBuilders(int n) => setState(() => nBuilders = n);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (nBuilders > 0)
            widget.bloc.builder(
              onState: (_, s) => Text(s.toString()),
            ),
          if (nBuilders > 1)
            widget.bloc.builder(
              onState: (_, s) => Text(s.toString()),
            ),
          if (nBuilders > 2)
            widget.bloc.builder(
              onState: (_, s) => Text(s.toString()),
            ),
        ],
      ),
    );
  }
}
