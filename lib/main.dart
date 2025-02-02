import 'package:flutter/material.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  final int maxMissedDays;
  final Map<DateTime, int>
      completedDates; // 0 = empty, 1 = square, 2 = triangle
  final Map<DateTime, (int, int)> streakCache =
      {}; //date to (streak, missedDays)

  int getStreakAtDate(DateTime streakDate) {
    DateTime normalizedStreakDate =
        DateTime(streakDate.year, streakDate.month, streakDate.day);
    DateTime previousDay = streakDate.subtract(const Duration(days: 1));
    if (streakCache.containsKey(previousDay)) {
      final state = completedDates[normalizedStreakDate] ?? 0;
      var (previousStreak, previousMissedDays) = streakCache[previousDay]!;
      if (state == 1) {
        streakCache[normalizedStreakDate] = (previousStreak + 1, 0);
        return previousStreak++;
      } else if (state == 0) {
        int missedDays = previousMissedDays + 1;
        if (missedDays > maxMissedDays) {
          streakCache[normalizedStreakDate] = (0, 0);
          return 0;
        }
        streakCache[normalizedStreakDate] = (previousStreak, missedDays);
        return previousStreak;
      } else if (state == 2) {
        streakCache[normalizedStreakDate] =
            (previousStreak, previousMissedDays);
        return previousStreak;
      }
    }

    int streak = 0;
    int missedDays = 0;

    List sortedDates = completedDates.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    sortedDates = sortedDates
        .where((date) => !date.isAfter(
              DateTime(streakDate.year, streakDate.month, streakDate.day),
            ))
        .toList();

    for (DateTime date in sortedDates) {
      final state = completedDates[date] ?? 0;
      if (state == 1) {
        streak++;
        missedDays = 0;
      } else if (state == 0) {
        missedDays++;
        if (missedDays > maxMissedDays) {
          streakCache[date] = (0, 0);
          break;
        }
      } else if (state == 2) {
        // Triangle day - do not affect streak or missedDays
      }
      streakCache[date] = (streak, missedDays);
    }
    return streak;
  }

  Color getColorForDate(DateTime date) {
    int streakLength = getStreakAtDate(date);

    // Convert base color to HSL
    final hsl = HSLColor.fromColor(color);

    // Calculate intensity based on streak length
    final saturation = (hsl.saturation + (streakLength * 0.07)).clamp(0.5, 1.0);
    final lightness = (hsl.lightness - (streakLength * 0.03)).clamp(0.1, 0.9);

    return hsl.withSaturation(saturation).withLightness(lightness).toColor();
  }

  Color getColorForTriangle(DateTime date) {
    final previousDate = date.subtract(const Duration(days: 1));
    return getColorForDate(previousDate);
  }

  Habit({
    required this.id,
    required this.name,
    required this.color,
    this.maxMissedDays = 0,
    Map<DateTime, int>? completedDates,
  }) : completedDates = completedDates ?? {};
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.value, // Store color as int value
        'completedDates': completedDates.map(
          (key, value) => MapEntry(
            DateTime(key.year, key.month, key.day).toIso8601String(),
            value,
          ),
        ),
        'maxMissedDays': maxMissedDays,
      }..removeWhere((key, value) => value == null);

  factory Habit.fromJson(Map<String, dynamic> json) {
    try {
      return Habit(
        id: json['id'],
        name: json['name'],
        color: Color(json['color'] as int),
        completedDates: (json['completedDates'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                DateTime(
                  DateTime.parse(key).year,
                  DateTime.parse(key).month,
                  DateTime.parse(key).day,
                ),
                value as int,
              ),
            ) ??
            {},
        maxMissedDays: json['maxMissedDays'] ?? 0,
      );
    } catch (e, stack) {
      debugPrint('Error creating Habit from JSON: $e');
      debugPrint(stack.toString());
      // Return a default habit if parsing fails
      return Habit(
        id: DateTime.now().toString(),
        name: 'New Habit',
        color: Colors.blueAccent,
        maxMissedDays: 0,
      );
    }
  }
}

class SimpleTablePage extends StatefulWidget {
  const SimpleTablePage({super.key});

  @override
  State<SimpleTablePage> createState() => _SimpleTablePageState();
}

class _SimpleTablePageState extends State<SimpleTablePage> {
  final List<Habit> _habits = [];
  late final SharedPreferences _prefs;
  final List<Color> _availableColors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.amber,
    Colors.purpleAccent,
    Colors.cyan,
    Colors.orangeAccent,
    Colors.tealAccent,
    Colors.pinkAccent,
    Colors.lightGreenAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final habitsJson = _prefs.getStringList('habits');
      if (habitsJson != null) {
        setState(() {
          _habits.addAll(habitsJson.map((json) {
            try {
              final decoded = jsonDecode(json);
              if (decoded is! Map<String, dynamic>) {
                throw FormatException(
                    'Expected Map, got ${decoded.runtimeType}');
              }
              return Habit.fromJson(decoded);
            } catch (e, stack) {
              debugPrint('Error parsing habit: $e');
              debugPrint(stack.toString());
              // Return a default habit if parsing fails
              return Habit(
                id: DateTime.now().toString(),
                name: 'New Habit',
                color: Colors.blueAccent,
                maxMissedDays: 0,
              );
            }
          }).toList());
        });
      }
    } catch (e, stack) {
      debugPrint('Error loading habits: $e');
      debugPrint(stack.toString());
      // Clear corrupted preferences
      await _prefs.remove('habits');
      setState(() {
        _habits.clear();
      });
    }
  }

  Future<void> _saveHabits() async {
    final habitsJson =
        _habits.map((habit) => jsonEncode(habit.toJson())).toList();
    await _prefs.setStringList('habits', habitsJson);
  }

  List<DateTime> get _dates {
    final now = DateTime.now();
    return List.generate(
        14, (index) => now.subtract(Duration(days: 13 - index)));
  }

  void _addHabit(String name, [int maxMissedDays = 0]) {
    setState(() {
      _habits.add(Habit(
        id: DateTime.now().toString(),
        name: name,
        color: _availableColors[_habits.length % _availableColors.length],
        maxMissedDays: maxMissedDays,
      ));
      _saveHabits();
    });
  }

  void _toggleDate(Habit habit, DateTime date) {
    habit.streakCache.removeWhere((key, _) => key.isAfter(date));
    setState(() {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final currentState = habit.completedDates[normalizedDate] ?? 0;
      habit.completedDates[normalizedDate] = (currentState + 1) % 3;
    });
    _saveHabits();
  }

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        final missedDaysController = TextEditingController(text: '0');
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          title: const Text('Add New Habit',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Habit name',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: missedDaysController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Max missed days (0 for strict)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  _addHabit(
                    textController.text,
                    int.tryParse(missedDaysController.text) ?? 0,
                  );
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
        rightHandSideColumnWidth: 560,
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
    final habit = _habits[index];
    return GestureDetector(
      onLongPress: () => _showEditHabitDialog(index),
      child: Container(
        width: 100,
        height: 40,
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(child: Text(habit.name)),
            Container(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '${habit.getStreakAtDate(DateTime.now())}🔥',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditHabitDialog(int index) {
    final habit = _habits[index];
    final textController = TextEditingController(text: habit.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          title:
              const Text('Edit Habit', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Habit name',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: TextEditingController(
                        text: _habits[index].maxMissedDays.toString()),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Max missed days',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final maxMissed = int.tryParse(value) ?? 0;
                      setState(() {
                        _habits[index] = Habit(
                          id: _habits[index].id,
                          name: _habits[index].name,
                          color: _habits[index].color,
                          maxMissedDays: maxMissed,
                          completedDates: _habits[index].completedDates,
                        );
                      });
                      _saveHabits();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the edit dialog
                      _showDeleteConfirmationDialog(index);
                    },
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                  TextButton(
                    onPressed: () {
                      if (textController.text.isNotEmpty) {
                        _renameHabit(index, textController.text);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Save',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _renameHabit(int index, String newName) {
    setState(() {
      _habits[index] = Habit(
        id: _habits[index].id,
        name: newName,
        color: _habits[index].color,
        maxMissedDays: _habits[index].maxMissedDays,
        completedDates: _habits[index].completedDates,
      );
      _saveHabits();
    });
  }

  void _showDeleteConfirmationDialog(int index) {
    final habit = _habits[index];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          title:
              const Text('Delete Habit', style: TextStyle(color: Colors.white)),
          content: Text(
              'Are you sure you want to delete Habit "${habit.name}"?',
              style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
            ),
            TextButton(
              onPressed: () {
                _deleteHabit(index);
                Navigator.pop(context);
              },
              child: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _deleteHabit(int index) {
    setState(() {
      _habits.removeAt(index);
      _saveHabits();
    });
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
                habit: _habits[index],
                date: date,
              ),
            ));
      }).toList(),
    );
  }
}

Widget _getShapeWidget(
    {required int state, required Habit habit, required DateTime date}) {
  return Container(
    color: Colors.grey[900],
    child: Stack(
      children: [
        if (state == 1) Container(color: habit.getColorForDate(date)),
        if (state == 2)
          ClipPath(
            clipper: TriangleClipper(),
            child: Container(color: habit.getColorForTriangle(date)),
          ),
        if (state == 0) _getMissedDayWidget(habit: habit, date: date),
      ],
    ),
  );
}

class MissedDayPainter extends CustomPainter {
  final Color color;
  final int consecutiveMissed; // 1 for first missed day, 2 for second, etc.
  final int maxMissedDays;

  MissedDayPainter({
    required this.color,
    required this.consecutiveMissed,
    required this.maxMissedDays,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double H = size.height;
    final double W = size.width;

    // Calculate effective heights based on the missed-day index.
    final double H_left =
        ((maxMissedDays - consecutiveMissed + 1) / maxMissedDays) * H;
    final double H_right =
        ((maxMissedDays - consecutiveMissed) / maxMissedDays) * H;

    // Center each edge vertically within the cell.
    final double topLeft = (H - H_left) / 2;
    final double bottomLeft = topLeft + H_left;
    final double topRight = (H - H_right) / 2;
    final double bottomRight = topRight + H_right;

    // Construct the trapezoidal path.
    final path = Path()
      ..moveTo(0, topLeft) // left edge, top
      ..lineTo(W, topRight) // right edge, top
      ..lineTo(W, bottomRight) // right edge, bottom
      ..lineTo(0, bottomLeft) // left edge, bottom
      ..close();

    // Draw the solid tapered shape.
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Now draw vertical stripes with Colors.grey[900].
    const int numberOfStripes = 4;
    final double stripeThickness = (0.5 * W) / numberOfStripes;

    // Clip the canvas to the trapezoidal shape.
    canvas.save();
    canvas.clipPath(path);

    final stripePaint = Paint()
      ..color = Colors.grey[900]!
      ..style = PaintingStyle.fill;

    // Draw the stripes evenly spaced across the cell.
    for (int i = 0; i < numberOfStripes; i++) {
      final double stripeX = (i + 0.5) * (W / numberOfStripes);
      final Rect stripeRect = Rect.fromCenter(
        center: Offset(stripeX, H / 2),
        width: stripeThickness,
        height: H,
      );
      canvas.drawRect(stripeRect, stripePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MissedDayPainter oldDelegate) =>
      oldDelegate.consecutiveMissed != consecutiveMissed ||
      oldDelegate.maxMissedDays != maxMissedDays ||
      oldDelegate.color != color;
}

Widget _getMissedDayWidget({required Habit habit, required DateTime date}) {
  // We assume this widget is only called for cells that are missed (state == 0).
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final state = habit.completedDates[normalizedDate] ?? 0;
  if (state != 0) return Container(); // only for missed days

  // Count consecutive missed days by scanning backward from the cell date.
  int consecutiveMissed = 0;
  DateTime current = date;
  while (true) {
    final norm = DateTime(current.year, current.month, current.day);
    final s = habit.completedDates[norm] ?? 0;
    if (s == 0) {
      consecutiveMissed++;
      // Break early if we already exceed the max allowed.
      if (consecutiveMissed > habit.maxMissedDays) break;
      current = current.subtract(const Duration(days: 1));
    } else if (s == 2) {
      // Triangle day - don't count as missed but continue checking previous days
      current = current.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  // If the consecutive missed count exceeds maxMissedDays, the cell is empty.
  if (consecutiveMissed > habit.maxMissedDays) {
    return Container();
  }

  final lastTrackedDate = date.subtract(Duration(days: consecutiveMissed));
  final color = habit.getColorForDate(lastTrackedDate);

  return CustomPaint(
    size: const Size(40, 40),
    painter: MissedDayPainter(
      color: color,
      consecutiveMissed: consecutiveMissed,
      maxMissedDays: habit.maxMissedDays,
    ),
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
