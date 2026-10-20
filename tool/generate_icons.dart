import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Generate launcher artwork from the supplied DZD geometry', () async {
    final source = File('assets/dzd.svg').readAsStringSync().replaceAll(
      'fill:rgb(255,0,0)', 'fill:rgb(6,37,26)');
    final picture = await vg.loadPicture(SvgStringLoader(source), null);
    final files = <File>[
      for (final folder in ['android/app/src/main/res', 'ios/Runner/Assets.xcassets/AppIcon.appiconset', 'web/icons'])
        ...Directory(folder).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.png')),
      File('web/favicon.png'),
    ];
    for (final file in files) {
      final bytes = file.readAsBytesSync();
      final header = ByteData.sublistView(bytes);
      final width = header.getUint32(16);
      final height = header.getUint32(20);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xFF34D399), ui.BlendMode.src);
      final scale = height * .64 / picture.size.height;
      canvas.translate((width - picture.size.width * scale) / 2, height * .18);
      canvas.scale(scale);
      canvas.drawPicture(picture.picture);
      final drawing = recorder.endRecording();
      final image = await drawing.toImage(width, height);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      file.writeAsBytesSync(png!.buffer.asUint8List());
      image.dispose();
      drawing.dispose();
    }
    picture.picture.dispose();
  });
}
