import 'package:counter_example/main.dart';
import 'package:ezbloc_flutter/ezbloc_flutter.dart';
import 'package:flutter/material.dart';

class CounterText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('You have pushed the button this many times:'),
          context.blocBuilder<CounterBloc>(
            onState: (_, i) => Text(i.toString()),
          ),
        ],
      ),
    );
  }
}
