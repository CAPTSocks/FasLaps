import 'package:flutter/material.dart';

class RaceDataBox extends StatelessWidget {
  final String title;
  final String value;

  const RaceDataBox({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasTitle = title.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: hasTitle ? 14 : 8,
        horizontal: 8,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 48, 56, 66), Color.fromARGB(255, 31, 44, 61)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: hasTitle
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Center(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}
