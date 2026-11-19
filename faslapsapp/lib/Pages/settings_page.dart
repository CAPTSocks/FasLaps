import 'package:flutter/material.dart';
//import 'main_menu_page.dart';
import '../services/tts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TtsService ttsService = TtsService.instance;
  bool keepScreenOn = false;

  @override
  void initState() {
    super.initState();
    _loadScreenSettings();
  }

  Future<void> _loadScreenSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      keepScreenOn = prefs.getBool('keepScreenOn') ?? false;
    });
  }

  Future<void> _saveScreenSettings(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('keepScreenOn', value);

    if (!mounted) return;

    setState(() {
      keepScreenOn = value;
    });
  }

  Future<void> _changeTtsSettings(BuildContext context) async {
    //final TtsService ttsService = TtsService();
    await ttsService.initializeTTS();
    double newRate = ttsService.speechRate;
    double newVolume = ttsService.volume;
    double newPitch = ttsService.pitch; // Default value
    // Default value
    //ttsService.initializeTTS(); // Initialize TTS before using it
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('TTS Settings'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Volume: ${newVolume.toStringAsFixed(1)}"),
                  Slider(
                    value: newVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    //label: "Volume: ${newVolume.toStringAsFixed(1)}",
                    onChanged: (double value) {
                      setState(() {
                        newVolume = value;
                      });
                    },
                  ),
                  Text("Speech Rate: ${newRate.toStringAsFixed(1)}"),
                  Slider(
                    value: newRate,
                    min: 0.1,
                    max: 2.0,
                    divisions: 19,
                    onChanged: (double value) {
                      setState(() {
                        newRate = value;
                      });
                    },
                  ),
                  Text("Pitch: ${newPitch.toStringAsFixed(1)}"),
                  Slider(
                    value: newPitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    onChanged: (double value) {
                      setState(() {
                        newPitch = value;
                      });
                    },
                  ),

                  FilledButton(
                     style: FilledButton.styleFrom(
                       shadowColor: Colors.black,
                       elevation: 3,
                    ),
                    onPressed: () async {
                      await ttsService.setSpeechRate(newRate);
                      await ttsService.setVolume(newVolume);
                      await ttsService.setPitch(newPitch);
                      await ttsService.speak(
                        "This is a test of the new speech rate.",
                      );
                    },
                    child: const Text("Test Text to Speech"),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await ttsService.setSpeechRate(newRate);
                await ttsService.setVolume(newVolume);
                await ttsService.setPitch(newPitch);
                Navigator.pop(context);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('firstName');
    await prefs.remove('lastName');
    await prefs.remove('pin');
  }

  Future<void> _changeUserSettings(BuildContext context) async {
    bool isNotificationsEnabled = false; // Default value
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('User Settings'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter dialogSetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Configure your account preferences below:"),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 1. Wrap the First Name TextField in Expanded
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "First Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),

                      // 2. Add a small horizontal gap between the fields
                      const SizedBox(width: 10),

                      // 3. Wrap the Last Name TextField in Expanded
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: "Last Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Pin",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),


                  //TODO: Remove this before release. This is just for testing purposes.
                  FilledButton(
                     style: FilledButton.styleFrom(
                       shadowColor: Colors.black,
                       elevation: 3,
                    ),
                    onPressed: () {
                      _clearUserData();
                    },
                    child: Text("Clear User Data"),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                print("Saved Notification Preference: $isNotificationsEnabled");
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: () {
                      _changeTtsSettings(context);
                    },
                    child: const Text("Text To Speech Settings"),
                  ),

                  const SizedBox(height: 15),

                  FilledButton(
                    onPressed: () {
                      _changeUserSettings(context);
                    },
                    child: const Text("User Data"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

         
ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 300),
  child: Material(
    color: const Color.fromARGB(255, 31, 44, 61),
    borderRadius: BorderRadius.circular(15),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () {
        _saveScreenSettings(!keepScreenOn);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Keep Screen On",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Prevent screen timeout during races.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Switch(
              value: keepScreenOn,
              onChanged: _saveScreenSettings,
            ),
          ],
        ),
      ),
    ),
  ),
),


            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
