import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('layer dependencies point toward the domain', () {
    for (final file
        in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final relative =
          file.absolute.path.replaceAll('\\', '/').split('/lib/').last;
      final layer = relative.split('/').first;
      for (final match in RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''')
          .allMatches(file.readAsStringSync())) {
        final imported = match.group(1)!;
        if (relative.startsWith('presentation/widgets/')) {
          expect(imported.contains('/screens/'), isFalse,
              reason: 'Shared widgets must not depend on screens: $relative');
        }
        if (layer == 'domain') {
          expect(imported.startsWith('package:'), isFalse,
              reason: '$relative must stay independent of Flutter and plugins');
        }
        String? target;
        if (imported.startsWith('package:wafir/')) {
          target = imported.substring('package:wafir/'.length).split('/').first;
        } else if (!imported.contains(':')) {
          final resolved = file.absolute.uri.resolve(imported).path;
          target = resolved.split('/lib/').last.split('/').first;
        }
        if (target == null) continue;
        if (layer == 'domain') {
          expect(target, 'domain', reason: '$relative -> $imported');
        }
        if (layer == 'data') {
          expect(['domain', 'data'], contains(target),
              reason: '$relative -> $imported');
        }
        if (layer == 'presentation') {
          expect(['domain', 'presentation'], contains(target),
              reason: '$relative -> $imported');
        }
      }
    }
  });
}
