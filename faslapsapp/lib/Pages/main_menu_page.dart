import 'package:flutter/material.dart';
import 'enter_ip_page.dart';
import 'settings_page.dart';
import 'package:faslapsapp/pages/race_history_page.dart';

class MainMenuPage extends StatelessWidget {
  final String firstName;
  final String lastName;

  const MainMenuPage({
    super.key,
    required this.firstName,
    required this.lastName,
  });

  

  @override
  Widget build(BuildContext context) {
    String newfirstName = firstName[0].toUpperCase() + firstName.substring(1);
    String newLastName = lastName[0].toUpperCase() + lastName.substring(1);
    return Scaffold(
      appBar: AppBar(title: const Text("Main Menu")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            Text(
              "Welcome $newfirstName $newLastName",
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 30),

            FilledButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Scan QR Code"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EnterIPPage()),
                );
              },
            ),

            FilledButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text("Settings"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsPage()),
                );
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RaceHistoryPage(),
                  ),
                );
              },
              child: const Text("Race History"),
            ),
          ],
        ),
      ),
    );
  }
}
