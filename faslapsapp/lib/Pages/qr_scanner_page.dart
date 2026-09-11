import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'connection_page.dart';

Uri buildWebSocketUri(String input) {
  final trimmedInput = input.trim();

  if (trimmedInput.isEmpty) {
    throw ArgumentError('QR code input cannot be empty');
  }

  final normalizedInput =
      trimmedInput.startsWith('ws://') || trimmedInput.startsWith('wss://')
      ? trimmedInput
      : 'ws://$trimmedInput';

  return Uri.parse(
    normalizedInput.endsWith('/') ? normalizedInput : '$normalizedInput/',
  );
}

class QRScannerPage extends StatefulWidget {
  final String? manualIP;

  const QRScannerPage({super.key, this.manualIP});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );

  bool isFlashOn = false;
  String connectionStatus = "Waiting for QR Scan";
  String? scannedCode;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    if (widget.manualIP != null) {
      _connectToSocket(widget.manualIP!);
    }
  }

  Future<void> _connectToSocket(String input) async {
    try {
      final uri = buildWebSocketUri(input);

      // setState(() {
      //   connectionStatus = "Connecting...";
      // });

      //final socket = WebSocketChannel.connect(uri);

      await controller.stop();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ConnectionPage(serverAddress: uri.host),
        ),
      );
    } catch (e) {
      setState(() {
        connectionStatus = "Connection Failed";
      });
    }
  }

  void _handleBarcode(BarcodeCapture capture) {
    final barcode = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;

    if (barcode == null || barcode == scannedCode) return;

    scannedCode = barcode;

    _connectToSocket(barcode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code Reader"),
        actions: [
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              await controller.toggleTorch();

              setState(() {
                isFlashOn = !isFlashOn;
              });
            },
          ),
        ],
      ),
      body: widget.manualIP == null
          ? _buildScanner()
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        Positioned(
          top: 24,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Point the camera at a QR code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        MobileScanner(controller: controller, onDetect: _handleBarcode),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              connectionStatus,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}
