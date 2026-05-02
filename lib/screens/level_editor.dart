import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/level_editor_state.dart';
import '../state/golf_state.dart';
import 'golf_board.dart';
import 'package:flutter/services.dart';

class LevelEditorScreen extends StatelessWidget {
  const LevelEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LevelEditorState(),
      child: const _LevelEditorView(),
    );
  }
}

class _LevelEditorView extends StatelessWidget {
  const _LevelEditorView();

  Future<int?> _showNumberDialog(BuildContext context, String title) async {
    int? result;
    await showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                result = int.tryParse(controller.text);
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            )
          ],
        );
      }
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LevelEditorState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Level Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Level Settings',
            onPressed: () async {
               int? newStart = await _showNumberDialog(context, 'Start Value');
               if (newStart != null) state.startValue = newStart;
               int? newTarget = await _showNumberDialog(context, 'Target Value');
               if (newTarget != null) state.targetValue = newTarget;
               state.forceUpdate(); 
            },
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Test Level',
            onPressed: () {
              final level = state.buildLevel();
              context.read<GolfState>().initialize();
              context.read<GolfState>().loadLevel(level);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GolfBoardScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Local',
            onPressed: () async {
              await state.saveLocal();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to custom_levels.json')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Export JSON',
            onPressed: () {
              final jsonStr = state.exportJson();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Export JSON'),
                  content: SelectableText(jsonStr),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: jsonStr));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                      },
                      child: const Text('Copy'),
                    ),
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear',
            onPressed: () => state.clear(),
          )
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 100,
            color: Colors.black26,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Tools', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                _ToolButton(
                  icon: Icons.person,
                  label: 'Player',
                  isSelected: state.currentTool == EditorTool.player,
                  onTap: () => state.setTool(EditorTool.player),
                ),
                _ToolButton(
                  icon: Icons.close,
                  label: 'Factor',
                  isSelected: state.currentTool == EditorTool.staticFactor,
                  onTap: () => state.setTool(EditorTool.staticFactor),
                ),
                _ToolButton(
                  icon: Icons.horizontal_rule,
                  label: 'Divide',
                  isSelected: state.currentTool == EditorTool.divideBumper,
                  onTap: () => state.setTool(EditorTool.divideBumper),
                ),
                _ToolButton(
                  icon: Icons.crop_square,
                  label: 'Wall',
                  isSelected: state.currentTool == EditorTool.wall,
                  onTap: () => state.setTool(EditorTool.wall),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Container(
                    width: 800,
                    height: 800,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2E1E),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: GestureDetector(
                      onPanStart: (d) => state.handlePanStart(d.localPosition),
                      onPanUpdate: (d) => state.handlePanUpdate(d.localPosition),
                      onPanEnd: (d) => state.handlePanEnd(),
                      onTapUp: (d) async {
                        final pos = d.localPosition;
                        if (state.currentTool == EditorTool.player) {
                          state.handleTap(pos);
                        } else if (state.currentTool == EditorTool.staticFactor) {
                          int? val = await _showNumberDialog(context, 'Factor Value');
                          if (val != null) state.addStaticFactor(pos, val);
                        } else if (state.currentTool == EditorTool.divideBumper) {
                          int? val = await _showNumberDialog(context, 'Divide Value');
                          if (val != null) state.addDivideBumper(pos, val);
                        }
                      },
                      child: CustomPaint(
                        painter: EditorGridPainter(state),
                        size: const Size(800, 800),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? Colors.deepPurple.withValues(alpha: 0.5) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white54),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class EditorGridPainter extends CustomPainter {
  final LevelEditorState state;

  EditorGridPainter(this.state) : super(repaint: state);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke;

    double step = 40.0;
    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    final wallPaint = Paint()..color = Colors.blueGrey;
    for (var w in state.walls) {
      canvas.drawRect(w.rect, wallPaint);
    }

    if (state.dragStart != null && state.dragCurrent != null) {
      canvas.drawRect(Rect.fromPoints(state.dragStart!, state.dragCurrent!), Paint()..color = Colors.blueGrey.withValues(alpha: 0.5));
    }

    final playerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(state.startPosition, 20, playerPaint);
    _drawText(canvas, '${state.startValue}', state.startPosition, 20, Colors.black);

    final factorPaint = Paint()..color = Colors.orange;
    for (var f in state.staticFactors) {
      canvas.drawCircle(f.position, f.radius, factorPaint);
      _drawText(canvas, 'x${f.value}', f.position, f.radius, Colors.white);
    }

    final bumperPaint = Paint()..color = Colors.grey.withValues(alpha: 0.5);
    final borderPaint = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 2;
    for (var b in state.divideBumpers) {
      canvas.drawCircle(b.position, b.radius, bumperPaint);
      canvas.drawCircle(b.position, b.radius, borderPaint);
      _drawText(canvas, '÷${b.divideValue}', b.position, b.radius, Colors.white54);
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, double radius, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: radius * 0.8, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant EditorGridPainter oldDelegate) => true;
}
