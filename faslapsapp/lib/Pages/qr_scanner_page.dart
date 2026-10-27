import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'race_monitor_page.dart';

Uri buildWebSocketUri(String input) {
  final trimmedInput = input.trim();

  if (trimmedInput.isEmpty) {
    throw const FormatException('Please enter an IP address.');
  }

  final normalizedInput =
      trimmedInput.startsWith('ws://') || trimmedInput.startsWith('wss://')
      ? trimmedInput
      : 'ws://$trimmedInput';

  final uri = Uri.tryParse(normalizedInput);

  if (uri == null ||
      (uri.scheme != 'ws' && uri.scheme != 'wss') ||
      uri.host.isEmpty) {
    throw const FormatException('Please enter a valid IP address.');
  }

  if (InternetAddress.tryParse(uri.host) == null) {
    throw const FormatException(
      'Invalid IP address. Please enter a valid IPv4 or IPv6 address.',
    );
  }

  if (uri.hasPort && (uri.port < 1 || uri.port > 65535)) {
    throw const FormatException(
      'Invalid port number. Please enter a port between 1 and 65535.',
    );
  }

  return uri;
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
  String? ipError;

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

  Future<void> _testServerConnection(Uri uri) async {
    final connectionUri = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : 5000,
      path: uri.path.isEmpty || uri.path == '/' ? '/mobile' : uri.path,
    );

    debugPrint("Testing WebSocket connection: $connectionUri");

    WebSocket? socket;

    try {
      socket = await WebSocket.connect(
        connectionUri.toString(),
      ).timeout(const Duration(seconds: 5));

      // The connection was successful.
      // Close this temporary connection before starting the
      // actual background service connection.
      await socket.close();
    } finally {
      // Ensure the temporary socket is closed if anything goes wrong.
      if (socket != null && socket.readyState != WebSocket.closed) {
        await socket.close();
      }
    }
  }

  Future<void> _connectToSocket(String input) async {
    debugPrint("Connecting using input: '$input'");
    try {
      // Step 1: Validate the IP address.
      final uri = buildWebSocketUri(input);

      if (!mounted) return;

      setState(() {
        ipError = null;
        connectionStatus = "Testing server connection...";
      });

      // Step 2: Test whether the server is actually reachable.
      await _testServerConnection(uri);

      if (!mounted) return;

      // Step 3: Only navigate if the connection test succeeds.
      setState(() {
        connectionStatus = "Connected! Opening race monitor...";
      });

      await controller.stop();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RaceMonitorPage(serverAddress: uri.host),
        ),
      );
    } on FormatException catch (e) {
      if (!mounted) return;

      setState(() {
        ipError = e.message;
        connectionStatus = "Invalid IP Address";
        scannedCode = null;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        ipError =
            "Connection timed out. Make sure the FasLaps server is running.";
        connectionStatus = "Connection Timed Out";
        scannedCode = null;
      });
    } on SocketException {
      if (!mounted) return;

      setState(() {
        ipError =
            "Could not reach the server. Check the IP address and make sure the server is running.";
        connectionStatus = "Server Unavailable";
        scannedCode = null;
      });
    } on WebSocketException {
      if (!mounted) return;

      setState(() {
        ipError =
            "The server rejected the connection. Make sure the FasLaps server is running on the correct port.";
        connectionStatus = "Connection Failed";
        scannedCode = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        ipError = "Unable to connect to the server. Please try again.";
        connectionStatus = "Connection Failed";
        scannedCode = null;
      });

      debugPrint("Server connection test failed: $e");
    }
  }

  void _handleBarcode(BarcodeCapture capture) {
    final barcode = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;

    if (barcode == null || barcode == scannedCode) return;

    debugPrint("QR code scanned: '$barcode'");

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
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _handleBarcode),

          // Instructions at the top
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

          // Manual entry panel
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.black87),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showManualEntry) ...[
              TextField(
                controller: ipController,
                keyboardType: TextInputType.url,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  if (ipError != null) {
                    setState(() {
                      ipError = null;
                    });
                  }
                },

                decoration: InputDecoration(
                  labelText: "Server IP Address",
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: "192.168.1.100:5000",
                  hintStyle: const TextStyle(color: Colors.white38),

                  errorText: ipError,

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
              Column(
                children: [
                  Text(
                    connectionStatus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),

                  if (ipError != null && !showManualEntry) ...[
                    const SizedBox(height: 8),

                    Text(
                      ipError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
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
