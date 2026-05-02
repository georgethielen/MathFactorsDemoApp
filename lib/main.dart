import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/game_state.dart';
import 'state/golf_state.dart';
import 'screens/game_board.dart';
import 'screens/level_select.dart';
import 'screens/level_editor.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GameState()),
        ChangeNotifierProvider(create: (context) => GolfState()),
      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Factors'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select Game Mode',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SandboxScreen()),
                );
              },
              child: const Text('Sandbox Mode'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LevelSelectScreen()),
                );
              },
              child: const Text('Factor Golf Mode'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LevelEditorScreen()),
                );
              },
              child: const Text('Level Editor'),
            ),
          ],
        ),
      ),
    );
  }
}

class SandboxScreen extends StatelessWidget {
  const SandboxScreen({super.key});

  void _showSettings(BuildContext context) {
    final gameState = context.read<GameState>();
    final controller = TextEditingController(text: gameState.startingNumber.toString());

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
                DropdownMenuItem(value: FactorMode.prime, child: Text('Prime Factors')),
                DropdownMenuItem(value: FactorMode.all, child: Text('All Factors (max 8)')),
                DropdownMenuItem(value: FactorMode.sqrt, child: Text('Factors <= sqrt(N)')),
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
        title: const Text('Sandbox'),
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
