import 'package:flutter/material.dart';
import 'providers/task_repository.dart';
import 'providers/task_scope.dart';
import 'widgets/task_list.dart';

void main() {
  runApp(
    TaskScope(
      repository: TaskRepository(),
      child: const SwipeActionCellExample(),
    ),
  );
}

class SwipeActionCellExample extends StatelessWidget {
  const SwipeActionCellExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwipeActionCell Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simple responsiveness: check width for layout adjustments
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 800;
    final taskRepository = TaskScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Swipe Actions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => taskRepository.refreshTasks(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Tasks', icon: Icon(Icons.list_alt)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle_outline)),
          ],
        ),
      ),
      body: Center(
        child: Container(
          // Constrain width on large screens for better readability
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 1000 : double.infinity,
          ),
          child: TabBarView(
            controller: _tabController,
            children: const [
              TaskList(showCompleted: false),
              TaskList(showCompleted: true),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Task: Feature coming soon!')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}
