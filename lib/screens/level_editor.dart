import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/level_editor_state.dart';
import '../state/golf_state.dart';
import '../models/level_model.dart';
import 'golf_board.dart';

class LevelEditorScreen extends StatelessWidget {
  final LevelModel? initialLevel;
  const LevelEditorScreen({super.key, this.initialLevel});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final state = LevelEditorState();
        if (initialLevel != null) {
          state.loadFromLevel(initialLevel!);
        }
        return state;
      },
      child: const _LevelEditorView(),
    );
  }
}

class _LevelEditorView extends StatefulWidget {
  const _LevelEditorView();

  @override
  State<_LevelEditorView> createState() => _LevelEditorViewState();
}

class _LevelEditorViewState extends State<_LevelEditorView> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<int?> _showNumberDialog(
    BuildContext context,
    String title, {
    bool positiveOnly = true,
    int? initial,
  }) async {
    int? result;
    await showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(
          text: initial?.toString() ?? '',
        );
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            onSubmitted: (_) {
              int? parsed = int.tryParse(controller.text);
              if (parsed != null && positiveOnly && parsed <= 0) return;
              result = parsed;
              Navigator.pop(ctx);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                int? parsed = int.tryParse(controller.text);
                if (parsed != null && positiveOnly && parsed <= 0) return;
                result = parsed;
                Navigator.pop(ctx);
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
    return result;
  }

  Future<String?> _showStringDialog(BuildContext context, String title, {String? initial}) async {
    String? result;
    await showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: initial ?? '');
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            onSubmitted: (_) {
              result = controller.text.isNotEmpty ? controller.text : null;
              Navigator.pop(ctx);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                result = controller.text.isNotEmpty ? controller.text : null;
                Navigator.pop(ctx);
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
    return result;
  }

  Future<Map<String, int>?> _showFactorDialog(
    BuildContext context,
    String title,
  ) async {
    int? valResult;
    int? radResult;
    await showDialog(
      context: context,
      builder: (ctx) {
        final valController = TextEditingController();
        final radController = TextEditingController(text: '40');
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Value (e.g. 2, 3)',
                ),
                autofocus: true,
              ),
              TextField(
                controller: radController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Radius (e.g. 30, 40)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                int? v = int.tryParse(valController.text);
                int? r = int.tryParse(radController.text);
                if (v != null && v > 0 && r != null && r > 0) {
                  valResult = v;
                  radResult = r;
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (valResult != null && radResult != null)
      return {'value': valResult!, 'radius': radResult!};
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LevelEditorState>();

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.delete) {
          state.deleteSelected();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Level Editor'),
          actions: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Test Level',
              onPressed: () {
                final level = state.buildLevel();
                context.read<GolfState>().initialize();
                context.read<GolfState>().loadLevel(level);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GolfBoardScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Local',
              onPressed: () async {
                await state.saveLocal();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saved to custom_levels.json'),
                    ),
                  );
                }
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                            ),
                          );
                        },
                        child: const Text('Copy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear All',
              onPressed: () => state.clear(),
            ),
          ],
        ),
        body: Row(
          children: [
            // ── Left sidebar ──
            Container(
              width: 130,
              color: Colors.black26,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Tools',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _ToolButton(
                    icon: Icons.mouse,
                    label: 'Select',
                    isSelected: state.currentTool == EditorTool.select,
                    onTap: () => state.setTool(EditorTool.select),
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

                  const Divider(color: Colors.white24),

                  // ── Selection info ──
                  if (state.selection != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        'Selected: ${_selectionLabel(state)}',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 36),
                        ),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text(
                          'Delete',
                          style: TextStyle(fontSize: 13),
                        ),
                        onPressed: state.selection?.type == SelectedType.player
                            ? null
                            : () => state.deleteSelected(),
                      ),
                    ),
                    // Removed "or press delete key" tool text.
                  ],

                  const Spacer(),

                  // ── Level settings ──
                  const Divider(color: Colors.white24),
                  const Text(
                    'Level Name',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  GestureDetector(
                    onTap: () async {
                      String? name = await _showStringDialog(
                        context,
                        'Level Name',
                        initial: state.levelName,
                      );
                      if (name != null) {
                        state.levelName = name;
                        state.forceUpdate();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              state.levelName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit,
                            size: 14,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Start Value',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  GestureDetector(
                    onTap: () async {
                      int? val = await _showNumberDialog(
                        context,
                        'Start Value',
                        initial: state.startValue,
                      );
                      if (val != null) {
                        state.startValue = val;
                        state.forceUpdate();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${state.startValue}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.edit,
                            size: 14,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Target Value',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  GestureDetector(
                    onTap: () async {
                      int? val = await _showNumberDialog(
                        context,
                        'Target Value',
                        initial: state.targetValue,
                      );
                      if (val != null) {
                        state.targetValue = val;
                        state.forceUpdate();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${state.targetValue}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.edit,
                            size: 14,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Canvas ──
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
                        onPanStart: (d) =>
                            state.handlePanStart(d.localPosition),
                        onPanUpdate: (d) =>
                            state.handlePanUpdate(d.localPosition),
                        onPanEnd: (d) => state.handlePanEnd(),
                        onTapUp: (d) async {
                          final pos = d.localPosition;
                          if (state.currentTool == EditorTool.select) {
                            state.handleTap(pos);
                          } else if (state.currentTool ==
                              EditorTool.staticFactor) {
                            var res = await _showFactorDialog(
                              context,
                              'Static Factor',
                            );
                            if (res != null)
                              state.addStaticFactor(
                                pos,
                                res['value']!,
                                res['radius']!.toDouble(),
                              );
                          } else if (state.currentTool ==
                              EditorTool.divideBumper) {
                            var res = await _showFactorDialog(
                              context,
                              'Divide Bumper',
                            );
                            if (res != null)
                              state.addDivideBumper(
                                pos,
                                res['value']!,
                                res['radius']!.toDouble(),
                              );
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
      ),
    );
  }

  String _selectionLabel(LevelEditorState state) {
    if (state.selection == null) return '';
    switch (state.selection!.type) {
      case SelectedType.player:
        return 'Player';
      case SelectedType.wall:
        return 'Wall';
      case SelectedType.staticFactor:
        return 'Factor x${state.staticFactors[state.selection!.index].value}';
      case SelectedType.divideBumper:
        return 'Bumper ÷${state.divideBumpers[state.selection!.index].divideValue}';
    }
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
        color: isSelected
            ? Colors.deepPurple.withValues(alpha: 0.5)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 14),
        width: double.infinity,
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white54),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Canvas painter — draws grid, elements, selection handles
// ──────────────────────────────────────────────────────────────

class EditorGridPainter extends CustomPainter {
  final LevelEditorState state;

  EditorGridPainter(this.state) : super(repaint: state);

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final gridPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke;

    double step = 40.0;
    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Walls
    final wallPaint = Paint()..color = Colors.blueGrey;
    for (int i = 0; i < state.walls.length; i++) {
      canvas.drawRect(state.walls[i].rect, wallPaint);
    }

    // Wall drag preview
    if (state.wallDragStart != null && state.wallDragCurrent != null) {
      canvas.drawRect(
        Rect.fromPoints(state.wallDragStart!, state.wallDragCurrent!),
        Paint()..color = Colors.blueGrey.withValues(alpha: 0.5),
      );
    }

    // Player
    final playerPaint = Paint()..color = Colors.white;
    double pRadius = state.playerRadius;
    canvas.drawCircle(state.startPosition, pRadius, playerPaint);
    _drawText(
      canvas,
      '${state.startValue}',
      state.startPosition,
      pRadius,
      Colors.black,
    );

    // Static factors
    final factorPaint = Paint()..color = Colors.orange;
    for (var f in state.staticFactors) {
      canvas.drawCircle(f.position, f.radius, factorPaint);
      _drawText(canvas, 'x${f.value}', f.position, f.radius, Colors.white);
    }

    // Divide bumpers
    final bumperPaint = Paint()..color = Colors.grey.withValues(alpha: 0.5);
    final borderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var b in state.divideBumpers) {
      canvas.drawCircle(b.position, b.radius, bumperPaint);
      canvas.drawCircle(b.position, b.radius, borderPaint);
      _drawText(
        canvas,
        '÷${b.divideValue}',
        b.position,
        b.radius,
        Colors.white54,
      );
    }

    // Selection highlight + handles
    if (state.selection != null) {
      _drawSelectionHandles(canvas, state.selection!);
    }
  }

  void _drawSelectionHandles(Canvas canvas, SelectedElement sel) {
    Rect bounds;
    switch (sel.type) {
      case SelectedType.player:
        double r = state.playerRadius;
        bounds = Rect.fromCenter(
          center: state.startPosition,
          width: r * 2,
          height: r * 2,
        );
      case SelectedType.wall:
        bounds = state.walls[sel.index].rect;
      case SelectedType.staticFactor:
        final f = state.staticFactors[sel.index];
        bounds = Rect.fromCenter(
          center: f.position,
          width: f.radius * 2,
          height: f.radius * 2,
        );
      case SelectedType.divideBumper:
        final b = state.divideBumpers[sel.index];
        bounds = Rect.fromCenter(
          center: b.position,
          width: b.radius * 2,
          height: b.radius * 2,
        );
    }

    // Dashed-style selection border
    final selPaint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(bounds.inflate(4), selPaint);

    // Corner handles
    const double hs = LevelEditorState.handleSize;
    final handlePaint = Paint()..color = Colors.amberAccent;
    for (final corner in [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ]) {
      canvas.drawRect(
        Rect.fromCenter(center: corner, width: hs, height: hs),
        handlePaint,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos,
    double radius,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      pos - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant EditorGridPainter oldDelegate) => true;
}
