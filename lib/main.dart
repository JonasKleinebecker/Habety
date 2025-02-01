import 'package:flutter/material.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habety',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
        ),
      ),
      home: SimpleTablePage(),
    );
  }
}

class Habit {
  final String id;
  final String name;
  final Color color;
  final Map<DateTime, int>
      completedDates; // 0 = empty, 1 = square, 2 = triangle

  Habit({
    required this.id,
    required this.name,
    required this.color,
    Map<DateTime, int>? completedDates,
  }) : completedDates = completedDates ?? {};
}

class SimpleTablePage extends StatefulWidget {
  const SimpleTablePage({super.key});

  @override
  State<SimpleTablePage> createState() => _SimpleTablePageState();
}

class _SimpleTablePageState extends State<SimpleTablePage> {
  final List<Habit> _habits = [];
  final List<Color> _availableColors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.amber,
    Colors.purpleAccent,
    Colors.cyan,
  ];

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
      final currentState = habit.completedDates[normalizedDate] ?? 0;
      habit.completedDates[normalizedDate] = (currentState + 1) % 3;
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
      body: HorizontalDataTable(
        leftHandSideColumnWidth: 100,
        rightHandSideColumnWidth: 280,
        isFixedHeader: true,
        headerWidgets: _getTitleWidget(),
        isFixedFooter: false,
        leftSideItemBuilder: _generateFirstColumnRow,
        rightSideItemBuilder: _generateRightHandSideColumnRow,
        itemCount: _habits.length,
        leftHandSideColBackgroundColor: Colors.grey[850]!,
        rightHandSideColBackgroundColor: Colors.grey[800]!,
        itemExtent: 40,
      ),
    );
  }

  List<Widget> _getTitleWidget() {
    return [
      Container(
        width: 100,
        height: 60,
        padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
        alignment: Alignment.centerLeft,
        child:
            Text('Habit', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      ..._dates.map((date) {
        return _getDateItemWidget(date);
      }),
    ];
  }

  Widget _getDateItemWidget(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return SizedBox(
      height: 60,
      width: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getDayAbbreviation(date.weekday),
            style: TextStyle(color: Colors.grey[400]),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: isToday
                ? BoxDecoration(
                    color: Colors.grey[700],
                    shape: BoxShape.circle,
                  )
                : null,
            child: Center(
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  color: isToday ? Colors.white : Colors.white,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _generateFirstColumnRow(BuildContext context, int index) {
    return Container(
      width: 100,
      height: 40,
      padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
      alignment: Alignment.centerLeft,
      child: Text(_habits[index].name),
    );
  }

  Widget _generateRightHandSideColumnRow(BuildContext context, int index) {
    return Row(
      children: _dates.map((date) {
        return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _toggleDate(_habits[index], date),
            child: Container(
              width: 40,
              height: 40,
              child: _getShapeWidget(
                state: _habits[index].completedDates[
                        DateTime(date.year, date.month, date.day)] ??
                    0,
                color: _habits[index].color,
              ),
            ));
      }).toList(),
    );
  }
}

Widget _getShapeWidget({required int state, required Color color}) {
  return Container(
    color: Colors.grey[900], // Row background color
    child: switch (state) {
      1 => Container(color: color),
      2 => ClipPath(
          clipper: TriangleClipper(),
          child: Container(color: color),
        ),
      _ => null,
    },
  );
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0); // Upper left corner
    path.lineTo(0, size.height); // Lower left corner
    path.lineTo(size.width, size.height); // Lower right corner
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
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
