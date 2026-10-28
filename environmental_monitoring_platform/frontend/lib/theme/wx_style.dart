import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:environmental_monitoring_platform/models/chart_point.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:environmental_monitoring_platform/providers/environment_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design tokens — lavender Material-You look from the Google Weather redesign
// ─────────────────────────────────────────────────────────────────────────────


enum WxAccentTheme {
  purple(
    label: 'Purple',
    darkAccent: Color(0xFFD0A8FF),
    lightAccent: Color(0xFF8A1FD6),
    darkHero: [Color(0xFF2A2066), Color(0xFF45307F), Color(0xFF7C4B86)],
    lightHero: [Color(0xFF5B43CC), Color(0xFF7F52C8), Color(0xFFB56DA8)],
    previewColor: Color(0xFF8A1FD6),
  ),
  ocean(
    label: 'Ocean',
    darkAccent: Color(0xFF70B6FF),
    lightAccent: Color(0xFF0284C7),
    darkHero: [Color(0xFF0F2B5C), Color(0xFF13427E), Color(0xFF1B62B3)],
    lightHero: [Color(0xFF0284C7), Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    previewColor: Color(0xFF0284C7),
  ),
  emerald(
    label: 'Emerald',
    darkAccent: Color(0xFF6EE7B7),
    lightAccent: Color(0xFF059669),
    darkHero: [Color(0xFF0D3B2E), Color(0xFF135742), Color(0xFF1B7F5E)],
    lightHero: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
    previewColor: Color(0xFF10B981),
  ),
  sunset(
    label: 'Sunset',
    darkAccent: Color(0xFFFF9E7A),
    lightAccent: Color(0xFFE65100),
    darkHero: [Color(0xFF5C2014), Color(0xFF852D1C), Color(0xFFBD4527)],
    lightHero: [Color(0xFFE65100), Color(0xFFF97316), Color(0xFFFB923C)],
    previewColor: Color(0xFFF97316),
  ),
  rose(
    label: 'Rose',
    darkAccent: Color(0xFFFF75B5),
    lightAccent: Color(0xFFD81B60),
    darkHero: [Color(0xFF54103B), Color(0xFF781B57), Color(0xFFAB2B7D)],
    lightHero: [Color(0xFFD81B60), Color(0xFFEC4899), Color(0xFFF472B6)],
    previewColor: Color(0xFFEC4899),
  ),
  cyan(
    label: 'Cyan',
    darkAccent: Color(0xFF5EEAD4),
    lightAccent: Color(0xFF0D9488),
    darkHero: [Color(0xFF093333), Color(0xFF0F4D4D), Color(0xFF186E6E)],
    lightHero: [Color(0xFF0D9488), Color(0xFF14B8A6), Color(0xFF2DD4BF)],
    previewColor: Color(0xFF14B8A6),
  );

  const WxAccentTheme({
    required this.label,
    required this.darkAccent,
    required this.lightAccent,
    required this.darkHero,
    required this.lightHero,
    required this.previewColor,
  });

  final String label;
  final Color darkAccent;
  final Color lightAccent;
  final List<Color> darkHero;
  final List<Color> lightHero;
  final Color previewColor;

  Color get color => previewColor;
}

class Wx {
  const Wx._(this.isDark, [this.accentTheme = WxAccentTheme.purple]);
  final bool isDark;
  final WxAccentTheme accentTheme;

  factory Wx.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    WxAccentTheme theme = WxAccentTheme.purple;
    try {
      final env = Provider.of<EnvironmentProvider>(context, listen: false);
      theme = env.accentTheme;
    } catch (_) {}
    return Wx._(isDark, theme);
  }

  // Surfaces (Frosted Glassmorphism)
  Color get bg => isDark ? const Color(0xFF0E0B16) : const Color(0xFFF3EDFC);
  Color get card => isDark
      ? const Color(0xFF1E172B).withValues(alpha: 0.60)
      : Colors.white.withValues(alpha: 0.72);
  Color get cardBorder => isDark
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.white.withValues(alpha: 0.75);
  Color get sheetBg => isDark
      ? const Color(0xFF191224).withValues(alpha: 0.92)
      : Colors.white.withValues(alpha: 0.94);
  Color get chipOn => isDark ? accent.withValues(alpha: 0.35) : accent.withValues(alpha: 0.22);
  Color get chipOff => isDark
      ? Colors.white.withValues(alpha: 0.07)
      : Colors.white.withValues(alpha: 0.65);
  Color get iconBg => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.white.withValues(alpha: 0.65);

  // Ink
  Color get text => isDark ? const Color(0xFFEFE8F7) : const Color(0xFF1C1822);
  Color get textDim => isDark ? const Color(0xFFA79BB8) : const Color(0xFF6A6178);

  // Accents
  Color get accent => isDark ? accentTheme.darkAccent : accentTheme.lightAccent;
  Color get accentTrack => isDark ? const Color(0xFF3A2D49) : const Color(0xFFF7EFFF);
  Color get onAccent => isDark ? const Color(0xFF1C1822) : Colors.white;
  Color get outdoorLine => isDark ? const Color(0xFFFFC72C) : const Color(0xFFE59A00);
  Color get good => isDark ? const Color(0xFF5FD3A0) : const Color(0xFF1E8E63);
  Color get bad => isDark ? const Color(0xFFFF8A94) : const Color(0xFFD93A4A);
  Color get warn => isDark ? const Color(0xFFFFC857) : const Color(0xFFB36B00);
  Color get warnBg => isDark ? const Color(0xFF3F2E10) : const Color(0xFFFFE9B8);

  List<Color> get heroColors => isDark ? accentTheme.darkHero : accentTheme.lightHero;

  TextStyle t(double size,
          {FontWeight w = FontWeight.w400, Color? c, double? h, double? ls}) =>
      TextStyle(
          fontSize: size,
          fontWeight: w,
          color: c ?? text,
          height: h,
          letterSpacing: ls);

  InputDecoration field(String label, {IconData? icon, String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        filled: true,
        fillColor: iconBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      );

  ButtonStyle get filledButton => FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: onAccent,
        minimumSize: const Size.fromHeight(50),
        shape: const StadiumBorder(),
      );

  ButtonStyle outlineButton(Color color) => OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        minimumSize: const Size.fromHeight(50),
        shape: const StadiumBorder(),
      );

  /// Apparent temperature (Steadman, no wind) from °C and relative humidity.
  static double feelsLike(double tC, double rh) {
    final e = rh / 100 * 6.105 * math.exp(17.27 * tC / (237.7 + tC));
    return tC + 0.33 * e - 4.0;
  }
}

/// Drop-in ThemeData so the nav bar, sheets and pickers match the screens.
///   theme: WxTheme.build(Brightness.light),
///   darkTheme: WxTheme.build(Brightness.dark),
class WxTheme {
  static ThemeData build(Brightness brightness, [WxAccentTheme accent = WxAccentTheme.purple]) {
    final wx = Wx._(brightness == Brightness.dark, accent);
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B4FD8),
      brightness: brightness,
    ).copyWith(primary: wx.accent, surface: wx.bg);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: wx.bg,
      cardColor: wx.card,
      appBarTheme: AppBarTheme(
        backgroundColor: wx.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: wx.text,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: wx.bg,
        indicatorColor: wx.chipOn,
        elevation: 0,
        labelTextStyle:
            WidgetStatePropertyAll(wx.t(12, w: FontWeight.w500)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Building blocks
// ─────────────────────────────────────────────────────────────────────────────

class WxCard extends StatelessWidget {
  const WxCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final wx = Wx.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: wx.card,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: wx.cardBorder, width: 1.0),
          ),
          child: child,
        ),
      ),
    );
  }
}

class WxIconDot extends StatelessWidget {
  const WxIconDot({super.key, required this.icon, this.size = 32, this.color});
  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final wx = Wx.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: wx.iconBg, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.52, color: color ?? wx.text),
    );
  }
}

class WxCardTitle extends StatelessWidget {
  const WxCardTitle({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final wx = Wx.of(context);
    return Row(
      children: [
        WxIconDot(icon: icon),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: wx.t(14, w: FontWeight.w500))),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class WxChipButton extends StatelessWidget {
  const WxChipButton({
    super.key,
    required this.child,
    this.selected = false,
    this.onTap,
    this.height = 44,
  });
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final wx = Wx.of(context);
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: selected ? wx.chipOn : wx.chipOff,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(height: height, child: Center(child: child)),
        ),
      ),
    );
  }
}

/// Equal-width pill tabs (Today / Tomorrow / 10 days in the reference).
class WxChips extends StatelessWidget {
  const WxChips({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final wx = Wx.of(context);
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: WxChipButton(
              selected: i == index,
              onTap: () => onChanged(i),
              child: Text(
                labels[i],
                style: wx.t(14,
                    w: FontWeight.w500, c: i == index ? wx.accent : wx.text),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Small inline two-way switch (e.g. "30 min" / "Full day").
class WxSegment extends StatelessWidget {
  const WxSegment({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final wx = Wx.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: wx.iconBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: i == index ? wx.chipOn : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  labels[i],
                  style: wx.t(12,
                      w: FontWeight.w500,
                      c: i == index ? wx.accent : wx.textDim),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact metric tile: icon, label, value and an optional trend arrow.
class WxTile extends StatelessWidget {
  const WxTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.delta,
    this.deltaUnit = '',
  });
  final IconData icon;
  final String label;
  final String value;
  final double? delta;
  final String deltaUnit;

  @override
  Widget build(BuildContext context) {
    final wx = Wx.of(context);
    return WxCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          WxIconDot(icon: icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: wx.t(12, c: wx.textDim)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(value,
                              style: wx.t(18, w: FontWeight.w500)),
                        ),
                      ),
                    ),
                    if (delta != null) ...[
                      Icon(
                        delta! >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        size: 16,
                        color: delta! >= 0 ? wx.accent : wx.bad,
                      ),
                      Text('${delta!.abs().toStringAsFixed(1)}$deltaUnit',
                          style: wx.t(10, c: wx.textDim)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wide tile with an optional small caption (Sunrise / Sunset in the reference).
class WxInfoTile extends StatelessWidget {
  const WxInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final wx = Wx.of(context);
    return WxCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          WxIconDot(icon: icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: wx.t(12, c: wx.textDim)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: wx.t(15, w: FontWeight.w500)),
                if (caption != null)
                  Text(caption!, style: wx.t(10, c: wx.textDim)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Label · pill bar · value (the "Chance of rain" rows in the reference).
class WxBarRow extends StatelessWidget {
  const WxBarRow({
    super.key,
    required this.label,
    required this.fraction,
    required this.valueText,
    this.color,
  });
  final String label;
  final double? fraction;
  final String valueText;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final wx = Wx.of(context);
    return Row(
      children: [
        SizedBox(width: 56, child: Text(label, style: wx.t(13))),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: wx.accentTrack,
              borderRadius: BorderRadius.circular(7),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (fraction ?? 0).clamp(0.0, 1.0).toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  color: color ?? wx.accent,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(valueText,
              textAlign: TextAlign.right, style: wx.t(13, c: wx.textDim)),
        ),
      ],
    );
  }
}

class WxLegendDot extends StatelessWidget {
  const WxLegendDot({super.key, required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final wx = Wx.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: wx.t(12, c: wx.textDim)),
      ],
    );
  }
}

Future<T?> showWxSheet<T>(BuildContext context,
    {required WidgetBuilder builder}) {
  final wx = Wx.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: wx.sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: wx.cardBorder, width: 1.0),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: wx.textDim.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SingleChildScrollView(child: builder(ctx)),
            ],
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Illustrations
// ─────────────────────────────────────────────────────────────────────────────

/// Sun / moon / cloud / rain glyph keyed by Open-Meteo (WMO) weather code and day/night.
class WeatherGlyph extends StatelessWidget {
  const WeatherGlyph({
    super.key,
    required this.code,
    this.isDay = true,
    this.size = 96,
  });
  final int code;
  final bool isDay;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _GlyphPainter(code, isDay)),
      );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.code, this.isDay);
  final int code;
  final bool isDay;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final clear = code <= 1;
    final partly = code == 2;
    final rainy = (code >= 51 && code <= 67) ||
        (code >= 80 && code <= 82) ||
        code >= 95;
    final snowy = (code >= 71 && code <= 77) || code == 85 || code == 86;
    final thunderstorm = code >= 95;

    // Celestial body: Sun (Day) or Crescent Moon (Night)
    if (clear || partly) {
      if (isDay) {
        // Sun
        final c = Offset(w * (clear ? 0.5 : 0.62), w * (clear ? 0.5 : 0.38));
        final r = w * (clear ? 0.30 : 0.27);
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = const RadialGradient(
              colors: [Color(0xFFFFE066), Color(0xFFFFB800)],
            ).createShader(Rect.fromCircle(center: c, radius: r)),
        );
      } else {
        // Crescent Moon
        final c = Offset(w * (clear ? 0.5 : 0.62), w * (clear ? 0.5 : 0.38));
        final r = w * (clear ? 0.32 : 0.28);
        _drawMoon(canvas, c, r);

        if (clear) {
          // Twinkling stars
          _drawStar(canvas, Offset(w * 0.22, w * 0.32), w * 0.04);
          _drawStar(canvas, Offset(w * 0.30, w * 0.68), w * 0.03);
          _drawStar(canvas, Offset(w * 0.78, w * 0.72), w * 0.035);
        }
      }
    }

    const front = Color(0xFFEDEAF3);
    const back = Color(0xFFB9B2C6);
    if (partly) {
      _cloud(canvas, w, Offset(-w * 0.02, w * 0.10), 1.0, front);
    } else if (!clear) {
      _cloud(canvas, w, Offset(w * 0.12, -w * 0.02), 0.8, back);
      _cloud(canvas, w, Offset(0, rainy || snowy ? -w * 0.04 : w * 0.12), 1.0,
          front);
    }

    if (rainy) {
      final p = Paint()
        ..color = const Color(0xFF6EA8FF)
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round;
      for (final x in [0.36, 0.52, 0.68]) {
        canvas.drawLine(Offset(w * x, w * 0.80), Offset(w * (x - 0.04), w * 0.93), p);
      }

      if (thunderstorm) {
        // Lightning bolt
        final bolt = Path()
          ..moveTo(w * 0.52, w * 0.66)
          ..lineTo(w * 0.44, w * 0.79)
          ..lineTo(w * 0.51, w * 0.79)
          ..lineTo(w * 0.46, w * 0.94)
          ..lineTo(w * 0.58, w * 0.77)
          ..lineTo(w * 0.51, w * 0.77)
          ..close();
        canvas.drawPath(
          bolt,
          Paint()
            ..color = const Color(0xFFFFD54F)
            ..style = PaintingStyle.fill,
        );
      }
    } else if (snowy) {
      final p = Paint()..color = Colors.white;
      for (final x in [0.36, 0.52, 0.68]) {
        canvas.drawCircle(Offset(w * x, w * 0.87), w * 0.03, p);
      }
    }
  }

  void _drawMoon(Canvas c, Offset center, double r) {
    final moonPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF7C2), Color(0xFFFFD84D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: r));

    final fullCircle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: r));
    final cutCircle = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(center.dx + r * 0.42, center.dy - r * 0.28),
        radius: r * 0.88,
      ));

    final crescent = Path.combine(PathOperation.difference, fullCircle, cutCircle);
    c.drawPath(crescent, moonPaint);
  }

  void _drawStar(Canvas c, Offset pos, double size) {
    final starPaint = Paint()..color = const Color(0xFFFFFDE7);
    final p = Path()
      ..moveTo(pos.dx, pos.dy - size)
      ..quadraticBezierTo(pos.dx, pos.dy, pos.dx + size, pos.dy)
      ..quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy + size)
      ..quadraticBezierTo(pos.dx, pos.dy, pos.dx - size, pos.dy)
      ..quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy - size);
    c.drawPath(p, starPaint);
  }

  void _cloud(Canvas c, double w, Offset o, double k, Color col) {
    final p = Paint()..color = col;
    Offset q(double x, double y) => Offset(o.dx + x * w * k, o.dy + y * w * k);
    c.drawCircle(q(.30, .62), w * k * .16, p);
    c.drawCircle(q(.50, .54), w * k * .21, p);
    c.drawCircle(q(.70, .64), w * k * .15, p);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(q(.14, .62), q(.85, .80)),
        Radius.circular(w * k * .09),
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.code != code || old.isDay != isDay;
}

/// Soft stars and warm lanterns behind the hero card text.
class WxSparkle extends StatelessWidget {
  const WxSparkle({super.key});

  @override
  Widget build(BuildContext context) =>
      const SizedBox.expand(child: CustomPaint(painter: _SparklePainter()));
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    for (var i = 0; i < 42; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.75),
        0.6 + rnd.nextDouble() * 1.8,
        Paint()..color = Colors.white.withValues(alpha: 0.12 + rnd.nextDouble() * 0.4),
      );
    }
    for (var i = 0; i < 7; i++) {
      final c = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: c,
              width: 9 + rnd.nextDouble() * 8,
              height: 12 + rnd.nextDouble() * 8),
          const Radius.circular(4),
        ),
        Paint()
          ..color = const Color(0xFFFFB36B).withValues(alpha: 0.22 + rnd.nextDouble() * 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Round gauge that fills like a glass of water (humidity tile in the Pixel reference).
class WxWaveGauge extends StatelessWidget {
  const WxWaveGauge({
    super.key,
    required this.percent,
    required this.caption,
    this.size = 96,
  });
  final double? percent;
  final String caption;
  final double size;

  @override
  Widget build(BuildContext context) {
    final wx = Wx.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _WavePainter(
              ((percent ?? 0) / 100).clamp(0.0, 1.0).toDouble(),
              wx.isDark ? const Color(0xFF7B4FB0) : const Color(0xFFC9A2F5),
              wx.iconBg,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(percent == null ? '--' : '${percent!.toStringAsFixed(0)}%',
                  style: wx.t(20, w: FontWeight.w500)),
              Text(caption, style: wx.t(11, c: wx.textDim)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.frac, this.fill, this.bg);
  final double frac;
  final Color fill;
  final Color bg;

  @override
  void paint(Canvas canvas, Size s) {
    final r = s.width / 2;
    final center = Offset(r, r);
    canvas.drawCircle(center, r, Paint()..color = bg);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    final top = s.height * (1 - frac);
    final path = Path()
      ..moveTo(0, s.height)
      ..lineTo(0, top);
    for (double x = 0; x <= s.width; x += 2) {
      path.lineTo(x, top + math.sin(x / s.width * 2 * math.pi * 1.5) * 4);
    }
    path
      ..lineTo(s.width, s.height)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.frac != frac || old.fill != fill || old.bg != bg;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Trend chart (shared by Dashboard + Charts)
// ─────────────────────────────────────────────────────────────────────────────

class WxTrendChart extends StatelessWidget {
  const WxTrendChart({
    super.key,
    required this.points,
    required this.temperature,
    this.showIndoor = true,
    this.showOutdoor = true,
    this.height = 200,
  });

  final List<ChartPoint> points;
  final bool temperature; // false = humidity
  final bool showIndoor;
  final bool showOutdoor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final wx = Wx.of(context);
    final unit = temperature ? '°' : '%';

    final inSpots = <FlSpot>[];
    final outSpots = <FlSpot>[];
    double lo = double.infinity;
    double hi = -double.infinity;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final double? a = temperature ? p.indoorTemperature : p.indoorHumidity;
      final double? b = temperature ? p.outdoorTemperature : p.outdoorHumidity;
      final t = p.timestamp.toLocal();
      final x = t.hour + (t.minute / 60.0) + (t.second / 3600.0);
      if (showIndoor && a != null) {
        inSpots.add(FlSpot(x, a));
        lo = math.min(lo, a);
        hi = math.max(hi, a);
      }
      if (showOutdoor && b != null) {
        outSpots.add(FlSpot(x, b));
        lo = math.min(lo, b);
        hi = math.max(hi, b);
      }
    }

    List<FlSpot> cleanSpots(List<FlSpot> spots) {
      if (spots.isEmpty) return [];
      spots.sort((a, b) => a.x.compareTo(b.x));
      final List<FlSpot> cleaned = [];
      for (final s in spots) {
        if (cleaned.isEmpty || (s.x - cleaned.last.x).abs() > 0.05) {
          cleaned.add(s);
        } else {
          cleaned[cleaned.length - 1] = s;
        }
      }
      return cleaned;
    }

    final cleanInSpots = cleanSpots(inSpots);
    final cleanOutSpots = cleanSpots(outSpots);

    if (inSpots.isEmpty && outSpots.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('Collecting readings…', style: wx.t(13, c: wx.textDim)),
        ),
      );
    }

    final span = hi - lo;
    final pad = span > 2 ? span * 0.15 : 1.0;
    var minY = (lo - pad).floorToDouble();
    var maxY = (hi + pad).ceilToDouble();
    if (!temperature) {
      minY = math.max(0, minY);
      maxY = math.min(100, maxY);
    }
    final interval = ((maxY - minY) / 3).clamp(1.0, 50.0).toDouble();

    LineChartBarData make(List<FlSpot> spots, Color color, {bool marker = false}) =>
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          preventCurveOverShooting: true,
          color: color,
          barWidth: 2.4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          showingIndicators: marker ? [spots.length - 1] : const [],
          belowBarData: BarAreaData(
            show: marker,
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        );

    final bars = <LineChartBarData>[];
    final colors = <Color>[];
    if (inSpots.isNotEmpty) {
      bars.add(make(cleanInSpots, wx.accent, marker: true));
      colors.add(wx.accent);
    }
    if (outSpots.isNotEmpty) {
      bars.add(make(cleanOutSpots, wx.outdoorLine, marker: cleanInSpots.isEmpty));
      colors.add(wx.outdoorLine);
    }

    String timeAtHour(double x) {
      final clamped = x.clamp(0.0, 24.0);
      final totalMin = (clamped * 60).round();
      final h = (totalMin ~/ 60) % 24;
      final m = totalMin % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }

    final axis = wx.t(11, c: wx.textDim);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0.0,
          maxX: 24.0,
          minY: minY,
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: wx.textDim.withValues(alpha: 0.25),
              strokeWidth: 0.8,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: interval,
                getTitlesWidget: (v, meta) =>
                    Text('${v.round()}$unit', style: axis),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 6.0,
                getTitlesWidget: (v, meta) {
                  final h = v.toInt();
                  if (h == 0 || h == 6 || h == 12 || h == 18 || h == 24) {
                    return Text('${h.toString().padLeft(2, '0')}:00', style: axis);
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (barData, indexes) => indexes
                .map(
                  (_) => TouchedSpotIndicatorData(
                    FlLine(color: wx.text, strokeWidth: 1.2, dashArray: [4, 4]),
                    FlDotData(
                      getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                        radius: 5,
                        color: bar.color ?? wx.accent,
                        strokeWidth: 2.5,
                        strokeColor: wx.isDark ? wx.bg : Colors.white,
                      ),
                    ),
                  ),
                )
                .toList(),
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => wx.isDark ? const Color(0xFF3A2D49) : Colors.white,
              tooltipRoundedRadius: 14,
              fitInsideHorizontally: true,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              getTooltipItems: (spots) => [
                for (var k = 0; k < spots.length; k++)
                  LineTooltipItem(
                    '${spots[k].y.toStringAsFixed(1)}$unit',
                    wx.t(13, w: FontWeight.w600, c: colors[spots[k].barIndex]),
                    children: k == 0
                        ? [
                            TextSpan(
                              text: '  ${timeAtHour(spots[k].x)}',
                              style: wx.t(11, c: wx.textDim),
                            ),
                          ]
                        : null,
                  ),
              ],
            ),
          ),
          showingTooltipIndicators: [
            ShowingTooltipIndicators([
              LineBarSpot(bars.first, 0, bars.first.spots.last),
            ]),
          ],
          lineBarsData: bars,
        ),
      ),
    );
  }
}
