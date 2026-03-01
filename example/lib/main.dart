import 'package:flutter/material.dart';
import 'screens/basic_screen.dart';
import 'screens/counter_screen.dart';
import 'screens/custom_visuals_screen.dart';
import 'screens/list_demo_screen.dart';
import 'screens/multi_threshold_screen.dart';
import 'screens/reveal_actions_screen.dart';
import 'screens/rtl_screen.dart';
import 'screens/templates_screen.dart';

void main() => runApp(const SwipeActionCellExampleApp());

/// Root application widget for the SwipeActionCell demo.
class SwipeActionCellExampleApp extends StatelessWidget {
  /// Creates the example application.
  const SwipeActionCellExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwipeActionCell Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      // DefaultTabController manages the 8-tab state without a StatefulWidget.
      home: DefaultTabController(
        length: 8,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('SwipeActionCell Demo'),
            bottom: const TabBar(
              // isScrollable: true allows more tabs than fit on screen width.
              isScrollable: true,
              tabs: [
                Tab(text: 'Basic'),
                Tab(text: 'Counter'),
                Tab(text: 'Reveal'),
                Tab(text: 'Multi-Zone'),
                Tab(text: 'Custom'),
                Tab(text: 'List'),
                Tab(text: 'RTL'),
                Tab(text: 'Templates'),
              ],
            ),
          ),
          // Each tab maps to one of the 8 screen widgets.
          body: const TabBarView(
            children: [
              BasicScreen(),
              CounterScreen(),
              RevealActionsScreen(),
              MultiThresholdScreen(),
              CustomVisualsScreen(),
              ListDemoScreen(),
              RtlScreen(),
              TemplatesScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
