import 'package:flutter/material.dart';
import 'qr_scanner_page.dart';

class EnterIPPage extends StatefulWidget {
  
  const EnterIPPage({super.key});

  @override
  State<EnterIPPage> createState() => _EnterIPPageState();
  
}

class _EnterIPPageState extends State<EnterIPPage> {
final TextEditingController ipController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter IP Address")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            const SizedBox(height: 30),

            FilledButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Scan QR Code"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QRScannerPage()),
                );
              },
            ),

            Padding(padding: const EdgeInsets.all(20)),

            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: "Manually Enter IP Address",
                border: OutlineInputBorder(),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Manually enter IP address.",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  const SizedBox(height: 20),

                  FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Submit"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QRScannerPage(
                            manualIP: ipController.text.trim(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
