// Velio's line icons and the duotone photo placeholder, drawn from the same SVG path data as the
// design system (apps/web/components/primitives.tsx), so the app and the web match.
import 'package:flutter/material.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../domain/env.dart';

const _paths = {
  'plus': 'M12 5v14M5 12h14',
  'minus': 'M5 12h14',
  'list': 'M8.5 6.5h12M8.5 12h12M8.5 17.5h12M4 6.5h.01M4 12h.01M4 17.5h.01',
  'clock': 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7.5V12l3 2',
  'target': 'M12 19.5a7.5 7.5 0 1 0 0-15 7.5 7.5 0 0 0 0 15zM12 2v3M12 19v3M2 12h3M19 12h3M12 13.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z',
  'calendar': 'M4 6.5h16v13H4zM4 10h16M8 4v4M16 4v4',
  'pin':
      'M12 21s-6.5-5.6-6.5-11a6.5 6.5 0 0 1 13 0C18.5 15.4 12 21 12 21zM12 12.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z',
  'price': 'M4 12.5V5h7.5l8.5 8.5-7.5 7.5zM8.5 9h.01',
  'host': 'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4.5 20.5c1.2-3.6 4-5.5 7.5-5.5s6.3 1.9 7.5 5.5',
  'people': 'M9 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7zM2.5 20c.9-3.2 3.3-5 6.5-5s5.6 1.8 6.5 5M16 4.5a3.2 3.2 0 0 1 0 6.2M18 15.3c1.7.6 2.9 2.2 3.5 4.7',
  'directions': 'M12 2.8l9.2 9.2-9.2 9.2L2.8 12zM9 14.5V12a1.5 1.5 0 0 1 1.5-1.5H15M13 8.5l2 2-2 2',
  'check': 'M5 12.5l4.5 4.5L19 7.5',
  'close': 'M6 6l12 12M18 6L6 18',
  'search': 'M10.5 17.5a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM15.5 15.5L20.5 20.5',
  'share': 'M12 15V3.5M7.5 8L12 3.5 16.5 8M5 12.5V20h14v-7.5',
  'copy': 'M8.5 8.5h11v11h-11zM15.5 8.5v-4h-11v11h4',
  'chevron': 'M9.5 5.5L16 12l-6.5 6.5',
  'back': 'M14.5 5.5L8 12l6.5 6.5',
  'offline': 'M3 3l18 18M8.5 16.5a5 5 0 0 1 7 0M5 13a10 10 0 0 1 4.5-2.4M19 13a10 10 0 0 0-2.3-1.6M2 9.5A14 14 0 0 1 7 6.6M22 9.5A14 14 0 0 0 11 6M12 20h.01',
  'alert': 'M12 3.5l9.5 16.5h-19zM12 10v4.5M12 17.5h.01',
  'info': 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 11v5.5M12 7.5h.01',
  'lock': 'M6 10.5h12v10H6zM8.5 10.5V7.5a3.5 3.5 0 0 1 7 0v3',
  'map': 'M3.5 6.5L9 4l6 2.5L20.5 4v13.5L15 20l-6-2.5L3.5 20zM9 4v13.5M15 6.5V20',
  'flag': 'M5 21V4M5 4.5h12l-2.5 4 2.5 4H5',
  'ticket': 'M3.5 7.5h17v3a2 2 0 0 0 0 4v3h-17v-3a2 2 0 0 0 0-4zM14.5 7.5v10',
  'refresh': 'M20 11.5A8 8 0 0 0 5.5 7M4 12.5A8 8 0 0 0 18.5 17M5 3.5V7h3.5M19 20.5V17h-3.5',
  'phone': 'M7 2.5h10v19H7zM11 18.5h2',
};

class _PathProxy extends PathProxy {
  final path = Path();
  @override
  void close() => path.close();
  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) =>
      path.cubicTo(x1, y1, x2, y2, x3, y3);
  @override
  void lineTo(double x, double y) => path.lineTo(x, y);
  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
}

final _cache = <String, Path>{};
Path svgPath(String d) => _cache.putIfAbsent(d, () {
  final proxy = _PathProxy();
  writeSvgPathDataToPath(d, proxy);
  return proxy.path;
});

/// A 24 px-grid line icon, 1.75 stroke. Decorative unless [label] is given.
class VIcon extends StatelessWidget {
  const VIcon(this.name, {super.key, this.size = 20, this.color, this.label});
  final String name;
  final double size;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final icon = CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(_paths[name]!, color ?? IconTheme.of(context).color ?? VelioColors.forest),
    );
    return label == null ? ExcludeSemantics(child: icon) : Semantics(label: label, image: true, child: icon);
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.d, this.color);
  final String d;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(
      svgPath(d),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.d != d || old.color != color;
}

enum Scene { lake, savanna, city, coast }

const _scenes = {
  Scene.lake: [VelioColors.sun, VelioColors.peach, VelioColors.forest, VelioColors.sky],
  Scene.savanna: [VelioColors.peach, VelioColors.sun, VelioColors.forest, VelioColors.lime],
  Scene.city: [VelioColors.lilac, VelioColors.sky, VelioColors.forest, VelioColors.lime],
  Scene.coast: [VelioColors.sky, VelioColors.lime, VelioColors.forest, VelioColors.info],
};

/// Duotone landscape: the placeholder when an activity has no photo yet.
class PhotoArt extends StatelessWidget {
  const PhotoArt({super.key, this.scene = Scene.lake});
  final Scene scene;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(painter: _ScenePainter(_scenes[scene]!), child: const SizedBox.expand()),
  );
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.c);
  final List<Color> c;

  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 320×200 with "slice" (cover), as on the web.
    final scale = size.width / 320 > size.height / 200 ? size.width / 320 : size.height / 200;
    canvas.clipRect(Offset.zero & size);
    canvas.translate((size.width - 320 * scale) / 2, (size.height - 200 * scale) / 2);
    canvas.scale(scale);
    final p = Paint();
    canvas.drawRect(const Rect.fromLTWH(0, 0, 320, 200), p..color = c[0]);
    canvas.drawCircle(const Offset(232, 78), 30, p..color = VelioColors.surface.withValues(alpha: 0.85));
    canvas.drawPath(svgPath('M0 120 L60 84 L110 108 L170 70 L240 112 L320 92 L320 200 L0 200Z'), p..color = c[1]);
    canvas.drawPath(svgPath('M0 140 L320 132 L320 200 L0 200Z'), p..color = c[3]);
    canvas.drawPath(
      svgPath('M0 150 C60 140 90 160 150 152 C210 144 260 162 320 150 L320 200 L0 200Z'),
      p..color = c[2],
    );
    canvas.drawPath(svgPath('M150 132 l14 -6 l14 6z'), p..color = c[2]);
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.c != c;
}

/// An uploaded photo (`/photos/…`), or the scene art when there is none or it fails to load.
/// [small] takes the 640 px variant (the API's `smallVariantKey`) for cards and thumbnails.
class Photo extends StatelessWidget {
  const Photo({super.key, required this.url, this.small = false, this.scene = Scene.lake, this.dimmed = false});
  final String? url;
  final bool small;
  final Scene scene;
  final bool dimmed;

  static String resolve(String url, {bool small = false}) {
    final path = small ? url.replaceFirstMapped(RegExp(r'\.([a-z]+)$'), (m) => '-640.${m[1]}') : url;
    return path.startsWith('/') ? '$apiBaseUrl$path' : path;
  }

  @override
  Widget build(BuildContext context) {
    final u = url;
    final child = u == null
        ? PhotoArt(scene: scene)
        : Image.network(
            resolve(u, small: small),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => PhotoArt(scene: scene),
          );
    return ColoredBox(
      color: VelioColors.forest,
      child: Opacity(opacity: dimmed ? 0.55 : 1, child: child),
    );
  }
}
