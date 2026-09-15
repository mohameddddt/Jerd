// Renders the launcher icon with Flutter itself, so the Arabic wordmark is
// shaped correctly with the bundled Rubik font.
//
//   flutter test tool/generate_icon_test.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _terracotta = Color(0xFFB85C38);
const _cream = Color(0xFFFFF8F2);

Future<void> _render(WidgetTester tester, Widget child, String path) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: RepaintBoundary(key: key, child: SizedBox(width: 1024, height: 1024, child: child)),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Widget _wordmark(double size) => Text(
      'جرد',
      style: TextStyle(fontFamily: 'Rubik', fontSize: size, fontWeight: FontWeight.w700, color: _cream, height: 1),
    );

void main() {
  testWidgets('generate launcher icons', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final loader = FontLoader('Rubik')..addFont(rootBundle.load('assets/fonts/Rubik-700.ttf'));
    await tester.runAsync(loader.load);

    // Legacy icon: the full rounded tile, as on the login screen.
    await _render(
      tester,
      Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: _terracotta, borderRadius: BorderRadius.circular(220)),
        child: _wordmark(400),
      ),
      'assets/icon/icon.png',
    );

    // Adaptive foreground: transparent, wordmark inside the 66% safe zone.
    await _render(tester, Center(child: _wordmark(300)), 'assets/icon/icon_foreground.png');

    expect(File('assets/icon/icon.png').existsSync(), isTrue);
  });
}
