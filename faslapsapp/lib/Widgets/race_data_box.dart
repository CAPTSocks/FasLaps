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
    final bool hasTitle = title.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: hasTitle ? 14 : 20,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF202020),
            Color(0xFF4D4D4D),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: hasTitle
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}