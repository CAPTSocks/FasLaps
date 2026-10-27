import 'package:flutter/material.dart';
import 'qr_scanner_page.dart';
import 'settings_page.dart';
import 'package:faslapsapp/pages/race_history_page.dart';
import 'package:faslapsapp/Pages/practice_race_history_page.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_cars_page.dart';

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
    final newFirstName = firstName.isNotEmpty
        ? firstName[0].toUpperCase() + firstName.substring(1)
        : '';
    final newLastName = lastName.isNotEmpty
        ? lastName[0].toUpperCase() + lastName.substring(1)
        : '';

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FasLaps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'My Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsPage()),
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome header
              // Text(
              //   'Welcome back!',
              //   style: theme.textTheme.headlineSmall?.copyWith(
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // const SizedBox(height: 4),
              // Text(
              //   '$newFirstName $newLastName'.trim(),
              //   style: theme.textTheme.bodyLarge?.copyWith(
              //     color: theme.colorScheme.onSurfaceVariant,
              //   ),
              // ),
              const SizedBox(height: 200),

              // Main action: Connect to Race
              SizedBox(
                height: 100,
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(
                      color: Color.fromARGB(255, 180, 67, 6),
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QRScannerPage(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.qr_code_scanner,
                            size: 34,
                            color: Color(0xFFEA661E),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Connect to Race',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Scan a QR code to connect',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFFEA661E),
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Compact history buttons side by side
              Row(
                children: [
                  Expanded(
                    child: _MenuButton(
                      icon: Icons.emoji_events_outlined,
                      label: 'My Races',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RaceHistoryPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MenuButton(
                      icon: Icons.timer_outlined,
                      label: 'My Practices',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PracticeRaceHistoryPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // My Cars
              // My Cars
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5 - 20,
                  height: 52,
                  child: _MenuButton(
                    icon: Icons.directions_car,
                    label: "My Cars",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedSlotCarsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Spacer(),

              // Development tools: remove before release if desired
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Developer Tools'),
                leading: const Icon(Icons.build_outlined),
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await NotificationService.instance
                            .showTestNotification();
                      },
                      child: const Text('Test Notification'),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Delete All Saved Races?'),
                            content: const Text(
                              'This will permanently clear the saved '
                              'race history on this device.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Delete All'),
                              ),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        final prefs = await SharedPreferences.getInstance();
                        final removed = await prefs.remove('savedRaces');
                        final remaining = prefs.getString('savedRaces');

                        debugPrint('Key removed: $removed');
                        debugPrint('Remaining race data: $remaining');

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              remaining == null
                                  ? 'Saved race history cleared.'
                                  : 'Could not clear all race history.',
                            ),
                          ),
                        );
                      },
                      child: const Text('Delete All Saved Races'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable compact button for the two history features.
class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 28, 28, 34),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: BorderSide(
            color: Color.fromARGB(255, 180, 67, 6),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: Color(0xFFEA661E)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
