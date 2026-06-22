import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _Glyph {
  final double x, y, w, h, xoff, yoff, xadv;
  _Glyph(this.x, this.y, this.w, this.h, this.xoff, this.yoff, this.xadv);
}

/// 원작 font.png + font.xml (AngelCode/Glyph Designer 포맷) 비트맵 폰트.
class BitmapFont {
  BitmapFont._(this.image, this.glyphs, this.lineHeight, this.base);

  final ui.Image image;
  final Map<int, _Glyph> glyphs;
  final double lineHeight;
  final double base;

  static BitmapFont? instance;

  static Future<void> ensureLoaded() async {
    if (instance != null) return;
    final bytes = await rootBundle.load('assets/images/font.png');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    final xml = await rootBundle.loadString('assets/images/font.xml');

    double attr(String src, String name) {
      final m = RegExp('$name="(-?\\d+)"').firstMatch(src);
      return m == null ? 0 : double.parse(m.group(1)!);
    }

    final common = RegExp(r'<common[^>]*>').firstMatch(xml)!.group(0)!;
    final lineHeight = attr(common, 'lineHeight');
    final base = attr(common, 'base');

    final glyphs = <int, _Glyph>{};
    for (final m in RegExp(r'<char\s[^>]*>').allMatches(xml)) {
      final c = m.group(0)!;
      final id = attr(c, 'id').toInt();
      glyphs[id] = _Glyph(
        attr(c, 'x'),
        attr(c, 'y'),
        attr(c, 'width'),
        attr(c, 'height'),
        attr(c, 'xoffset'),
        attr(c, 'yoffset'),
        attr(c, 'xadvance'),
      );
    }
    instance = BitmapFont._(image, glyphs, lineHeight, base);
  }

  Size measure(String text, double scale) {
    double w = 0;
    for (final code in text.runes) {
      final g = glyphs[code] ?? glyphs[32];
      if (g != null) w += g.xadv * scale;
    }
    return Size(w, lineHeight * scale);
  }
}

/// 비트맵 폰트로 한 줄 텍스트를 그리는 위젯.
class BitmapText extends StatelessWidget {
  const BitmapText(this.text,
      {super.key, this.scale = 1.0, this.color = Colors.white});

  final String text;
  final double scale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final font = BitmapFont.instance;
    if (font == null) {
      return Text(text,
          style: TextStyle(
              color: color,
              fontFamily: 'monospace',
              fontSize: 14 * scale,
              fontWeight: FontWeight.bold));
    }
    final size = font.measure(text, scale);
    return CustomPaint(size: size, painter: _BitmapTextPainter(font, text, scale, color));
  }
}

class _BitmapTextPainter extends CustomPainter {
  _BitmapTextPainter(this.font, this.text, this.scale, this.color);
  final BitmapFont font;
  final String text;
  final double scale;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false
      ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    double penX = 0;
    for (final code in text.runes) {
      final g = font.glyphs[code] ?? font.glyphs[32];
      if (g == null) continue;
      if (g.w > 0 && g.h > 0) {
        final src = Rect.fromLTWH(g.x, g.y, g.w, g.h);
        final dst = Rect.fromLTWH(
            penX + g.xoff * scale, g.yoff * scale, g.w * scale, g.h * scale);
        canvas.drawImageRect(font.image, src, dst, paint);
      }
      penX += g.xadv * scale;
    }
  }

  @override
  bool shouldRepaint(_BitmapTextPainter old) =>
      old.text != text || old.scale != scale || old.color != color;
}
