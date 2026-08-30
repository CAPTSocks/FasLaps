import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'name_entry_page.dart';
import 'main_menu_page.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}



class _StartupPageState extends State<StartupPage> {

@override
Widget build(BuildContext context) {

  return const Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );

}

  @override
  void initState() {
    super.initState();
    _checkStoredNames();
  }

  Future<void> _checkStoredNames() async {
    final prefs = await SharedPreferences.getInstance();

    String? storedFirstName = prefs.getString('firstName') ?? '';
    String? storedLastName = prefs.getString('lastName') ?? '';

    if (storedFirstName.isNotEmpty && storedLastName.isNotEmpty) {
      // Navigate to MainMenuPage if names are found
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainMenuPage(
            firstName: storedFirstName,
            lastName: storedLastName,
          ),
        ),
      );
    } else {
      // Navigate to NameEntryPage if names are not found
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const NameEntryPage(),
        ),
      );
    }
  }

}