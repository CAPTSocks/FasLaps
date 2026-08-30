import 'dart:async';

import 'package:flutter/material.dart';
import 'package:faslapsapp/race_data.dart';
import 'package:faslapsapp/services/race_connection_service.dart';
import 'package:faslapsapp/services/background_race_service.dart';

class ConnectionPage extends StatefulWidget {
  final String serverAddress;

  const ConnectionPage({
    super.key,
    required this.serverAddress,
  });

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final RaceConnectionService raceService =
      RaceConnectionService.instance;

  final List<RaceData> raceHistory = [];

  late StreamSubscription<List<RaceData>>
      raceHistorySubscription;

  late StreamSubscription<ConnectionStatus>
      statusSubscription;

  String status = "Connecting...";

  @override
  void initState() {
    super.initState();

    raceHistory.addAll(raceService.raceHistory);

    raceHistorySubscription =
        raceService.raceHistoryStream.listen(
      (history) {
        if (!mounted) return;

        setState(() {
          raceHistory
            ..clear()
            ..addAll(history);
        });
      },
    );

    statusSubscription =
        raceService.statusStream.listen(
      (connectionStatus) {
        if (!mounted) return;

        setState(() {
          switch (connectionStatus) {
            case ConnectionStatus.connected:
              status = "Connected";
              break;

            case ConnectionStatus.disconnected:
              status = "Disconnected";
              break;

            case ConnectionStatus.connectionError:
              status = "Connection Error";
              break;
          }
        });
      },
    );

    _startRace();
  }

  Future<void> _startRace() async {
    
    await BackgroundRaceService.requestPermissions();
    await BackgroundRaceService.start();

    await raceService.connect(
      widget.serverAddress,
    );
  }

  // Future<void> _connect() async {
  //   await raceService.connect(
  //     widget.serverAddress,
  //   );
  // }

  @override
  void dispose() {
    raceHistorySubscription.cancel();
    statusSubscription.cancel();

    // Do NOT disconnect the race service here.
    // We eventually want it to continue running
    // when the page is no longer visible.

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Race Monitor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: "Stop Race",
            onPressed: () async {
              await raceService.disconnect();

              await BackgroundRaceService.stop();

              if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              status,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: status == 'Connected'
                        ? Colors.green
                        : Colors.red,
                  ),
            ),

            const SizedBox(height: 20),

            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      "Lap",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Lap Time",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Best Lap",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Position",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: raceHistory.length,
                itemBuilder: (context, index) {
                  final lap = raceHistory[index];

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(
                          vertical: 3,
                        ),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${lap.lapNumber}",
                              textAlign:
                                  TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              lap.lapTimeSeconds
                                  .toStringAsFixed(3),
                              textAlign:
                                  TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              lap.bestLapTimeSeconds
                                  .toStringAsFixed(3),
                              textAlign:
                                  TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "${lap.racePosition}",
                              textAlign:
                                  TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}