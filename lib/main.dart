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
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

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
      body: Column(
        children: [
          // Header with synchronized scrolling
          _buildHeader(),
          // Content
          Expanded(
            child: Row(
              children: [
                // Pinned Habit Names
                SizedBox(
                  width: 120,
                  child: ListView.builder(
                    controller: _verticalScrollController,
                    itemCount: _habits.length,
                    itemBuilder: (context, index) {
                      final habit = _habits[index];
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
                    },
                  ),
                ),
                // Scrollable Days Grid
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      // Synchronize vertical scrolling
                      if (scrollNotification is ScrollUpdateNotification) {
                        _verticalScrollController.jumpTo(
                          _verticalScrollController.offset +
                              scrollNotification.scrollDelta!,
                        );
                      }
                      return true;
                    },
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 40.0 * _dates.length,
                        child: ListView(
                          controller: _verticalScrollController,
                          scrollDirection: Axis.vertical,
                          children: [
                            Table(
                              defaultColumnWidth: const FixedColumnWidth(40.0),
                              children: _habits
                                  .map((habit) => _buildHabitRow(habit))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
      color: Colors.grey[850],
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Habits',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _dates.map((date) => _buildDateHeader(date)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return SizedBox(
      width: 40,
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
