import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

/// Секретная мини-игра «Лис в бегах»: лиса убегает от охотника к своей норе.
/// Открывается пятью нажатиями на надпись «fox browser» на стартовой странице.

enum _Kind { stone, bush, log, stump, trap }

class _Level {
  const _Level(
    this.name,
    this.speed,
    this.goal,
    this.minGap,
    this.maxGap,
    this.kinds,
    this.skyTop,
    this.skyBottom,
    this.trees, {
    this.doubles = false,
  });

  final String name;
  final double speed; // единиц в секунду
  final double goal; // длина уровня
  final double minGap, maxGap; // интервал между препятствиями, сек
  final List<_Kind> kinds;
  final Color skyTop, skyBottom, trees;
  final bool doubles; // двойные препятствия
}

const _levels = [
  _Level('Опушка', 240, 3000, 1.35, 2.3, [_Kind.stone, _Kind.bush],
      Color(0xFFFBF6EF), Color(0xFFF3EADF), Color(0xFFB7B08F)),
  _Level('Берёзовая роща', 265, 3800, 1.25, 2.1, [_Kind.stone, _Kind.bush, _Kind.log],
      Color(0xFFF7F0E7), Color(0xFFEDE2D3), Color(0xFFC9C3A5)),
  _Level('Овраг', 290, 4600, 1.15, 1.95, [_Kind.stone, _Kind.log, _Kind.stump],
      Color(0xFFF3EADF), Color(0xFFE3D4C1), Color(0xFFA9A27F)),
  _Level('Старый бурелом', 315, 5400, 1.05, 1.8, [_Kind.log, _Kind.stump, _Kind.bush, _Kind.trap],
      Color(0xFFEDE2D3), Color(0xFFDCCBB4), Color(0xFF9C9673)),
  _Level('Болото', 340, 6200, 1.0, 1.7, [_Kind.stone, _Kind.trap, _Kind.bush, _Kind.stump],
      Color(0xFFE4E0CC), Color(0xFFD3CDB2), Color(0xFF8E8B68),
      doubles: true),
  _Level('Тёмный ельник', 365, 7000, 0.95, 1.6, [_Kind.stump, _Kind.log, _Kind.trap, _Kind.stone],
      Color(0xFFCFC2AC), Color(0xFFB9A88F), Color(0xFF6F6A50),
      doubles: true),
  _Level('Путь к норе', 390, 8000, 0.9, 1.5, _Kind.values,
      Color(0xFFF2D7B8), Color(0xFFE8C4A0), Color(0xFF8C7A5B),
      doubles: true),
];

const _vh = 400.0; // виртуальная высота мира
const _groundY = 330.0;
const _gravity = 1800.0;
const _jumpSpeed = 620.0;
const _maxGap = 170.0;
const _caughtGap = 45.0;

class _Obstacle {
  _Obstacle(this.kind, this.x)
      : w = switch (kind) {
          _Kind.stone => 34.0,
          _Kind.bush => 46.0,
          _Kind.log => 70.0,
          _Kind.stump => 34.0,
          _Kind.trap => 52.0,
        },
        h = switch (kind) {
          _Kind.stone => 26.0,
          _Kind.bush => 34.0,
          _Kind.log => 28.0,
          _Kind.stump => 52.0,
          _Kind.trap => 16.0,
        };

  final _Kind kind;
  double x;
  final double w, h;
  bool hit = false;
}

class _Berry {
  _Berry(this.x, this.height);
  double x;
  final double height;
  bool taken = false;
}

enum _Phase { menu, ready, running, caught, levelDone, victory }

class _World {
  double vw = 800;
  double foxH = 0, vy = 0;
  double distance = 0, gap = _maxGap, time = 0, scroll = 0;
  double nextSpawn = 1.2, nextBerry = 4, invuln = 0;
  final obstacles = <_Obstacle>[];
  final berries = <_Berry>[];

  double get foxX => vw * 0.38;
  bool get onGround => foxH <= 0;

  void reset() {
    foxH = 0;
    vy = 0;
    distance = 0;
    gap = _maxGap;
    time = 0;
    scroll = 0;
    nextSpawn = 1.2;
    nextBerry = 4;
    invuln = 0;
    obstacles.clear();
    berries.clear();
  }
}

class FoxRunGame extends StatefulWidget {
  const FoxRunGame({super.key});

  @override
  State<FoxRunGame> createState() => _FoxRunGameState();
}

class _FoxRunGameState extends State<FoxRunGame> with SingleTickerProviderStateMixin {
  static const _prefsKey = 'fox_game_unlocked';

  final _world = _World();
  final _frame = ValueNotifier<int>(0);
  final _rng = Random();
  final _focus = FocusNode();
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  _Phase _phase = _Phase.menu;
  int _level = 0;
  int _unlocked = 1;

  _Level get cfg => _levels[_level];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _ticker = createTicker(_tick);
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _unlocked = min(7, max(1, p.getInt(_prefsKey) ?? 1)));
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    _focus.dispose();
    SystemChrome.setPreferredOrientations([]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startLevel(int index) {
    setState(() {
      _level = index;
      _world.reset();
      _phase = _Phase.ready;
    });
    _frame.value++;
  }

  void _run() {
    setState(() => _phase = _Phase.running);
    _last = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void _stop(_Phase phase) {
    _ticker.stop();
    setState(() => _phase = phase);
  }

  Future<void> _unlock(int count) async {
    if (count <= _unlocked) return;
    _unlocked = count;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_prefsKey, count);
  }

  void _onTap() {
    switch (_phase) {
      case _Phase.ready:
        _run();
        _jump();
      case _Phase.running:
        _jump();
      default:
        break;
    }
  }

  void _jump() {
    if (_world.onGround) {
      _world.vy = _jumpSpeed;
      _world.foxH = 0.01;
    }
  }

  double _rand(double a, double b) => a + _rng.nextDouble() * (b - a);

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.016
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _last = elapsed;
    final w = _world;
    final speed = cfg.speed;
    final move = speed * dt;

    w.time += dt;
    w.scroll += move;
    w.distance += move;

    // Прыжок и гравитация.
    if (!w.onGround || w.vy > 0) {
      w.foxH += w.vy * dt;
      w.vy -= _gravity * dt;
      if (w.foxH <= 0) {
        w.foxH = 0;
        w.vy = 0;
      }
    }

    // Препятствия.
    final nearEnd = w.distance > cfg.goal - w.vw * 0.7;
    w.nextSpawn -= dt;
    if (w.nextSpawn <= 0 && !nearEnd) {
      final kind = cfg.kinds[_rng.nextInt(cfg.kinds.length)];
      w.obstacles.add(_Obstacle(kind, w.vw + 40));
      if (cfg.doubles && _rng.nextDouble() < 0.3) {
        w.obstacles.add(_Obstacle(_Kind.stone, w.vw + 40 + 74));
      }
      w.nextSpawn = _rand(cfg.minGap, cfg.maxGap);
    }
    for (final o in w.obstacles) {
      o.x -= move;
    }
    w.obstacles.removeWhere((o) => o.x + o.w < -60);

    // Ягоды — отбрасывают охотника назад.
    w.nextBerry -= dt;
    if (w.nextBerry <= 0 && !nearEnd) {
      w.berries.add(_Berry(w.vw + 40, _rand(70, 120)));
      w.nextBerry = _rand(4, 7);
    }
    for (final b in w.berries) {
      b.x -= move;
    }
    w.berries.removeWhere((b) => b.x < -40 || b.taken);

    // Столкновения.
    final fox = Rect.fromLTRB(w.foxX - 20, _groundY - w.foxH - 28, w.foxX + 22, _groundY - w.foxH);
    w.invuln = max(0.0, w.invuln - dt);
    for (final o in w.obstacles) {
      if (o.hit) continue;
      final r = Rect.fromLTWH(o.x + 4, _groundY - o.h + 4, o.w - 8, o.h - 4);
      if (w.invuln <= 0 && fox.overlaps(r)) {
        o.hit = true;
        w.invuln = 1.0;
        w.gap -= 50 + 4 * _level;
        HapticFeedback.mediumImpact();
      }
    }
    for (final b in w.berries) {
      final r = Rect.fromCircle(center: Offset(b.x, _groundY - b.height), radius: 14);
      if (fox.overlaps(r)) {
        b.taken = true;
        w.gap = min(_maxGap, w.gap + 40);
        HapticFeedback.selectionClick();
      }
    }
    w.gap = min(_maxGap, w.gap + 10 * dt);

    if (w.gap < _caughtGap) {
      HapticFeedback.heavyImpact();
      _stop(_Phase.caught);
    } else if (w.distance >= cfg.goal) {
      if (_level == _levels.length - 1) {
        _unlock(7);
        _stop(_Phase.victory);
      } else {
        _unlock(_level + 2);
        _stop(_Phase.levelDone);
      }
    }
    _frame.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildTheme(foxLightScheme()),
      child: Scaffold(
        backgroundColor: FoxPalette.sand,
        body: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.space ||
                    event.logicalKey == LogicalKeyboardKey.arrowUp)) {
              _onTap();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: LayoutBuilder(
            builder: (context, box) {
              final scale = box.maxHeight / _vh;
              _world.vw = box.maxWidth / scale;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _onTap(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _GamePainter(
                        world: _world,
                        level: cfg,
                        scale: scale,
                        repaint: _frame,
                      ),
                    ),
                    if (_phase != _Phase.menu) _hud(),
                    _overlay(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _hud() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CircleIcon(icon: Icons.close_rounded, onTap: () => Navigator.of(context).maybePop()),
            const SizedBox(width: 12),
            _Pill(text: 'Уровень ${_level + 1}/7 · ${cfg.name}'),
            const SizedBox(width: 16),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: _frame,
                builder: (context, _, __) => _ProgressTrack(
                  progress: (_world.distance / cfg.goal).clamp(0.0, 1.0).toDouble(),
                  danger: 1 - ((_world.gap - _caughtGap) / (_maxGap - _caughtGap)).clamp(0.0, 1.0).toDouble(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlay() {
    switch (_phase) {
      case _Phase.menu:
        return _Card(
          title: 'Лис в бегах',
          subtitle: 'Секретная игра Fox Browser.\nПомоги лисе убежать от охотника и добраться до норы!',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < _levels.length; i++)
                    _LevelBubble(
                      number: i + 1,
                      locked: i + 1 > _unlocked,
                      onTap: () => _startLevel(i),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Касание или пробел — прыжок · ягоды отгоняют охотника',
                style: TextStyle(color: FoxPalette.bark, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Вернуться в браузер'),
              ),
            ],
          ),
        );
      case _Phase.ready:
        return IgnorePointer(
          child: _Card(
            title: '${_level + 1}. ${cfg.name}',
            subtitle: 'До норы ${(cfg.goal / 10).round()} м.\nНажми, чтобы бежать!',
          ),
        );
      case _Phase.running:
        return const SizedBox.shrink();
      case _Phase.caught:
        return _Card(
          title: 'Охотник догнал!',
          subtitle: 'Лиса пробежала ${(_world.distance / 10).round()} из ${(cfg.goal / 10).round()} м.',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Ещё раз'),
                onPressed: () => _startLevel(_level),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => setState(() => _phase = _Phase.menu),
                child: const Text('Уровни'),
              ),
            ],
          ),
        );
      case _Phase.levelDone:
        return _Card(
          title: 'Ушла от погони!',
          subtitle: 'Уровень ${_level + 1} пройден. Впереди: «${_levels[_level + 1].name}».',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Дальше'),
                onPressed: () => _startLevel(_level + 1),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => setState(() => _phase = _Phase.menu),
                child: const Text('Уровни'),
              ),
            ],
          ),
        );
      case _Phase.victory:
        return _Card(
          title: 'Лиса дома!',
          subtitle: 'Все 7 уровней пройдены — охотник остался ни с чем.\nТы настоящий лисий друг.',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('В браузер'),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => setState(() => _phase = _Phase.menu),
                child: const Text('Уровни'),
              ),
            ],
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Интерфейс игры
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.subtitle, this.child});

  final String title;
  final String subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: FoxPalette.cream.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: FoxPalette.dune),
          boxShadow: const [BoxShadow(color: Color(0x223B2F25), blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: FoxPalette.espresso),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: FoxPalette.bark, height: 1.35),
              ),
              if (child != null) ...[const SizedBox(height: 16), child!],
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBubble extends StatelessWidget {
  const _LevelBubble({required this.number, required this.locked, required this.onTap});

  final int number;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: locked ? FoxPalette.linen : FoxPalette.tiles[(number - 1) % FoxPalette.tiles.length],
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: locked ? null : onTap,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: locked
                ? const Icon(Icons.lock_rounded, size: 18, color: FoxPalette.caramel)
                : Text(
                    '$number',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: FoxPalette.espresso),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FoxPalette.cream.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(dimension: 40, child: Icon(icon, size: 20, color: FoxPalette.espresso)),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FoxPalette.cream.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, color: FoxPalette.espresso),
      ),
    );
  }
}

/// Дорожка прогресса: лиса движется к норе, полоска снизу показывает близость охотника.
class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.progress, required this.danger});

  final double progress;
  final double danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: FoxPalette.cream.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth - 24;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: 0,
                right: 18,
                top: 14,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(color: FoxPalette.dune, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Positioned(
                left: 0,
                width: max(0.0, w * progress),
                top: 14,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(color: FoxPalette.latte, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Positioned(
                left: 0,
                width: max(0.0, (box.maxWidth - 18) * danger),
                bottom: 5,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Color.lerp(const Color(0xFFB7B08F), const Color(0xFFB0473A), danger),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Positioned(right: 0, top: 6, child: Icon(Icons.home_rounded, size: 18, color: FoxPalette.bark)),
              Positioned(
                left: w * progress - 6,
                top: 4,
                child: const SizedBox(width: 24, height: 20, child: CustomPaint(painter: _MiniFoxPainter())),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniFoxPainter extends CustomPainter {
  const _MiniFoxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 60);
    _drawFox(canvas, const Offset(30, 34), 0, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Рисование мира
// ---------------------------------------------------------------------------

class _GamePainter extends CustomPainter {
  _GamePainter({
    required this.world,
    required this.level,
    required this.scale,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final _World world;
  final _Level level;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final w = world;
    canvas.save();
    canvas.scale(scale);
    final vw = size.width / scale;

    // Небо.
    final sky = Rect.fromLTWH(0, 0, vw, _vh);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [level.skyTop, level.skyBottom],
        ).createShader(sky),
    );
    // Солнце.
    canvas.drawCircle(Offset(vw * 0.78, 90), 38, Paint()..color = FoxPalette.caramel.withValues(alpha: 0.35));
    canvas.drawCircle(Offset(vw * 0.78, 90), 26, Paint()..color = FoxPalette.cream.withValues(alpha: 0.8));

    // Дальние холмы.
    _hills(canvas, vw, w.scroll * 0.15, 250, 40, FoxPalette.dune.withValues(alpha: 0.9), 260);
    _hills(canvas, vw, w.scroll * 0.3, 285, 28, Color.lerp(FoxPalette.dune, level.trees, 0.35)!, 180);

    // Деревья.
    _trees(canvas, vw, w.scroll * 0.55, level.trees);

    // Земля.
    canvas.drawRect(Rect.fromLTWH(0, _groundY, vw, _vh - _groundY), Paint()..color = const Color(0xFFD8C4A6));
    canvas.drawRect(Rect.fromLTWH(0, _groundY, vw, 5), Paint()..color = const Color(0xFFB89B7A));
    final tuft = Paint()
      ..color = const Color(0xFFA9A27F)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const step = 46.0;
    final off = w.scroll % step;
    for (var x = -off; x < vw + step; x += step) {
      canvas.drawLine(Offset(x, _groundY + 18), Offset(x + 4, _groundY + 10), tuft);
      canvas.drawLine(Offset(x + 6, _groundY + 18), Offset(x + 7, _groundY + 9), tuft);
      canvas.drawCircle(Offset(x + 24, _groundY + 40), 2.5, Paint()..color = const Color(0xFFC9B394));
    }

    // Нора в конце уровня.
    final burrowX = w.foxX + (level.goal - w.distance) + 40;
    if (burrowX < vw + 120) {
      final mound = Path()
        ..moveTo(burrowX - 70, _groundY)
        ..quadraticBezierTo(burrowX, _groundY - 90, burrowX + 70, _groundY)
        ..close();
      canvas.drawPath(mound, Paint()..color = const Color(0xFFB89B7A));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(burrowX, _groundY - 18), width: 52, height: 40),
        Paint()..color = FoxPalette.espresso,
      );
    }

    // Ягоды.
    for (final b in w.berries) {
      final c = Offset(b.x, _groundY - b.height);
      canvas.drawCircle(c + const Offset(-6, 3), 7, Paint()..color = const Color(0xFFB0473A));
      canvas.drawCircle(c + const Offset(6, 3), 7, Paint()..color = const Color(0xFFC0574A));
      canvas.drawCircle(c + const Offset(0, -6), 7, Paint()..color = const Color(0xFFA33E33));
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - 12)
          ..lineTo(c.dx + 12, c.dy - 20)
          ..lineTo(c.dx + 6, c.dy - 10)
          ..close(),
        Paint()..color = const Color(0xFF8E8B68),
      );
    }

    // Препятствия.
    for (final o in w.obstacles) {
      _obstacle(canvas, o);
    }

    // Охотник.
    final hunterX = w.foxX - w.gap;
    _drawHunter(canvas, Offset(hunterX, _groundY), w.time);

    // Лиса (мигает после столкновения).
    final blink = w.invuln > 0 && (w.invuln * 10).floor().isEven;
    if (!blink) {
      _drawFox(canvas, Offset(w.foxX, _groundY - w.foxH), w.time, !w.onGround);
    }
    canvas.restore();
  }

  void _hills(Canvas canvas, double vw, double offset, double baseY, double amp, Color color, double period) {
    final path = Path()..moveTo(0, _groundY);
    for (double x = 0; x <= vw + 10; x += 10) {
      final y = baseY - amp * (0.5 + 0.5 * sin((x + offset) / period * 2 * pi));
      path.lineTo(x, y);
    }
    path
      ..lineTo(vw, _groundY)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _trees(Canvas canvas, double vw, double offset, Color color) {
    const spacing = 120.0;
    final first = (offset / spacing).floor();
    for (var i = first - 1; i < first + vw / spacing + 2; i++) {
      final seed = (i * 7919) % 97;
      final x = i * spacing - offset + seed % 40;
      final h = 70.0 + seed % 50;
      final trunk = Paint()..color = const Color(0xFF8C7A5B);
      canvas.drawRect(Rect.fromLTWH(x - 3, _groundY - 18, 6, 18), trunk);
      final crown = Paint()..color = color.withValues(alpha: 0.85);
      for (var k = 0; k < 3; k++) {
        final top = _groundY - 14 - h + k * h * 0.28;
        final half = 18.0 + k * 7;
        canvas.drawPath(
          Path()
            ..moveTo(x, top)
            ..lineTo(x + half, top + h * 0.42)
            ..lineTo(x - half, top + h * 0.42)
            ..close(),
          crown,
        );
      }
    }
  }

  void _obstacle(Canvas canvas, _Obstacle o) {
    final r = Rect.fromLTWH(o.x, _groundY - o.h, o.w, o.h);
    switch (o.kind) {
      case _Kind.stone:
        canvas.drawOval(r.inflate(2).translate(0, 4), Paint()..color = const Color(0xFF9E8F7D));
        canvas.drawOval(Rect.fromLTWH(r.left + 6, r.top + 4, r.width * 0.4, r.height * 0.3),
            Paint()..color = const Color(0xFFCFC2B2));
      case _Kind.bush:
        final p = Paint()..color = const Color(0xFF8E8B68);
        canvas.drawCircle(Offset(r.left + 12, r.bottom - 12), 13, p);
        canvas.drawCircle(Offset(r.right - 12, r.bottom - 12), 13, p);
        canvas.drawCircle(Offset(r.center.dx, r.top + 14), 16, Paint()..color = const Color(0xFF9C9A74));
      case _Kind.log:
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(14)), Paint()..color = FoxPalette.latte);
        canvas.drawCircle(Offset(r.right - 12, r.center.dy), 11, Paint()..color = const Color(0xFFD6BEA0));
        canvas.drawCircle(Offset(r.right - 12, r.center.dy), 5,
            Paint()
              ..color = FoxPalette.latte
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      case _Kind.stump:
        canvas.drawRect(r, Paint()..color = FoxPalette.bark);
        canvas.drawOval(Rect.fromLTWH(r.left - 2, r.top - 6, r.width + 4, 12), Paint()..color = const Color(0xFFD6BEA0));
      case _Kind.trap:
        final base = Paint()..color = const Color(0xFF5A4F44);
        canvas.drawRect(Rect.fromLTWH(r.left, r.bottom - 5, r.width, 5), base);
        final teeth = Path()..moveTo(r.left, r.bottom - 4);
        const n = 6;
        for (var i = 0; i < n; i++) {
          final x0 = r.left + r.width * i / n;
          teeth
            ..lineTo(x0 + r.width / n / 2, r.top)
            ..lineTo(x0 + r.width / n, r.bottom - 4);
        }
        teeth.close();
        canvas.drawPath(teeth, Paint()..color = const Color(0xFF7D7366));
    }
  }

  @override
  bool shouldRepaint(covariant _GamePainter old) => old.level != level || old.scale != scale;
}

/// Лиса сбоку, смотрит вправо. [feet] — точка между лапами на земле.
void _drawFox(Canvas canvas, Offset feet, double t, bool inAir) {
  final body = Paint()..color = FoxPalette.latte;
  final dark = Paint()..color = FoxPalette.espresso;
  final cream = Paint()..color = FoxPalette.cream;
  final x = feet.dx, y = feet.dy;

  // Лапы.
  final legPaint = Paint()
    ..color = FoxPalette.espresso
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;
  final swing = inAir ? 0.6 : sin(t * 18);
  for (final (dx, phase) in [(-12.0, 0.0), (12.0, pi)]) {
    final s = inAir ? swing : sin(t * 18 + phase);
    canvas.drawLine(Offset(x + dx, y - 12), Offset(x + dx + s * 7, y), legPaint);
    canvas.drawLine(Offset(x + dx + 4, y - 12), Offset(x + dx + 4 - s * 7, y), legPaint);
  }

  // Хвост.
  final wag = inAir ? -4.0 : sin(t * 9) * 3;
  final tail = Path()
    ..moveTo(x - 16, y - 22)
    ..lineTo(x - 44, y - 30 + wag)
    ..lineTo(x - 36, y - 16 + wag)
    ..close();
  canvas.drawPath(tail, body);
  canvas.drawPath(
    Path()
      ..moveTo(x - 38, y - 27 + wag)
      ..lineTo(x - 44, y - 30 + wag)
      ..lineTo(x - 40, y - 21 + wag)
      ..close(),
    cream,
  );

  // Тело.
  final torso = RRect.fromRectAndRadius(Rect.fromLTWH(x - 20, y - 28, 38, 18), const Radius.circular(9));
  canvas.drawRRect(torso, body);
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x - 10, y - 16, 24, 6), const Radius.circular(3)),
    cream,
  );

  // Голова.
  final head = Path()
    ..moveTo(x + 10, y - 36)
    ..lineTo(x + 34, y - 24)
    ..lineTo(x + 12, y - 16)
    ..close();
  canvas.drawPath(head, body);
  canvas.drawPath(
    Path()
      ..moveTo(x + 14, y - 22)
      ..lineTo(x + 34, y - 24)
      ..lineTo(x + 14, y - 16)
      ..close(),
    cream,
  );
  // Ухо.
  canvas.drawPath(
    Path()
      ..moveTo(x + 11, y - 34)
      ..lineTo(x + 14, y - 46)
      ..lineTo(x + 20, y - 32)
      ..close(),
    body,
  );
  canvas.drawPath(
    Path()
      ..moveTo(x + 13, y - 35)
      ..lineTo(x + 14.5, y - 42)
      ..lineTo(x + 18, y - 33.5)
      ..close(),
    dark,
  );
  canvas.drawCircle(Offset(x + 21, y - 28), 2.2, dark);
  canvas.drawCircle(Offset(x + 34, y - 24), 2.2, dark);
}

/// Охотник: шляпа, куртка цвета хаки, ружьё. [feet] — точка на земле.
void _drawHunter(Canvas canvas, Offset feet, double t) {
  final x = feet.dx, y = feet.dy;
  final legPaint = Paint()
    ..color = const Color(0xFF5A4F44)
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round;
  final s = sin(t * 12);
  canvas.drawLine(Offset(x - 4, y - 38), Offset(x - 4 + s * 12, y - 2), legPaint);
  canvas.drawLine(Offset(x + 4, y - 38), Offset(x + 4 - s * 12, y - 2), legPaint);
  // Сапоги.
  final boot = Paint()..color = FoxPalette.espresso;
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x - 9 + s * 12, y - 6, 14, 6), const Radius.circular(3)),
    boot,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x - 1 - s * 12, y - 6, 14, 6), const Radius.circular(3)),
    boot,
  );
  // Куртка.
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x - 13, y - 78, 26, 44), const Radius.circular(8)),
    Paint()..color = const Color(0xFF6B7350),
  );
  canvas.drawRect(Rect.fromLTWH(x - 13, y - 50, 26, 5), Paint()..color = const Color(0xFF5A4632));
  // Ружьё.
  canvas.drawLine(
    Offset(x - 6, y - 52),
    Offset(x + 36, y - 66),
    Paint()
      ..color = const Color(0xFF3B2F25)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawLine(
    Offset(x - 8, y - 50),
    Offset(x + 6, y - 56),
    Paint()
      ..color = const Color(0xFF8B6B4A)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round,
  );
  // Рука.
  canvas.drawLine(
    Offset(x, y - 70),
    Offset(x + 14, y - 60),
    Paint()
      ..color = const Color(0xFF5E6645)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round,
  );
  // Голова.
  canvas.drawCircle(Offset(x + 2, y - 88), 11, Paint()..color = const Color(0xFFE0C3A0));
  canvas.drawCircle(Offset(x + 7, y - 89), 1.8, Paint()..color = FoxPalette.espresso);
  // Шляпа.
  final hat = Paint()..color = const Color(0xFF5A4632);
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x - 14, y - 98, 32, 5), const Radius.circular(2)),
    hat,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(x - 8, y - 110, 20, 14), const Radius.circular(4)),
    hat,
  );
  canvas.drawRect(Rect.fromLTWH(x - 8, y - 100, 20, 3), Paint()..color = const Color(0xFFB0473A));
}
