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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Race History")),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (savedRaces.isEmpty) {
      return const Center(
        child: Text("No saved races.", style: TextStyle(fontSize: 18)),
      );
    }

    return ListView.builder(
      itemCount: savedRaces.length,
      itemBuilder: (context, index) {
        final race = savedRaces[index];

        return ListTile(
          title: Text("Race ${index + 1}"),
          subtitle: Text("${race.laps.length} laps"),
          trailing: Text(_formatDate(race.date)),
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
