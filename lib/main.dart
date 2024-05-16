import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:logging/logging.dart';
import 'zombie_game.dart';

Future<void> main() async {
  Logger.root.level = Level.WARNING; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(
      '[${record.loggerName}][${record.level.name}]: '
      '${record.time.minute.toString().padLeft(2, '0')}:'
      '${record.time.second.toString().padLeft(2, '0')}.'
      '${record.time.millisecond.toString().padLeft(3, '0')} '
      '${record.message}',
    );
  });
  WidgetsFlutterBinding.ensureInitialized();
  final game = ZombieGame();
  runApp(MyApp(game: game));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.game});

  final ZombieGame game;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: GameWidget(game: game),
    );
  }
}
