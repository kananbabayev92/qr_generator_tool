import 'package:flutter_test/flutter_test.dart';
import 'package:qr_tool_app/services/security_service.dart';

void main() {
  group('SecurityService Tests', () {
    test('Detects safe text and safe HTTPS URLs', () {
      final textResult = SecurityService.analyze('Salam dünya');
      expect(textResult.level, ThreatLevel.safe);
      expect(textResult.isBlocked, false);

      final httpsResult = SecurityService.analyze('https://flutter.dev/docs');
      expect(httpsResult.level, ThreatLevel.safe);
      expect(httpsResult.isBlocked, false);
    });

    test('Blocks dangerous schemes (javascript, file, data)', () {
      final jsResult = SecurityService.analyze('javascript:alert("hacked")');
      expect(jsResult.level, ThreatLevel.dangerous);
      expect(jsResult.isBlocked, true);

      final fileResult = SecurityService.analyze('file:///android_asset/something');
      expect(fileResult.level, ThreatLevel.dangerous);
      expect(fileResult.isBlocked, true);
    });

    test('Blocks malware files (.apk, .exe, .bat, .sh)', () {
      final apkResult = SecurityService.analyze('https://evil-site.com/download/trojan.apk');
      expect(apkResult.level, ThreatLevel.dangerous);
      expect(apkResult.isExecutableMalware, true);
      expect(apkResult.isBlocked, true);

      final exeResult = SecurityService.analyze('https://example.com/payload.exe?token=123');
      expect(exeResult.level, ThreatLevel.dangerous);
      expect(exeResult.isExecutableMalware, true);
      expect(exeResult.isBlocked, true);

      final batResult = SecurityService.analyze('script.bat');
      expect(batResult.level, ThreatLevel.dangerous);
      expect(batResult.isExecutableMalware, true);
      expect(batResult.isBlocked, true);
    });

    test('Blocks XSS and script injections', () {
      final xssResult = SecurityService.analyze('<script>fetch("http://evil.com")</script>');
      expect(xssResult.level, ThreatLevel.dangerous);
      expect(xssResult.isBlocked, true);
    });

    test('Flags suspicious unencrypted HTTP or IP links', () {
      final httpResult = SecurityService.analyze('http://insecure-site.com');
      expect(httpResult.level, ThreatLevel.suspicious);
      expect(httpResult.isBlocked, false);

      final ipResult = SecurityService.analyze('http://192.168.1.1/admin');
      expect(ipResult.level, ThreatLevel.suspicious);
      expect(ipResult.warnings.isNotEmpty, true);
    });

    test('Enforces maximum safe input length', () {
      final oversized = 'A' * 3000;
      final lenResult = SecurityService.analyze(oversized);
      expect(lenResult.level, ThreatLevel.dangerous);
      expect(lenResult.isBlocked, true);
    });
  });
}
