import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'db.dart';
import 'cosmos_ui.dart';
import 'notify.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Notify.init();
  runApp(const CosmosApp());
}

class CosmosApp extends StatelessWidget {
  const CosmosApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cosmos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        fontFamily: 'SF Pro Text',
        colorScheme: const ColorScheme.dark(
            primary: kAccent2, secondary: kAccent1, surface: kBg),
      ),
      home: const Gate(),
    );
  }
}

/// Decides between sign-in and the app based on whether a profile exists.
class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  String? _name;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DB.profileName().then((n) => setState(() {
          _name = n;
          _loading = false;
        }));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _name == null
        ? SignIn(onSignedIn: (n) => setState(() => _name = n))
        : Home(name: _name!, onSignOut: () => setState(() => _name = null));
  }
}

// ---------------------------------------------------------------- Sign in
class SignIn extends StatefulWidget {
  final ValueChanged<String> onSignedIn;
  const SignIn({super.key, required this.onSignedIn});
  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  late final AnimationController _a =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat(reverse: true);

  Future<void> _enter() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    await DB.setProfile(name);
    widget.onSignedIn(name);
  }

  @override
  void dispose() {
    _a.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GalaxyBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(
                animation: _a,
                builder: (_, child) => Transform.translate(
                    offset: Offset(0, -10 + 20 * _a.value), child: child),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: kAccentGrad,
                    boxShadow: [
                      BoxShadow(
                          color: kAccent2.withOpacity(0.6), blurRadius: 40)
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 46),
                ),
              ),
              const SizedBox(height: 28),
              const GradientText('Cosmos',
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Your universe of focus, tasks & gratitude',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 40),
              Glass(
                child: TextField(
                  controller: _ctrl,
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _enter(),
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'What should we call you?',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GlowButton(
                  label: 'Enter the Cosmos',
                  icon: Icons.rocket_launch,
                  onTap: _enter),
            ]),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Home shell
class Home extends StatefulWidget {
  final String name;
  final VoidCallback onSignOut;
  const Home({super.key, required this.name, required this.onSignOut});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _tab = 0;
  // Bumping this key forces the Today dashboard to re-query when revisited.
  int _refresh = 0;

  void _bump() => setState(() => _refresh++);

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayScreen(
          key: ValueKey(_refresh),
          name: widget.name,
          onSignOut: widget.onSignOut,
          onRefresh: _bump,
          goto: (i) => setState(() => _tab = i)),
      TasksScreen(onChanged: _bump),
      FocusScreen(onChanged: _bump),
      GratitudeScreen(onChanged: _bump),
    ];
    return Scaffold(
      extendBody: true,
      body: GalaxyBackground(
        child: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: pages[_tab],
          ),
        ),
      ),
      bottomNavigationBar: _NavBar(
          index: _tab,
          onTap: (i) {
            if (i == 0) _bump();
            setState(() => _tab = i);
          }),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _NavBar({required this.index, required this.onTap});

  static const _items = [
    (Icons.dashboard_rounded, 'Today'),
    (Icons.check_circle_rounded, 'Tasks'),
    (Icons.timer_rounded, 'Focus'),
    (Icons.favorite_rounded, 'Gratitude'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: Glass(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final sel = i == index;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(
                    horizontal: sel ? 16 : 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: sel ? kAccentGrad : null,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(children: [
                  Icon(_items[i].$1,
                      color: sel ? Colors.white : Colors.white54, size: 24),
                  if (sel) ...[
                    const SizedBox(width: 6),
                    Text(_items[i].$2,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ]),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Today
class TodayScreen extends StatelessWidget {
  final String name;
  final VoidCallback onSignOut;
  final VoidCallback onRefresh;
  final ValueChanged<int> goto;
  const TodayScreen(
      {super.key,
      required this.name,
      required this.onSignOut,
      required this.onRefresh,
      required this.goto});

  Future<void> _backup(BuildContext context) async {
    final path = await DB.exportJson();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF161033),
        content: Text('Backed up to $path')));
  }

  Future<void> _restore(BuildContext context) async {
    final ok = await DB.importJson();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF161033),
        content: Text(ok ? 'Restored from backup ✦' : 'No backup found yet')));
    if (ok) onRefresh();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        DB.taskCounts(),
        DB.focusToday(),
        DB.gratitudeTodayCount(),
        DB.streak()
      ]),
      builder: (context, snap) {
        final tasks = (snap.data?[0] as (int, int)?) ?? (0, 0);
        final focus = (snap.data?[1] as (int, int)?) ?? (0, 0);
        final grat = (snap.data?[2] as int?) ?? 0;
        final streak = (snap.data?[3] as int?) ?? 0;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_greeting,
                      style:
                          TextStyle(color: Colors.white.withOpacity(0.6))),
                  GradientText(name,
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.w800)),
                ]),
                IconButton(
                  onPressed: () async {
                    await DB.signOut();
                    onSignOut();
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _StreakBanner(days: streak),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: _StatTile(
                      label: 'Tasks done',
                      value: '${tasks.$1}/${tasks.$2}',
                      icon: Icons.check_circle_rounded,
                      onTap: () => goto(1))),
              const SizedBox(width: 14),
              Expanded(
                  child: _StatTile(
                      label: 'Focus today',
                      value: '${focus.$2}m',
                      icon: Icons.timer_rounded,
                      onTap: () => goto(2))),
            ]),
            const SizedBox(height: 14),
            _StatTile(
                label: 'Gratitude logged today',
                value: '$grat ${grat == 1 ? "thing" : "things"}',
                icon: Icons.favorite_rounded,
                wide: true,
                onTap: () => goto(3)),
            const SizedBox(height: 24),
            Glass(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✦ Cosmic nudge',
                      style: TextStyle(
                          color: kAccent1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  Text(
                    focus.$1 == 0
                        ? 'Start one 25-minute focus session. Small steps, big orbits.'
                        : 'You\'ve completed ${focus.$1} session${focus.$1 == 1 ? "" : "s"} today. Keep the momentum.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: _SyncButton(
                    icon: Icons.cloud_upload_rounded,
                    label: 'Back up',
                    onTap: () => _backup(context)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SyncButton(
                    icon: Icons.cloud_download_rounded,
                    label: 'Restore',
                    onTap: () => _restore(context)),
              ),
            ]),
          ],
        );
      },
    );
  }
}

class _StreakBanner extends StatelessWidget {
  final int days;
  const _StreakBanner({required this.days});
  @override
  Widget build(BuildContext context) {
    return Glass(
      child: Row(children: [
        const Text('🔥', style: TextStyle(fontSize: 30)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$days day${days == 1 ? "" : "s"}',
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          Text(days == 0 ? 'Start your streak today' : 'Current streak',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 12)),
        ]),
      ]),
    );
  }
}

class _SyncButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SyncButton(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Glass(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: kAccent1, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool wide;
  final VoidCallback onTap;
  const _StatTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.onTap,
      this.wide = false});
  @override
  Widget build(BuildContext context) {
    return Glass(
      onTap: onTap,
      child: Row(
        mainAxisAlignment:
            wide ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 12)),
          ]),
          if (wide) const Spacer(),
          Icon(icon, color: kAccent2, size: 30),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Tasks
class TasksScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const TasksScreen({super.key, required this.onChanged});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, Object?>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await DB.tasks();
    setState(() => _tasks = t);
    widget.onChanged();
  }

  static const _prioColors = [Color(0xFF6BE675), kAccent1, kAccent3];
  static const _prioLabels = ['Low', 'Medium', 'High'];

  Future<void> _addSheet() async {
    final ctrl = TextEditingController();
    int prio = 1;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 8),
          child: Glass(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('New task',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                    hintText: 'What needs doing?',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white12),
              ),
              const SizedBox(height: 16),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final sel = prio == i;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ChoiceChip(
                        label: Text(_prioLabels[i]),
                        selected: sel,
                        onSelected: (_) => setSheet(() => prio = i),
                        selectedColor: _prioColors[i].withOpacity(0.3),
                        side: BorderSide(color: _prioColors[i]),
                      ),
                    );
                  })),
              const SizedBox(height: 18),
              GlowButton(
                  label: 'Add',
                  icon: Icons.add,
                  onTap: () async {
                    if (ctrl.text.trim().isEmpty) return;
                    await DB.addTask(ctrl.text.trim(), prio);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  }),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      _tasks.isEmpty
          ? const _Empty(
              icon: Icons.task_alt_rounded,
              text: 'No tasks yet.\nTap + to launch your first one.')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: _tasks.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(4, 8, 0, 16),
                    child: GradientText('Tasks',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w800)),
                  );
                }
                final t = _tasks[i - 1];
                final done = t['done'] == 1;
                final prio = t['priority'] as int;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: ValueKey(t['id']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                          color: kAccent3.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(22)),
                      child: const Icon(Icons.delete_rounded,
                          color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await DB.deleteTask(t['id'] as int);
                      _load();
                    },
                    child: Glass(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      onTap: () async {
                        await DB.toggleTask(t['id'] as int, !done);
                        _load();
                      },
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: done ? kAccentGrad : null,
                            border: done
                                ? null
                                : Border.all(
                                    color: _prioColors[prio], width: 2),
                          ),
                          child: done
                              ? const Icon(Icons.check,
                                  size: 18, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: TextStyle(
                              fontSize: 16,
                              color: done ? Colors.white38 : Colors.white,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: Colors.white38,
                            ),
                            child: Text(t['title'] as String),
                          ),
                        ),
                        if (!done)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _prioColors[prio]),
                          ),
                      ]),
                    ),
                  ),
                );
              },
            ),
      Positioned(
        right: 20,
        bottom: 110,
        child: FloatingActionButton(
          onPressed: _addSheet,
          backgroundColor: kAccent2,
          child: const Icon(Icons.add, size: 30),
        ),
      ),
    ]);
  }
}

// ---------------------------------------------------------------- Focus
class FocusScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const FocusScreen({super.key, required this.onChanged});
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with SingleTickerProviderStateMixin {
  static const _presets = [25, 15, 5];
  int _minutes = 25;
  int _remaining = 25 * 60;
  Timer? _timer;
  bool _running = false;
  (int, int) _today = (0, 0);

  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    DB.focusToday().then((v) => setState(() => _today = v));
  }

  void _setPreset(int m) {
    _timer?.cancel();
    Notify.cancelFocus();
    setState(() {
      _minutes = m;
      _remaining = m * 60;
      _running = false;
    });
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      Notify.cancelFocus();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    Notify.scheduleFocusEnd(Duration(seconds: _remaining), _minutes);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _complete();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _complete() async {
    _timer?.cancel();
    await DB.logSession(_minutes);
    final t = await DB.focusToday();
    if (!mounted) return;
    setState(() {
      _running = false;
      _remaining = _minutes * 60;
      _today = t;
    });
    widget.onChanged();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161033),
        title: const GradientText('Session complete ✦',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        content: Text('You focused for $_minutes minutes. Logged to your orbit.',
            style: TextStyle(color: Colors.white.withOpacity(0.8))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nice'))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  String get _fmt {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - _remaining / (_minutes * 60);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: GradientText('Focus',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 20),
        Center(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => SizedBox(
              width: 280,
              height: 280,
              child: CustomPaint(
                painter: _RingPainter(
                    progress, _running ? 0.3 + 0.7 * _pulse.value : 0.4),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_fmt,
                          style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w200,
                              letterSpacing: 2)),
                      Text(_running ? 'in focus…' : 'ready',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _presets.map((m) {
              final sel = m == _minutes;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => _setPreset(m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: sel ? kAccentGrad : null,
                      color: sel ? null : Colors.white10,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text('${m}m',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : Colors.white60)),
                  ),
                ),
              );
            }).toList()),
        const SizedBox(height: 28),
        Center(
          child: GlowButton(
              label: _running ? 'Pause' : 'Start focus',
              icon: _running ? Icons.pause : Icons.play_arrow_rounded,
              onTap: _toggle),
        ),
        const SizedBox(height: 30),
        Glass(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat('${_today.$1}', 'sessions today'),
              Container(width: 1, height: 36, color: Colors.white12),
              _MiniStat('${_today.$2}', 'minutes focused'),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  const _MiniStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
        GradientText(value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
      ]);
}

class _RingPainter extends CustomPainter {
  final double progress, glow;
  _RingPainter(this.progress, this.glow);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 18;
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..color = Colors.white10);
    final rect = Rect.fromCircle(center: c, radius: r);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
              colors: [kAccent1, kAccent2, kAccent3, kAccent1])
          .createShader(rect)
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, 6 * glow);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(_) => true;
}

// ---------------------------------------------------------------- Gratitude
class GratitudeScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const GratitudeScreen({super.key, required this.onChanged});
  @override
  State<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<GratitudeScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, Object?>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final g = await DB.gratitude();
    setState(() => _items = g);
    widget.onChanged();
  }

  Future<void> _add() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    await DB.addGratitude(t);
    _ctrl.clear();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: GradientText('Gratitude',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 6),
        Glass(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('What are you grateful for today?',
                style: TextStyle(color: Colors.white.withOpacity(0.8))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (_) => _add(),
                  decoration: const InputDecoration(
                      hintText: 'A good thing…',
                      border: InputBorder.none),
                ),
              ),
              IconButton.filled(
                onPressed: _add,
                style: IconButton.styleFrom(backgroundColor: kAccent2),
                icon: const Icon(Icons.add),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        _Heatmap(key: ValueKey(_items.length)),
        const SizedBox(height: 20),
        if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: _Empty(
                icon: Icons.favorite_border_rounded,
                text: 'Your gratitude orbit is empty.\nAdd the first good thing.'),
          ),
        ..._items.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: ValueKey(g['id']),
                direction: DismissDirection.endToStart,
                onDismissed: (_) async {
                  await DB.deleteGratitude(g['id'] as int);
                  _load();
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                      color: kAccent3.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(22)),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                child: Glass(
                  child: Row(children: [
                    const Text('✦', style: TextStyle(color: kAccent1, fontSize: 18)),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Text(g['text'] as String,
                            style: const TextStyle(fontSize: 16))),
                    Text(g['day'] as String,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11)),
                  ]),
                ),
              ),
            )),
      ],
    );
  }
}

/// GitHub-style heatmap of gratitude entries over the last 17 weeks.
class _Heatmap extends StatelessWidget {
  const _Heatmap({super.key});
  static const _weeks = 17;
  static const _cells = _weeks * 7;

  Color _shade(int count) {
    if (count <= 0) return Colors.white.withOpacity(0.06);
    if (count == 1) return kAccent2.withOpacity(0.45);
    if (count == 2) return kAccent2.withOpacity(0.75);
    return kAccent1;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    String fmt(DateTime t) => t.toIso8601String().substring(0, 10);
    return FutureBuilder<Map<String, int>>(
      future: DB.gratitudeHeatmap(),
      builder: (context, snap) {
        final counts = snap.data ?? const {};
        return Glass(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Last 17 weeks',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, c) {
              const gap = 4.0;
              final cell = (c.maxWidth - gap * (_weeks - 1)) / _weeks;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(_weeks, (col) {
                  return Padding(
                    padding: EdgeInsets.only(right: col == _weeks - 1 ? 0 : gap),
                    child: Column(
                      children: List.generate(7, (row) {
                        final i = col * 7 + row;
                        final day =
                            today.subtract(Duration(days: _cells - 1 - i));
                        final count = counts[fmt(day)] ?? 0;
                        return Container(
                          width: cell,
                          height: cell,
                          margin: const EdgeInsets.only(bottom: gap),
                          decoration: BoxDecoration(
                              color: _shade(count),
                              borderRadius: BorderRadius.circular(3)),
                        );
                      }),
                    ),
                  );
                }),
              );
            }),
          ]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- shared
class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), height: 1.5)),
          ],
        ),
      );
}
