import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'connection_page.dart';

Uri buildWebSocketUri(String input) {
  final trimmedInput = input.trim();

  if (trimmedInput.isEmpty) {
    throw ArgumentError('IP address cannot be empty');
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
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: [BarcodeFormat.qrCode],
  );

  final TextEditingController ipController = TextEditingController();

  bool isFlashOn = false;
  bool showManualEntry = false;
  String connectionStatus = "Waiting for QR Scan";
  String? scannedCode;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    ipController.dispose();
    super.dispose();
  }

  Future<void> _connectToSocket(String input) async {
    try {
      final uri = buildWebSocketUri(input);

      setState(() {
        connectionStatus = "Connecting...";
      });

      await controller.stop();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConnectionPage(
            serverAddress: uri.host,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

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

  void _connectManually() {
    final ip = ipController.text.trim();

    if (ip.isEmpty) {
      setState(() {
        connectionStatus = "Please enter an IP address";
      });
      return;
    }

    _connectToSocket(ip);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connect to Race"),
        actions: [
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: () async {
              await controller.toggleTorch();

              setState(() {
                isFlashOn = !isFlashOn;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),

          // Instructions at the top
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Point the camera at a QR code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Manual entry panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.black87,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showManualEntry) ...[
              TextField(
                controller: ipController,
                keyboardType: TextInputType.url,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Server IP Address",
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: "192.168.1.100:5000",
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.wifi),
                  label: const Text("Connect"),
                  onPressed: _connectManually,
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () {
                  setState(() {
                    showManualEntry = false;
                    connectionStatus = "Waiting for QR Scan";
                  });
                },
                child: const Text(
                  "Back to QR Scanner",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ] else ...[
              Text(
                connectionStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.keyboard),
                  label: const Text("Enter IP Address Manually"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  onPressed: () {
                    setState(() {
                      showManualEntry = true;
                      connectionStatus = "Enter the server IP address";
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}