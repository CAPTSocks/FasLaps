import 'package:flutter/material.dart';

import '../saved_race.dart';
import '../services/race_history_service.dart';
import 'race_details_page.dart';

class RaceHistoryPage extends StatefulWidget {
  const RaceHistoryPage({super.key});

  @override
  State<RaceHistoryPage> createState() => _RaceHistoryPageState();
}

class _RaceHistoryPageState extends State<RaceHistoryPage> {
  List<SavedRace> savedRaces = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRaces();
  }

  Future<void> _loadRaces() async {
    final races = await RaceHistoryService.loadRaces();

    if (!mounted) return;

    setState(() {
      savedRaces = races;
      isLoading = false;
    });
  }

  Future<void> _deleteRace(SavedRace race) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Race?"),
          content: Text(
            "Are you sure you want to delete ${race.raceName}?\n\n"
            "This will permanently delete this race and its ${race.laps.length} saved laps.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await RaceHistoryService.deleteRace(race.raceId);

    if (!mounted) return;

    setState(() {
      savedRaces.removeWhere(
        (savedRace) => savedRace.raceId == race.raceId,
      );
    });
  }

  Future<void> _clearRaceHistory() async {
    if (savedRaces.isEmpty) return;

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Clear Race History?"),
          content: Text(
            "Are you sure you want to delete all ${savedRaces.length} "
            "saved races?\n\nThis cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text("Clear History"),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    await RaceHistoryService.clearRaces();

    if (!mounted) return;

    setState(() {
      savedRaces.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Race History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Clear Race History",
            onPressed: savedRaces.isEmpty ? null : _clearRaceHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (savedRaces.isEmpty) {
      return const Center(
        child: Text(
          "No saved races.",
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: savedRaces.length,
      itemBuilder: (context, index) {
        final race = savedRaces[index];

        return ListTile(
          title: Text(
            race.raceName.isEmpty
                ? "Race ${index + 1}"
                : race.raceName,
          ),
          subtitle: Text("${race.laps.length} laps"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_formatDate(race.raceDate)),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: "Delete Race",
                onPressed: () => _deleteRace(race),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RaceDetailsPage(race: race),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
