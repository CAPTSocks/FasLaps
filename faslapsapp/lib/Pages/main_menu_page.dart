import 'package:flutter/material.dart';
import 'qr_scanner_page.dart';
import 'settings_page.dart';
import 'package:faslapsapp/pages/race_history_page.dart';
import 'package:faslapsapp/Pages/practice_race_history_page.dart';

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
    double buttonSpace = 8.0;
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
              label: const Text("Connect To Race"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QRScannerPage()),
                );
              },
            ),
            SizedBox(height: buttonSpace),
            FilledButton.icon(
              icon: const Icon(Icons.sports_score),
              label: const Text("My Races"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RaceHistoryPage(),
                  ),
                );
              },
            ),
            SizedBox(height: buttonSpace),

            FilledButton.icon(
              icon: const Icon(Icons.timer),
              label: const Text("My Practices"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PracticeRaceHistoryPage(),
                  ),
                );
              },
            ),

            SizedBox(height: buttonSpace),
            FilledButton.icon(
              icon: const Icon(Icons.car_rental),
              label: const Text("My Cars"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PracticeRaceHistoryPage(),
                  ),
                );
              },
            ),

            SizedBox(height: buttonSpace),
            FilledButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text("My Settings"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
