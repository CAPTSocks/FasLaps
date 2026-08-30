import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_menu_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NameEntryPage extends StatefulWidget {
  const NameEntryPage({super.key});

  @override
  State<NameEntryPage> createState() => _NameEntryPageState();
}

class _NameEntryPageState extends State<NameEntryPage> {
  final TextEditingController firstNameController = TextEditingController();

  final TextEditingController lastNameController = TextEditingController();

  final TextEditingController userPinController = TextEditingController();

  final TextEditingController confirmPinController = TextEditingController();

  Future<void> _continuePressed() async {
    final prefs = await SharedPreferences.getInstance();

    // Save the first and last name to shared preferences
    await prefs.setString('firstName', firstNameController.text);
    await prefs.setString('lastName', lastNameController.text);
    await prefs.setString('pin', userPinController.text);

    // Navigate to the main menu page

    if (userPinController.text != confirmPinController.text) {
      // Show an error message if the PINs do not match
      await _showErrorDialog("PINs do not match. Please try again.");
      return; // Exit the function if PINs do not match
    }

    if (userPinController.text.length != 4 ) {
      // Show an error message if the PIN is not 4 digits
      await _showErrorDialog("PIN must be 4 digits. Please try again.");
      return; // Exit the function if PIN is not valid
    }

    if (firstNameController.text.isEmpty || lastNameController.text.isEmpty || userPinController.text.isEmpty || confirmPinController.text.isEmpty )
    {
      await _showErrorDialog("Please fill out each line.");
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainMenuPage(
          firstName: firstNameController.text,
          lastName: lastNameController.text,
        ),
      ),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      // Duration of the entry animation
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation1, animation2) {
        return AlertDialog(
          title: const Text(
            "Error",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          shape: const RoundedRectangleBorder(
            side: BorderSide(
              color: Colors.red, // Border color
              width: 5.0, // Thickness of the line
            ),
            borderRadius: BorderRadius.all(
              Radius.circular(4.0),
            ), // Matches standard dialog corners
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final double progress = animation.value;

            // Check if the dialog is in the process of closing/exiting
            final bool isExiting = animation.status == AnimationStatus.reverse;

            // If exiting, set shake to 0. Otherwise, calculate the entry shake.
            final double shake = isExiting
                ? 0.0
                : 15 * math.sin(progress * 3 * 2 * math.pi);

            return Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(shake * (1.0 - progress), 0),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
    );
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Welcome")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: "First Name"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: "Last Name"),
            ),

            const SizedBox(height: 30),

            TextField(
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: userPinController,
              decoration: const InputDecoration(
                labelText: "User Pin (4 digits)",
              ),
            ),
            TextField(
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: confirmPinController,
              decoration: const InputDecoration(
                labelText: "Confirm Pin (4 digits)",
              ),
            ),

            const SizedBox(height: 30),

            FilledButton(
              onPressed: _continuePressed,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
