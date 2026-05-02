import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/levels.dart';
import '../state/golf_state.dart';
import '../models/level_model.dart';
import '../models/level_serialization.dart';
import 'golf_board.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  List<LevelModel> customLevels = [];

  @override
  void initState() {
    super.initState();
    _loadCustomLevels();
  }

  Future<void> _loadCustomLevels() async {
    try {
      final file = File('custom_levels.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> jsonList = jsonDecode(content);
          setState(() {
            customLevels = jsonList.map((json) => LevelModelSerialization.fromJson(json)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Load failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Factor Golf - Select Level')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final levels = [...Levels.getAllLevels(), ...customLevels];
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: levels.length,
            itemBuilder: (context, index) {
              final level = levels[index];
              return Card(
                child: ListTile(
                  title: Text(level.name),
                  subtitle: Text('Start: ${level.startValue}  |  Target: ${level.targetValue}'),
                  trailing: const Icon(Icons.sports_golf),
                  onTap: () {
                    context.read<GolfState>().initialize();
                    context.read<GolfState>().loadLevel(level);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GolfBoardScreen()),
                    );
                  },
                ),
              );
            },
          );
        }
      ),
    );
  }
}
