import 'package:flutter/material.dart';

import '../saved_race.dart';
import '../services/race_history_service.dart';
import 'race_details_page.dart';

class PracticeRaceHistoryPage extends StatefulWidget {
  const PracticeRaceHistoryPage({super.key});

  @override
  State<PracticeRaceHistoryPage> createState() => _PracticeRaceHistoryPageState();
}

class _PracticeRaceHistoryPageState extends State<PracticeRaceHistoryPage> {
  List<SavedRace> savedRaces = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRaces();
  }

  Future<void> _loadRaces() async {
    final races = await RaceHistoryService.loadRaces(raceType: 'practice');

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
          title: const Text("Delete Practice?"),
          content: Text(
            "Are you sure you want to delete ${race.raceName}?\n\n"
            "This will permanently delete this race and its "
            "${race.laps.length} saved laps.",
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
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
      savedRaces.removeWhere((savedRace) => savedRace.raceId == race.raceId);
    });
  }

  Future<void> _clearRaceHistory() async {
    if (savedRaces.isEmpty) return;

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Clear Practice History?"),
          content: Text(
            "Are you sure you want to delete all "
            "${savedRaces.length} saved practices?\n\n"
            "This cannot be undone.",
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Clear History"),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    // We will change this later so it only clears regular races.
    await RaceHistoryService.clearRaces(raceType: "practice");

    if (!mounted) return;

    setState(() {
      savedRaces.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Practice History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Clear Practice History",
            onPressed: savedRaces.isEmpty ? null : _clearRaceHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (savedRaces.isEmpty) {
      return const Center(
        child: Text("No saved practices.", style: TextStyle(fontSize: 18)),
      );
    }

    return ListView.builder(
      itemCount: savedRaces.length,
      itemBuilder: (context, index) {
        final race = savedRaces[index];

        return ListTile(
          title: Text(
            race.raceName.isEmpty ? "Race ${index + 1}" : race.raceName,
          ),
          subtitle: Text("${race.laps.length} laps"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_formatDate(race.raceDate)),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: "Delete Practice",
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
