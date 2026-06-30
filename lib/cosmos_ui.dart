import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

// Shared palette / building blocks for the whole app.
const kBg = Color(0xFF06060F);
const kAccent1 = Color(0xFF38E1FF); // cyan
const kAccent2 = Color(0xFF9B5CFF); // purple
const kAccent3 = Color(0xFFFF5CA8); // pink
const kAccentGrad = LinearGradient(colors: [kAccent1, kAccent2, kAccent3]);

/// A slowly drifting starfield + nebula glow, painted behind everything.
class GalaxyBackground extends StatefulWidget {
  final Widget child;
  const GalaxyBackground({super.key, required this.child});
  @override
  State<GalaxyBackground> createState() => _GalaxyBackgroundState();
}

class _GalaxyBackgroundState extends State<GalaxyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))
        ..repeat();
  final _rng = math.Random(42);
  late final List<List<double>> _stars = List.generate(140, (_) => [
        _rng.nextDouble(), // x 0..1
        _rng.nextDouble(), // y 0..1
        0.4 + _rng.nextDouble() * 1.8, // size
        _rng.nextDouble(), // twinkle phase
      ]);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.7),
          radius: 1.4,
          colors: [Color(0xFF161033), kBg],
        ),
      ),
      child: Stack(children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) =>
                CustomPaint(painter: _StarPainter(_c.value, _stars)),
          ),
        ),
        widget.child,
      ]),
    );
  }
}

class _StarPainter extends CustomPainter {
  final double t;
  final List<List<double>> stars;
  _StarPainter(this.t, this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    // two soft nebula blooms
    void bloom(Offset c, double r, Color col) => canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [col, Colors.transparent])
              .createShader(Rect.fromCircle(center: c, radius: r)));
    bloom(Offset(size.width * 0.2, size.height * 0.18), 220,
        kAccent2.withOpacity(0.18));
    bloom(Offset(size.width * 0.85, size.height * 0.6), 260,
        kAccent1.withOpacity(0.10));

    for (final s in stars) {
      final drift = (s[0] + t) % 1.0;
      final p = Offset(drift * size.width, s[1] * size.height);
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin((t + s[3]) * math.pi * 2 * 3));
      canvas.drawCircle(
          p, s[2], Paint()..color = Colors.white.withOpacity(0.7 * tw));
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

/// Frosted-glass card — the core surface of the UI.
class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const Glass(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(18),
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withOpacity(0.06),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border:
                    Border.all(color: Colors.white.withOpacity(0.10), width: 1),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Text painted with the accent gradient.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const GradientText(this.text, {super.key, required this.style});
  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (b) => kAccentGrad.createShader(b),
        child: Text(text, style: style.copyWith(color: Colors.white)),
      );
}

/// Gradient pill button with a soft glow.
class GlowButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const GlowButton(
      {super.key, required this.label, this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
        decoration: BoxDecoration(
          gradient: kAccentGrad,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
                color: kAccent2.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
          ],
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.3)),
        ]),
      ),
    );
  }
}
