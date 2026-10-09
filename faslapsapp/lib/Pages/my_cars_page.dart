import 'package:flutter/material.dart';

class SavedSlotCarsPage extends StatelessWidget {
  const SavedSlotCarsPage({super.key});

  static const _cars = [
    _SlotCar(name: 'Porsche 917', scale: '1:32', lane: 'Red', notes: 'Main race car'),
    _SlotCar(name: 'Ford GT40', scale: '1:32', lane: 'Blue', notes: 'Backup'),
    _SlotCar(name: 'Ferrari 312', scale: '1:24', lane: 'Yellow', notes: 'Needs new braids'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Slot Cars'),
      ),
      body: _cars.isEmpty
          ? const Center(child: Text('No saved slot cars yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _cars.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final car = _cars[index];
                return Card(
                  child: ListTile(
                    title: Text(car.name),
                    subtitle: Text('${car.scale} · Lane ${car.lane}\n${car.notes}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Temporary: open detail later.
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _SlotCar {
  const _SlotCar({
    required this.name,
    required this.scale,
    required this.lane,
    required this.notes,
  });

  final String name;
  final String scale;
  final String lane;
  final String notes;
}