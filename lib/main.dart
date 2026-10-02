import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// =============================================================================
// CAMPUS PULSE — single-file implementation
// =============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const CampusPulseApp());
}

// ------------------------------- THEME ---------------------------------------
class C {
  C._();
  static const bg = Color(0xFF0A0E16);
  static const side = Color(0xFF0D121C);
  static const card = Color(0xFF111826);
  static const card2 = Color(0xFF161F30);
  static const border = Color(0xFF1F2A3D);
  static const blue = Color(0xFF4DA3FF);
  static const red = Color(0xFFFF5B5B);
  static const green = Color(0xFF22D37A);
  static const amber = Color(0xFFFFB443);
  static const pink = Color(0xFFFF7BAC);
  static const text = Color(0xFFF2F5FA);
  static const sub = Color(0xFF93A0B8);
  static const mute = Color(0xFF5E6B82);
}

class CampusPulseApp extends StatelessWidget {
  const CampusPulseApp({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'Campus Pulse',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: C.bg,
        colorScheme: base.colorScheme.copyWith(
            primary: C.blue, secondary: C.green, surface: C.card, error: C.red),
        textTheme:
            base.textTheme.apply(bodyColor: C.text, displayColor: C.text),
        dividerColor: C.border,
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: C.side,
          indicatorColor: C.blue.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ------------------------------- MODELS --------------------------------------
const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

String hm(int m) =>
    '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
int _t(int h, int m) => h * 60 + m;

class Exam {
  final String code, name, slot, hall;
  final DateTime date;
  final List<String> units;
  Exam(this.code, this.name, this.date, this.slot, this.hall, this.units);

  int get daysLeft {
    final n = DateTime.now();
    return DateTime(date.year, date.month, date.day)
        .difference(DateTime(n.year, n.month, n.day))
        .inDays;
  }

  bool get urgent => daysLeft >= 0 && daysLeft <= 3;
  String get dateLabel =>
      '${_months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}';
  String get countdown {
    final d = daysLeft;
    if (d < 0) return 'Completed';
    if (d == 0) return 'Today';
    if (d == 1) return 'Tomorrow';
    return 'In $d days';
  }
}

class Subject {
  final String code, name;
  final int attended, total, remaining;
  final Color color;
  const Subject(this.code, this.name, this.attended, this.total, this.remaining,
      this.color);
  double get pct => total == 0 ? 0 : attended / total * 100;
  bool get safe => pct >= 75;
}

class ClassSlot {
  final String name, code, room, faculty;
  final int start, end; // minutes from midnight
  final Color color;
  const ClassSlot(this.name, this.code, this.room, this.faculty, this.start,
      this.end, this.color);
}

class Notice {
  final String title, body, category, ago;
  final Color color;
  final IconData icon;
  final bool important;
  const Notice(
      this.title, this.body, this.category, this.color, this.icon, this.ago,
      {this.important = false});
}

// ------------------------------- MOCK DATA -----------------------------------
class Mock {
  Mock._();

  // Exam dates are relative to today so the reminder popup can always be tested.
  // Change the `days:` values to try different scenarios.
  static final exams = <Exam>[
    Exam(
        '21CSC201J',
        'Data Structures & Algorithms',
        DateTime.now().add(const Duration(days: 2)),
        '10:00 AM – 12:00 PM',
        'TP Block · Hall 4', [
      'Arrays, linked lists & stacks',
      'Trees & balanced trees (AVL, B-Tree)',
      'Graphs: BFS, DFS, shortest paths',
      'Sorting, hashing & dynamic programming',
    ]),
    Exam(
        '21CSC302T',
        'Artificial Intelligence',
        DateTime.now().add(const Duration(days: 6)),
        '2:00 PM – 4:00 PM',
        'TP Block · Hall 1', [
      'Search strategies & heuristics',
      'Supervised learning',
      'Neural networks & backpropagation',
      'Clustering & PCA',
    ]),
    Exam(
        '21MAB204T',
        'Mathematics III',
        DateTime.now().add(const Duration(days: 11)),
        '10:00 AM – 12:00 PM',
        'Tech Park · Hall 7', [
      'Fourier series',
      'Laplace transforms',
      'Z-transforms',
      'Partial differential equations',
    ]),
  ];

  static const subjects = <Subject>[
    Subject('21CSC201J', 'Data Structures & Algorithms', 10, 13, 14, C.blue),
    Subject('21CSC302T', 'Artificial Intelligence', 9, 12, 16, C.green),
    Subject('21CSC304T', 'Computer Networks', 12, 13, 12, C.pink),
    Subject('21MAB204T', 'Mathematics III', 9, 14, 15, C.amber),
  ];

  static int get attended => subjects.fold(0, (s, e) => s + e.attended);
  static int get total => subjects.fold(0, (s, e) => s + e.total);
  static double get overall => total == 0 ? 0 : attended / total * 100;

  static Subject get best => subjects.reduce((a, b) => a.pct >= b.pct ? a : b);
  static Subject get worst => subjects.reduce((a, b) => a.pct <= b.pct ? a : b);

  // Day order 1–5 → classes
  static final Map<int, List<ClassSlot>> timetable = {
    1: [
      ClassSlot('Data Structures & Algorithms', '21CSC201J', 'TP 402',
          'Dr. Kavitha Rao', _t(8, 45), _t(9, 35), C.blue),
      ClassSlot('Mathematics III', '21MAB204T', 'UB 210', 'Dr. R. Nair',
          _t(9, 40), _t(10, 30), C.amber),
      ClassSlot('Computer Networks', '21CSC304T', 'UB 503', 'Prof. S. Iyer',
          _t(13, 15), _t(14, 5), C.pink),
    ],
    2: [
      ClassSlot('Artificial Intelligence', '21CSC302T', 'TP 201',
          'Dr. Arvind Menon', _t(9, 40), _t(10, 30), C.green),
      ClassSlot('Mathematics III', '21MAB204T', 'UB 210', 'Dr. R. Nair',
          _t(10, 45), _t(11, 35), C.amber),
    ],
    3: [
      ClassSlot('Artificial Intelligence', '21CSC302T', 'Lab 3 · TP Block',
          'Dr. Arvind Menon', _t(8, 45), _t(10, 30), C.green),
      ClassSlot('Data Structures & Algorithms', '21CSC201J', 'TP 402',
          'Dr. Kavitha Rao', _t(10, 45), _t(11, 35), C.blue),
      ClassSlot('Computer Networks', '21CSC304T', 'UB 503', 'Prof. S. Iyer',
          _t(13, 15), _t(14, 5), C.pink),
    ],
    4: [
      ClassSlot('Mathematics III', '21MAB204T', 'UB 210', 'Dr. R. Nair',
          _t(8, 45), _t(9, 35), C.amber),
      ClassSlot('Computer Networks', '21CSC304T', 'UB 503', 'Prof. S. Iyer',
          _t(10, 45), _t(11, 35), C.pink),
    ],
    5: [
      ClassSlot('Data Structures & Algorithms', '21CSC201J', 'TP 402',
          'Dr. Kavitha Rao', _t(9, 40), _t(10, 30), C.blue),
      ClassSlot('Artificial Intelligence', '21CSC302T', 'TP 201',
          'Dr. Arvind Menon', _t(13, 15), _t(14, 5), C.green),
    ],
  };

  static const notices = <Notice>[
    Notice(
        'End Semester Hall Tickets',
        'Hall tickets are now available on the portal. Download and carry a printed copy along with your ID card. Download before Oct 2.',
        'Exams',
        C.red,
        Icons.menu_book_outlined,
        '4h',
        important: true),
    Notice(
        'Academic calendar updated',
        'The revised academic calendar has been uploaded. Working Saturdays have been added; check the department notice board for section-wise details.',
        'Academic',
        C.blue,
        Icons.event_note_outlined,
        '1d'),
    Notice(
        'Pre-placement talk',
        'A pre-placement talk for pre-final year students will be held this week. Eligibility: CGPA 7.5+ and no active backlogs.',
        'Placements',
        C.green,
        Icons.work_outline,
        '2d',
        important: true),
    Notice(
        'Competitive programming workshop',
        'A two-day hands-on workshop on advanced data structures and contest strategy. Limited seats; register through the student club portal.',
        'Events',
        C.amber,
        Icons.celebration_outlined,
        '3d'),
  ];
}

// ------------------------------- AUTH ----------------------------------------

class AuthResult {
  final bool success;
  final String name;
  final String message;

  const AuthResult.ok(this.name)
      : success = true,
        message = '';

  const AuthResult.fail(this.message)
      : success = false,
        name = '';
}

class AuthService {
  AuthService._();

  static Future<AuthResult> login(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        return AuthResult.ok(
          credential.user!.displayName ?? 'Student',
        );
      }

      return const AuthResult.fail('Login failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return const AuthResult.fail('Invalid email or password.');
        case 'invalid-email':
          return const AuthResult.fail('Please enter a valid email address.');
        case 'too-many-requests':
          return const AuthResult.fail(
              'Too many attempts. Please try again later.');
        case 'network-request-failed':
          return const AuthResult.fail(
              'Network error. Check your internet connection.');
        default:
          return AuthResult.fail(e.message ?? 'Sign-in failed.');
      }
    } catch (_) {
      return const AuthResult.fail('Could not sign in. Please try again.');
    }
  }
}

// ------------------------------- APP STATE -----------------------------------
class AppState extends ChangeNotifier {
  String name = 'Student';
  String regNo = '';
  bool alertsEnabled = true;
  bool remindersShown = false; // popups show once per login session

  void login(String reg, String n) {
    regNo = reg;
    name = n;
    remindersShown = false;
    notifyListeners();
  }

  void setAlerts(bool v) {
    alertsEnabled = v;
    notifyListeners();
  }
}

final app = AppState();

class Clock {
  static DateTime get now => DateTime.now();
  static int? get dayOrder => now.weekday > 5 ? null : (now.weekday % 5) + 1;
  static List<ClassSlot> get today =>
      dayOrder == null ? [] : (Mock.timetable[dayOrder] ?? []);
  static String get weekday => _weekdays[now.weekday - 1];
  static String get greeting {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static ClassSlot? get nextClass {
    final m = now.hour * 60 + now.minute;
    for (final c in today) {
      if (c.start > m) return c;
    }
    return null;
  }
}

// =============================================================================
// EXAM REMINDER POPUPS (fires for exams 0–3 days away)
// =============================================================================
Future<void> showExamReminders(BuildContext context,
    {bool force = false}) async {
  if (!force && (!app.alertsEnabled || app.remindersShown)) return;
  app.remindersShown = true;

  final due = Mock.exams.where((e) => e.urgent).toList()
    ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

  if (due.isEmpty) {
    if (force && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No exams in the next 3 days 🎉'),
          behavior: SnackBarBehavior.floating));
    }
    return;
  }

  for (var i = 0; i < due.length; i++) {
    if (!context.mounted) return;
    final openSyllabus = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ExamReminderDialog(exam: due[i], index: i + 1, count: due.length),
    );
    if (openSyllabus == true && context.mounted) {
      await showExamSheet(context, due[i]);
    }
  }
}

class ExamReminderDialog extends StatelessWidget {
  final Exam exam;
  final int index, count;
  const ExamReminderDialog(
      {super.key,
      required this.exam,
      required this.index,
      required this.count});

  @override
  Widget build(BuildContext context) {
    final color = exam.daysLeft <= 1 ? C.red : C.amber;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 40)
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(Icons.alarm_rounded, color: color, size: 30),
            ),
            const SizedBox(height: 14),
            Text('EXAM REMINDER${count > 1 ? '  ·  $index OF $count' : ''}',
                style: TextStyle(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Text(exam.countdown,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(exam.name,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${exam.code} · ${exam.dateLabel}',
                style: const TextStyle(color: C.sub, fontSize: 13)),
            const SizedBox(height: 16),
            _InfoRow(Icons.schedule_rounded, exam.slot),
            const SizedBox(height: 8),
            _InfoRow(Icons.location_on_outlined, exam.hall),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: C.sub,
                      side: const BorderSide(color: C.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('View syllabus',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: C.card2, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, size: 16, color: C.sub),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ]),
      );
}

Future<void> showExamSheet(BuildContext context, Exam exam) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _Sheet(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exam.name,
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${exam.code} · ${exam.dateLabel} · ${exam.countdown}',
                style: const TextStyle(color: C.sub, fontSize: 13)),
            const SizedBox(height: 16),
            _InfoRow(Icons.schedule_rounded, exam.slot),
            const SizedBox(height: 8),
            _InfoRow(Icons.location_on_outlined, exam.hall),
            const SizedBox(height: 20),
            const Text('Syllabus',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...exam.units.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: C.blue.withValues(alpha: 0.15),
                              shape: BoxShape.circle),
                          child: Text('${e.key + 1}',
                              style: const TextStyle(
                                  color: C.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(e.value,
                              style:
                                  const TextStyle(color: C.sub, fontSize: 14)),
                        )),
                      ]),
                )),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Hall ticket download started…'),
                      behavior: SnackBarBehavior.floating));
                },
                icon: const Icon(Icons.badge_outlined, size: 18),
                label: const Text('Download hall ticket'),
                style: FilledButton.styleFrom(
                    backgroundColor: C.blue,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ]),
    ),
  );
}

class _Sheet extends StatelessWidget {
  final Widget child;
  const _Sheet({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
            color: C.side,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                22, 12, 22, 22 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: C.border, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 18),
              Align(alignment: Alignment.centerLeft, child: child),
            ]),
          ),
        ),
      );
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const Panel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(18),
      this.onTap});
  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.border)),
      child: child,
    );
    if (onTap == null) return box;
    return InkWell(
        borderRadius: BorderRadius.circular(18), onTap: onTap, child: box);
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill(this.text, this.color, {super.key, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4)
          ],
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ]),
      );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final Color trailingColor;
  const SectionTitle(this.title,
      {super.key, this.trailing, this.trailingColor = C.blue});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          if (trailing != null)
            Text(trailing!,
                style: TextStyle(
                    color: trailingColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
        ]),
      );
}

Widget twoCol(bool wide, Widget a, Widget b, {int flexA = 1, int flexB = 1}) {
  if (!wide) return Column(children: [a, const SizedBox(height: 16), b]);
  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(flex: flexA, child: a),
    const SizedBox(width: 16),
    Expanded(flex: flexB, child: b),
  ]);
}

class PageFrame extends StatelessWidget {
  final bool wide;
  final List<Widget> children;
  const PageFrame({super.key, required this.wide, required this.children});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TopBar(wide: wide),
      const Divider(height: 1, color: C.border),
      Expanded(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 24, wide ? 32 : 16, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children),
            ),
          ),
        ),
      ),
    ]);
  }
}

class TopBar extends StatelessWidget {
  final bool wide;
  const TopBar({super.key, required this.wide});
  @override
  Widget build(BuildContext context) {
    final d = Clock.dayOrder;
    final dueCount = Mock.exams.where((e) => e.urgent).length;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 16, vertical: 16),
      child: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: app,
          builder: (context, _) => Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${Clock.weekday.toUpperCase()}${d != null ? ' · DAY ORDER $d' : ' · NO CLASSES'}',
                        style: const TextStyle(
                            color: C.sub,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6)),
                    const SizedBox(height: 2),
                    Text('${Clock.greeting}, ${app.name}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: wide ? 28 : 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4)),
                  ]),
            ),
            IconButton(
              tooltip: 'Exam reminders',
              onPressed: () => showExamReminders(context, force: true),
              icon: Stack(clipBehavior: Clip.none, children: [
                const Icon(Icons.notifications_none_rounded, size: 24),
                if (dueCount > 0)
                  Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                              color: C.red, shape: BoxShape.circle))),
              ]),
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 19,
              backgroundColor: C.blue,
              child: Text(app.name.isEmpty ? '?' : app.name[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }
}

// =============================================================================
// LOGIN
// =============================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _reg = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true, _loading = false, _remember = true;
  String? _error;

  @override
  void dispose() {
    _reg.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    final reg = _reg.text.trim().toUpperCase();
    final result = await AuthService.login(reg, _pass.text);
    if (!mounted) return;

    if (result.success) {
      app.login(reg, result.name);
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShell()));
    } else {
      setState(() {
        _loading = false;
        _error = result.message;
      });
    }
  }

  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: C.mute, fontSize: 14),
        prefixIcon: Icon(icon, color: C.mute, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: C.card,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: C.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: C.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: C.blue)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: C.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: C.red)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
              center: const Alignment(0, -1.1),
              radius: 1.2,
              colors: [C.blue.withValues(alpha: 0.18), C.bg]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                                color: C.blue,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                      color: C.blue.withValues(alpha: 0.4),
                                      blurRadius: 30)
                                ]),
                            child: const Icon(Icons.auto_awesome_rounded,
                                color: Colors.black, size: 32),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Campus Pulse',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 6),
                        const Text('SRM Student Portal · sign in to continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: C.sub, fontSize: 13.5)),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _reg,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          decoration: _dec('Demo Email', Icons.email_outlined),
                          validator: (v) => (v == null || v.trim().length < 5)
                              ? 'Enter your registration number'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _pass,
                          obscureText: _obscure,
                          onFieldSubmitted: (_) => _submit(),
                          decoration:
                              _dec('Password', Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: C.mute,
                                        size: 20),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  )),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Enter your password'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          SizedBox(
                            height: 32,
                            width: 32,
                            child: Checkbox(
                                value: _remember,
                                activeColor: C.blue,
                                checkColor: Colors.black,
                                onChanged: (v) =>
                                    setState(() => _remember = v ?? false)),
                          ),
                          const SizedBox(width: 6),
                          const Text('Remember me',
                              style: TextStyle(color: C.sub, fontSize: 13)),
                          const Spacer(),
                          TextButton(
                              onPressed: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Contact your department office to reset your password.'),
                                      behavior: SnackBarBehavior.floating)),
                              child: const Text('Forgot password?',
                                  style: TextStyle(fontSize: 13))),
                        ]),
                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(top: 6, bottom: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: C.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              const Icon(Icons.error_outline,
                                  color: C.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(_error!,
                                      style: const TextStyle(
                                          color: C.red, fontSize: 13))),
                            ]),
                          ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(
                                backgroundColor: C.blue,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14))),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.4, color: Colors.black))
                                : const Text('Sign in',
                                    style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SHELL (sidebar on wide screens, bottom nav on phones)
// =============================================================================
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Overview'),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Timetable'),
    (Icons.groups_outlined, Icons.groups_rounded, 'Campus life'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'My profile'),
  ];

  @override
  void initState() {
    super.initState();
    // Fire exam reminder popups right after the home screen appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showExamReminders(context);
    });
  }

  void go(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    final pages = [
      OverviewPage(wide: wide, onNav: go),
      TimetablePage(wide: wide),
      CampusPage(wide: wide),
      ProfilePage(wide: wide),
    ];
    final body = pages[index];

    if (wide) {
      return Scaffold(
        body: Row(children: [
          _Sidebar(index: index, onTap: go),
          const VerticalDivider(width: 1, color: C.border),
          Expanded(child: body),
        ]),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: go,
        destinations: [
          for (final it in _items)
            NavigationDestination(
                icon: Icon(it.$1),
                selectedIcon: Icon(it.$2, color: C.blue),
                label: it.$3),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _Sidebar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final next = Clock.nextClass;
    return Container(
      width: 300,
      color: C.side,
      padding: const EdgeInsets.all(22),
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: C.blue, borderRadius: BorderRadius.circular(14)),
              child:
                  const Icon(Icons.auto_awesome_rounded, color: Colors.black),
            ),
            const SizedBox(width: 12),
            const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Campus Pulse',
                      style:
                          TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  Text('SRM Student Portal',
                      style: TextStyle(color: C.sub, fontSize: 12)),
                ]),
          ]),
          const SizedBox(height: 32),
          for (var i = 0; i < _HomeShellState._items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTap(i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                      color: index == i ? C.card2 : Colors.transparent,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(
                        index == i
                            ? _HomeShellState._items[i].$2
                            : _HomeShellState._items[i].$1,
                        size: 21,
                        color: index == i ? C.text : C.sub),
                    const SizedBox(width: 12),
                    Text(_HomeShellState._items[i].$3,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                index == i ? FontWeight.w700 : FontWeight.w500,
                            color: index == i ? C.text : C.sub)),
                  ]),
                ),
              ),
            ),
          const Spacer(),
          Panel(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  Clock.dayOrder == null
                      ? 'NO DAY ORDER'
                      : 'DAY ORDER ${Clock.dayOrder}',
                  style: const TextStyle(
                      color: C.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4)),
              const SizedBox(height: 6),
              Text(
                  '${Clock.weekday}, ${Clock.now.day} ${_months[Clock.now.month - 1]}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                  '${Clock.today.length} classes${next != null ? ' · Next at ${hm(next.start)} ${next.start < 720 ? 'AM' : 'PM'}' : ''}',
                  style: const TextStyle(color: C.sub, fontSize: 12.5)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// =============================================================================
// OVERVIEW
// =============================================================================
class OverviewPage extends StatelessWidget {
  final bool wide;
  final ValueChanged<int> onNav;
  const OverviewPage({super.key, required this.wide, required this.onNav});

  @override
  Widget build(BuildContext context) {
    final upcoming = Mock.exams.where((e) => e.daysLeft >= 0).toList()
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    final shown = upcoming.take(2).toList();

    return PageFrame(wide: wide, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('YOUR PULSE',
                style: TextStyle(
                    color: C.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6)),
            const SizedBox(height: 6),
            Text('Focus on what\'s next.',
                style: TextStyle(
                    fontSize: wide ? 36 : 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8)),
          ]),
        ),
        AnimatedBuilder(
          animation: app,
          builder: (context, _) => OutlinedButton.icon(
            onPressed: () {
              app.setAlerts(!app.alertsEnabled);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(app.alertsEnabled
                      ? 'Exam reminders on — you\'ll get a popup 3 days before each exam.'
                      : 'Exam reminders turned off.'),
                  behavior: SnackBarBehavior.floating));
            },
            icon: Icon(
                app.alertsEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                size: 18),
            label: Text(app.alertsEnabled ? 'Alerts on' : 'Enable alerts'),
            style: OutlinedButton.styleFrom(
                foregroundColor: app.alertsEnabled ? C.green : C.text,
                side: const BorderSide(color: C.border),
                padding: EdgeInsets.symmetric(
                    horizontal: wide ? 20 : 12, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ]),
      const SizedBox(height: 22),
      if (shown.isNotEmpty)
        twoCol(
          wide,
          ExamCard(exam: shown[0]),
          shown.length > 1 ? ExamCard(exam: shown[1]) : const SizedBox.shrink(),
        ),
      const SizedBox(height: 32),
      const SectionTitle('Attendance health', trailing: 'Semester overview'),
      const AttendanceSection(),
      const SizedBox(height: 32),
      SectionTitle('Today\'s timetable',
          trailing: '${Clock.today.length} classes'),
      TodayTimetable(onViewAll: () => onNav(1)),
      const SizedBox(height: 32),
      twoCol(
        wide,
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle('Campus life', trailing: 'Today'),
          CampusLifeCard(),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle('Latest notices',
              trailing:
                  '${Mock.notices.where((n) => n.important).length} unread'),
          NoticeListCard(notices: Mock.notices.take(2).toList()),
        ]),
      ),
    ]);
  }
}

// ---- Exam card ---------------------------------------------------------------
class ExamCard extends StatefulWidget {
  final Exam exam;
  const ExamCard({super.key, required this.exam});
  @override
  State<ExamCard> createState() => _ExamCardState();
}

class _ExamCardState extends State<ExamCard> {
  late bool open = widget.exam.urgent;

  @override
  Widget build(BuildContext context) {
    final e = widget.exam;
    final color = e.urgent ? C.red : C.blue;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 18, 18, 8),
          decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: C.border)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(
                    e.urgent ? 'URGENT · EXAM APPROACHING' : 'UPCOMING EXAM',
                    style: TextStyle(
                        color: color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4)),
              ),
              Pill(e.countdown, color),
            ]),
            const SizedBox(height: 12),
            Text(e.name,
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${e.code} · ${e.dateLabel}',
                style: const TextStyle(color: C.sub, fontSize: 13)),
            const SizedBox(height: 14),
            Wrap(spacing: 18, runSpacing: 6, children: [
              _Meta(Icons.schedule_rounded, e.slot),
              _Meta(Icons.location_on_outlined, e.hall),
            ]),
            const SizedBox(height: 14),
            const Divider(height: 1, color: C.border),
            InkWell(
              onTap: () => setState(() => open = !open),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Expanded(
                      child: Text(
                          open
                              ? 'Syllabus included'
                              : 'View syllabus & details',
                          style:
                              const TextStyle(color: C.sub, fontSize: 13.5))),
                  Icon(
                      open
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: C.sub),
                ]),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState:
                  open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              secondChild: const SizedBox(width: double.infinity),
              firstChild: Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: C.card2, borderRadius: BorderRadius.circular(12)),
                  child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(
                            text: 'Syllabus: ',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(
                            text: e.units.join(', '),
                            style: const TextStyle(color: C.sub)),
                      ]),
                      style: const TextStyle(fontSize: 13.5, height: 1.4)),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: () => showExamSheet(context, e),
                      child: const Text('Full details & hall ticket')),
                ),
              ]),
            ),
          ]),
        ),
        Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: color)),
      ]),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta(this.icon, this.text);
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: C.sub),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13)),
      ]);
}

// ---- Attendance --------------------------------------------------------------
class RingPainter extends CustomPainter {
  final double value; // 0..1
  final Color color;
  RingPainter(this.value, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final rect = const Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = C.border;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, arc);
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.value != value || old.color != color;
}

class AttendanceSection extends StatelessWidget {
  const AttendanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final pct = Mock.overall;
    final safe = pct >= 75;
    final color = safe ? C.green : C.red;
    final a = Mock.attended, t = Mock.total;
    final canMiss = ((a * 4) ~/ 3) - t;
    final needAttend = 3 * t - 4 * a;
    final best = Mock.best, worst = Mock.worst;

    final main = Panel(
      padding: const EdgeInsets.all(22),
      child: LayoutBuilder(builder: (context, c) {
        final ring = SizedBox(
          width: 130,
          height: 130,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (pct / 100).clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CustomPaint(
              painter: RingPainter(v, color),
              child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${pct.round()}%',
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w800)),
                const Text('OVERALL',
                    style: TextStyle(
                        color: C.sub, fontSize: 10.5, letterSpacing: 0.6)),
              ])),
            ),
          ),
        );
        final info =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Pill(safe ? 'Safe' : 'At risk', color,
              icon: safe
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded),
          const SizedBox(height: 10),
          Text(safe ? 'You\'re above the line' : 'You\'re below the line',
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              safe
                  ? (canMiss > 0
                      ? 'You can safely miss $canMiss class${canMiss == 1 ? '' : 'es'} and stay above 75%.'
                      : 'Right on the edge — don\'t miss the next class.')
                  : 'Attend the next $needAttend classes in a row to get back to 75%.',
              style: const TextStyle(color: C.sub, fontSize: 14, height: 1.35)),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => showBunkCalculator(context),
            style: OutlinedButton.styleFrom(
                foregroundColor: C.text,
                side: const BorderSide(color: C.border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Open bunk calculator'),
              SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 18),
            ]),
          ),
        ]);
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          ring,
          const SizedBox(width: 22),
          Expanded(child: info),
        ]);
      }),
    );

    Widget stat(String label, String value, String sub, {Color? vc}) => Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: C.sub, fontSize: 13)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: vc ?? C.text)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(color: C.sub, fontSize: 12.5)),
          ]),
        );

    final stats = Panel(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Row(children: [
          Expanded(child: stat('Attended', '$a', 'of $t classes')),
          Container(width: 1, height: 100, color: C.border),
          Expanded(child: stat('This week', '8/9', 'classes attended')),
        ]),
        const Divider(height: 1, color: C.border),
        Row(children: [
          Expanded(
              child:
                  stat('Best', '${best.pct.round()}%', best.name, vc: C.green)),
          Container(width: 1, height: 100, color: C.border),
          Expanded(
              child: stat('Needs care', '${worst.pct.round()}%', worst.name,
                  vc: worst.safe ? C.amber : C.red)),
        ]),
      ]),
    );

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 760;
      return twoCol(wide, main, stats, flexA: 3, flexB: 2);
    });
  }
}

// ---- Bunk calculator ---------------------------------------------------------
Future<void> showBunkCalculator(BuildContext context, {int initial = 0}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _Sheet(child: BunkCalculator(initial: initial)),
  );
}

class BunkCalculator extends StatefulWidget {
  final int initial;
  const BunkCalculator({super.key, this.initial = 0});
  @override
  State<BunkCalculator> createState() => _BunkCalculatorState();
}

class _BunkCalculatorState extends State<BunkCalculator> {
  late int sel = widget.initial;
  double missed = 0;

  @override
  Widget build(BuildContext context) {
    final s = Mock.subjects[sel];
    final futureTotal = s.total + s.remaining;
    final projected = (s.attended + s.remaining - missed) / futureTotal * 100;
    final ok = projected >= 75;
    final budget = (s.attended + s.remaining - 0.75 * futureTotal)
        .floor()
        .clamp(0, s.remaining)
        .toInt();
    final color = ok ? C.green : C.red;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Bunk calculator',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text('See what skipping classes does to your attendance.',
          style: TextStyle(color: C.sub, fontSize: 13)),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < Mock.subjects.length; i++)
          ChoiceChip(
            label: Text(Mock.subjects[i].name,
                style: const TextStyle(fontSize: 12.5)),
            selected: sel == i,
            selectedColor: C.blue.withValues(alpha: 0.2),
            backgroundColor: C.card,
            side: BorderSide(color: sel == i ? C.blue : C.border),
            onSelected: (_) => setState(() {
              sel = i;
              missed = 0;
            }),
          ),
      ]),
      const SizedBox(height: 18),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              'Now: ${s.attended}/${s.total} (${s.pct.toStringAsFixed(1)}%) · ${s.remaining} classes left',
              style: const TextStyle(color: C.sub, fontSize: 12.5)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
                'If I miss ${missed.round()} class${missed.round() == 1 ? '' : 'es'}…',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Pill('${projected.toStringAsFixed(1)}%', color),
          ]),
          Slider(
            value: missed,
            min: 0,
            max: s.remaining.toDouble(),
            divisions: s.remaining,
            activeColor: color,
            label: '${missed.round()}',
            onChanged: (v) => setState(() => missed = v),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Panel(
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: C.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.shield_outlined, color: C.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
                budget == 0
                    ? 'No safe misses left in this subject. Attend everything!'
                    : 'Safe budget: you can miss up to $budget more class${budget == 1 ? '' : 'es'} and finish the semester at 75%+.',
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.35)),
          ),
        ]),
      ),
    ]);
  }
}

// ---- Timetable ---------------------------------------------------------------
class TodayTimetable extends StatelessWidget {
  final VoidCallback onViewAll;
  const TodayTimetable({super.key, required this.onViewAll});
  @override
  Widget build(BuildContext context) => ClassList(
      classes: Clock.today,
      showStatus: true,
      emptyText: 'No classes today — enjoy the break!');
}

class ClassList extends StatelessWidget {
  final List<ClassSlot> classes;
  final bool showStatus;
  final String emptyText;
  const ClassList(
      {super.key,
      required this.classes,
      required this.showStatus,
      this.emptyText = 'No classes'});

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return Panel(
          child: Center(
              child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(emptyText, style: const TextStyle(color: C.sub)),
      )));
    }
    final m = Clock.now.hour * 60 + Clock.now.minute;
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (var i = 0; i < classes.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: C.border),
          _ClassRow(
              c: classes[i],
              state: !showStatus
                  ? 3
                  : (m >= classes[i].end
                      ? 0
                      : (m >= classes[i].start ? 1 : 2))),
        ],
      ]),
    );
  }
}

// state: 0 completed, 1 active, 2 upcoming, 3 none
class _ClassRow extends StatelessWidget {
  final ClassSlot c;
  final int state;
  const _ClassRow({required this.c, required this.state});
  @override
  Widget build(BuildContext context) {
    final dim = state == 0;
    final dot = dim ? C.mute : (state == 1 ? C.green : c.color);
    final label = ['Completed', 'Active', 'Upcoming', ''][state];
    final pc = [C.mute, C.green, C.blue, C.blue][state];
    return Opacity(
      opacity: dim ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 58,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hm(c.start),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(hm(c.end),
                  style: const TextStyle(color: C.mute, fontSize: 12)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 10),
            child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          ),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name,
                  style: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${c.code} · ${c.room}',
                  style: const TextStyle(color: C.sub, fontSize: 13)),
              const SizedBox(height: 2),
              Text(c.faculty,
                  style: const TextStyle(color: C.sub, fontSize: 13)),
            ]),
          ),
          if (state != 3) Pill(label, pc),
        ]),
      ),
    );
  }
}

class TimetablePage extends StatefulWidget {
  final bool wide;
  const TimetablePage({super.key, required this.wide});
  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  late int selected = Clock.dayOrder ?? 1;

  @override
  Widget build(BuildContext context) {
    final today = Clock.dayOrder;
    return PageFrame(wide: widget.wide, children: [
      const Text('Timetable',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      const Text('Pick a day order to see its classes.',
          style: TextStyle(color: C.sub)),
      const SizedBox(height: 18),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (var d = 1; d <= 5; d++)
          ChoiceChip(
            label: Text('Day order $d${d == today ? ' · Today' : ''}'),
            selected: selected == d,
            selectedColor: C.blue.withValues(alpha: 0.2),
            backgroundColor: C.card,
            side: BorderSide(color: selected == d ? C.blue : C.border),
            onSelected: (_) => setState(() => selected = d),
          ),
      ]),
      const SizedBox(height: 20),
      ClassList(
          classes: Mock.timetable[selected] ?? [],
          showStatus: selected == today),
    ]);
  }
}

// ---- Campus life & notices ---------------------------------------------------
class CampusLifeCard extends StatelessWidget {
  const CampusLifeCard({super.key});
  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, Color c, String title, String sub, String time) =>
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: c, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(color: C.sub, fontSize: 12.5)),
                ])),
            Text(time, style: const TextStyle(color: C.sub, fontSize: 12)),
          ]),
        );
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(children: [
        row(Icons.restaurant_rounded, C.amber, 'Lunch at Main Mess',
            'Veg biryani · Raita · Gulab jamun', '12:00–2:30'),
        const Divider(height: 1, color: C.border),
        row(Icons.groups_outlined, C.blue, 'Robotics Club meetup',
            'Mini Hall 2 · Open to all', '5:30 PM'),
      ]),
    );
  }
}

class NoticeListCard extends StatelessWidget {
  final List<Notice> notices;
  const NoticeListCard({super.key, required this.notices});
  @override
  Widget build(BuildContext context) => Panel(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (var i = 0; i < notices.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: C.border),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                constraints: const BoxConstraints(maxWidth: 640),
                builder: (_) => _Sheet(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Pill(notices[i].category, notices[i].color,
                            icon: notices[i].icon),
                        const SizedBox(height: 12),
                        Text(notices[i].title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${notices[i].ago} ago',
                            style: const TextStyle(color: C.mute)),
                        const SizedBox(height: 14),
                        Text(notices[i].body,
                            style: const TextStyle(
                                color: C.sub, fontSize: 14.5, height: 1.5)),
                      ]),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: notices[i].color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(notices[i].icon,
                        color: notices[i].color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(notices[i].title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14.5)),
                        const SizedBox(height: 2),
                        Text(notices[i].body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(color: C.sub, fontSize: 12.5)),
                      ])),
                  const SizedBox(width: 8),
                  Text(notices[i].ago,
                      style: const TextStyle(color: C.sub, fontSize: 12)),
                ]),
              ),
            ),
          ],
        ]),
      );
}

class CampusPage extends StatefulWidget {
  final bool wide;
  const CampusPage({super.key, required this.wide});
  @override
  State<CampusPage> createState() => _CampusPageState();
}

class _CampusPageState extends State<CampusPage> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final cats = [
      'All',
      ...{for (final n in Mock.notices) n.category}
    ];
    final list = Mock.notices
        .where((n) => filter == 'All' || n.category == filter)
        .toList();
    return PageFrame(wide: widget.wide, children: [
      const Text('Campus life',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 18),
      const SectionTitle('Today on campus'),
      const CampusLifeCard(),
      const SizedBox(height: 28),
      const SectionTitle('Mess menu'),
      Panel(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (final r in const [
            ('Breakfast', 'Idli · Sambar · Coconut chutney'),
            ('Lunch', 'Veg biryani · Raita · Gulab jamun'),
            ('Snacks', 'Samosa · Tea / Coffee'),
            ('Dinner', 'Chapati · Paneer curry · Rice'),
          ]) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                SizedBox(
                    width: 90,
                    child: Text(r.$1,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: C.blue))),
                Expanded(
                    child: Text(r.$2, style: const TextStyle(color: C.sub))),
              ]),
            ),
            if (r.$1 != 'Dinner') const Divider(height: 1, color: C.border),
          ],
        ]),
      ),
      const SizedBox(height: 28),
      const SectionTitle('Notices'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final c in cats)
          ChoiceChip(
            label: Text(c),
            selected: filter == c,
            selectedColor: C.blue.withValues(alpha: 0.2),
            backgroundColor: C.card,
            side: BorderSide(color: filter == c ? C.blue : C.border),
            onSelected: (_) => setState(() => filter = c),
          ),
      ]),
      const SizedBox(height: 14),
      NoticeListCard(notices: list),
    ]);
  }
}

// ---- Profile -----------------------------------------------------------------
class ProfilePage extends StatelessWidget {
  final bool wide;
  const ProfilePage({super.key, required this.wide});

  @override
  Widget build(BuildContext context) {
    return PageFrame(wide: wide, children: [
      const Text('My profile',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      const SizedBox(height: 18),
      AnimatedBuilder(
        animation: app,
        builder: (context, _) => Column(children: [
          Panel(
            child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: C.blue,
                child: Text(app.name.isEmpty ? '?' : app.name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(app.name,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(app.regNo,
                        style: const TextStyle(color: C.sub, fontSize: 13)),
                    const SizedBox(height: 8),
                    const Pill('Synced', C.green,
                        icon: Icons.check_circle_rounded),
                  ])),
            ]),
          ),
          const SizedBox(height: 20),
          Panel(
            padding: EdgeInsets.zero,
            child: Column(children: [
              SwitchListTile(
                value: app.alertsEnabled,
                onChanged: app.setAlerts,
                activeThumbColor: C.blue,
                secondary: const Icon(Icons.alarm_rounded, color: C.blue),
                title: const Text('Exam reminders',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                subtitle: const Text(
                    'Popup alert when an exam is 3 days or less away',
                    style: TextStyle(color: C.sub, fontSize: 12.5)),
              ),
              const Divider(height: 1, color: C.border),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined,
                    color: C.blue),
                title: const Text('Show exam reminders now',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                trailing:
                    const Icon(Icons.chevron_right_rounded, color: C.mute),
                onTap: () => showExamReminders(context, force: true),
              ),
              const Divider(height: 1, color: C.border),
              ListTile(
                leading: const Icon(Icons.calculate_outlined, color: C.blue),
                title: const Text('Bunk calculator',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                trailing:
                    const Icon(Icons.chevron_right_rounded, color: C.mute),
                onTap: () => showBunkCalculator(context),
              ),
              const Divider(height: 1, color: C.border),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: C.red),
                title: const Text('Log out',
                    style: TextStyle(
                        color: C.red,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5)),
                onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}
