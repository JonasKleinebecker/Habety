import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class Habit {
  final String id;
  final String name;
  final Color color;
  final Map<DateTime, bool> completedDates;

  Habit({
    required this.id,
    required this.name,
    required this.color,
    Map<DateTime, bool>? completedDates,
  }) : completedDates = completedDates ?? {};
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Habit> _habits = [];
  final List<Color> _availableColors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.amber,
    Colors.purpleAccent,
    Colors.cyan,
  ];
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  List<DateTime> get _dates {
    final now = DateTime.now();
    return List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));
  }

  void _addHabit(String name) {
    setState(() {
      _habits.add(Habit(
        id: DateTime.now().toString(),
        name: name,
        color: _availableColors[_habits.length % _availableColors.length],
      ));
    });
  }

  void _toggleDate(Habit habit, DateTime date) {
    setState(() {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      habit.completedDates[normalizedDate] =
          !(habit.completedDates[normalizedDate] ?? false);
    });
  }

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          title: const Text('Add New Habit',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: textController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Habit name',
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  _addHabit(textController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddHabitDialog,
          ),
        ],
      ),
      body: Row(
        children: [
          // Header
          _buildHabitColumn(),
          // Combined Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitColumn() {
    return Column(
      children: [
        Container(
          height: 60,
          color: Colors.grey[850],
          child: const SizedBox(
            width: 120,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Habits', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            width: 120,
            child: ListView.builder(
              controller: _verticalController,
              itemCount: _habits.length,
              itemBuilder: (context, index) => _buildHabitName(_habits[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      controller: _horizontalController,
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 40.0 * _dates.length,
        child: ListView(
          controller: _verticalController,
          scrollDirection: Axis.vertical,
          children: [
            Table(
              defaultColumnWidth: const FixedColumnWidth(40),
              children: [
                TableRow(
                  children: _dates.map(_buildDateHeader).toList(),
                ),
                ..._habits.map(_buildHabitRow),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return SizedBox(
      height: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getDayAbbreviation(date.weekday),
            style: TextStyle(color: Colors.grey[400]),
          ),
          Text(
            date.day.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitName(Habit habit) {
    return Container(
      height: 40,
      color: Colors.grey[800],
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Text(
        habit.name,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  TableRow _buildHabitRow(Habit habit) {
    return TableRow(
      children: _dates.map((date) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _toggleDate(habit, date),
          child: Container(
            height: 40,
            color: habit.completedDates[
                        DateTime(date.year, date.month, date.day)] ??
                    false
                ? habit.color
                : Colors.grey[900],
          ),
        );
      }).toList(),
    );
  }

  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}
