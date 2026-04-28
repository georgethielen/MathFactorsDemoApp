import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/game_state.dart';
import 'screens/game_board.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameState(),
      child: const MathFactorsApp(),
    ),
  );
}

class MathFactorsApp extends StatelessWidget {
  const MathFactorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Factors Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  void _showSettings(BuildContext context) {
    final gameState = context.read<GameState>();
    final controller = TextEditingController(
      text: gameState.startingNumber.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Starting Number'),
            ),
            const SizedBox(height: 10),
            const Text('Factor Display Mode', style: TextStyle(fontSize: 12)),
            DropdownButton<FactorMode>(
              value: gameState.factorMode,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: FactorMode.prime,
                  child: Text('Show prime factors'),
                ),
                DropdownMenuItem(
                  value: FactorMode.all,
                  child: Text('Show up to 8 factors (random)'),
                ),
                DropdownMenuItem(
                  value: FactorMode.sqrt,
                  child: Text('Only show small factors'),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  gameState.setFactorMode(mode);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              int? newNum = int.tryParse(controller.text);
              if (newNum != null && newNum > 0) {
                gameState.setStartingNumber(newNum);
              }
              Navigator.pop(context);
            },
            child: const Text('Apply & Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Factors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<GameState>().reset(),
          ),
        ],
      ),
      body: const GameBoard(),
    );
  }
}
