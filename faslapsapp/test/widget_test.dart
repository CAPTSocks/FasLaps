import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faslapsapp/Pages/qr_scanner_page.dart';

void main() {
  testWidgets('QR scanner page loads', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: QRScannerPage(),
      ),
    );

    expect(find.text('QR Code Reader'), findsOneWidget);
    expect(find.text('Point the camera at a QR code'), findsOneWidget);
  });

  test('buildWebSocketUri converts IP input into a websocket URI', () {
    expect(buildWebSocketUri('192.168.1.10'), Uri.parse('ws://192.168.1.10/'));
    expect(buildWebSocketUri('192.168.1.10:8080'), Uri.parse('ws://192.168.1.10:8080/'));
  });
}
