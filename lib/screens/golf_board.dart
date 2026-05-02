import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../state/golf_state.dart';
import 'level_editor.dart';

class GolfBoardScreen extends StatefulWidget {
  const GolfBoardScreen({super.key});

  @override
  State<GolfBoardScreen> createState() => _GolfBoardScreenState();
}

class _GolfBoardScreenState extends State<GolfBoardScreen> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;

  Offset? _dragStart;
  Offset? _dragCurrent;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (_lastTime == Duration.zero) {
        _lastTime = elapsed;
        return;
      }
      double dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
      _lastTime = elapsed;
      if (mounted) {
        context.read<GolfState>().tick(dt);
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<GolfState>(
          builder: (context, state, _) {
            return Text('${state.currentLevel?.name ?? 'Level'} - Strokes: ${state.strokes}');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Open in Editor',
            onPressed: () {
              final state = context.read<GolfState>();
              if (state.currentLevel != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LevelEditorScreen(initialLevel: state.currentLevel!),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart Level',
            onPressed: () {
              final state = context.read<GolfState>();
              if (state.currentLevel != null) {
                state.loadLevel(state.currentLevel!);
              }
            },
          )
        ],
      ),
      body: Consumer<GolfState>(
        builder: (context, state, child) {
          if (state.currentLevel == null || state.playerBall == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 800,
                  height: 800,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(color: const Color(0xFF1B2E1E)),
                      
                      ...state.currentLevel!.walls.map((wall) => Positioned(
                        left: wall.rect.left,
                        top: wall.rect.top,
                        width: wall.rect.width,
                        height: wall.rect.height,
                        child: Container(
                          decoration: BoxDecoration(
                            color: wall.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      )),

                      ...state.currentLevel!.divideBumpers.where((b) => !b.isUsed).map((bumper) {
                        bool divisible = state.playerBall!.value % bumper.divideValue == 0;
                        return Positioned(
                          left: bumper.position.dx - bumper.radius,
                          top: bumper.position.dy - bumper.radius,
                          child: Container(
                            width: bumper.radius * 2,
                            height: bumper.radius * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: divisible ? Colors.redAccent : Colors.grey.withValues(alpha: 0.5),
                              border: Border.all(color: Colors.white24, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.all(bumper.radius * 0.1),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '÷${bumper.divideValue}',
                                  style: TextStyle(
                                    fontSize: bumper.radius * 0.5,
                                    fontWeight: FontWeight.bold,
                                    color: divisible ? Colors.white : Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      ...state.currentLevel!.staticFactors.where((f) => !f.isUsed).map((factor) => Positioned(
                        left: factor.position.dx - factor.radius,
                        top: factor.position.dy - factor.radius,
                        child: Container(
                          width: factor.radius * 2,
                          height: factor.radius * 2,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange,
                          ),
                          alignment: Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.all(factor.radius * 0.1),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'x${factor.value}',
                                style: TextStyle(
                                  fontSize: factor.radius * 0.6,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )),

                      Positioned(
                        left: state.playerBall!.position.dx - state.playerBall!.radius,
                        top: state.playerBall!.position.dy - state.playerBall!.radius,
                        child: Container(
                          width: state.playerBall!.radius * 2,
                          height: state.playerBall!.radius * 2,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                          ),
                          alignment: Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.all(state.playerBall!.radius * 0.1),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${state.playerBall!.value}',
                                style: TextStyle(
                                  fontSize: state.playerBall!.radius * 0.8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (_dragStart != null && _dragCurrent != null)
                        CustomPaint(
                          painter: AimPainter(
                            ballPosition: state.playerBall!.position,
                            dragStart: _dragStart!,
                            dragCurrent: _dragCurrent!,
                          ),
                        ),

                      // Drag Area (Top layer for dragging)
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanStart: (details) {
                          if (state.playerBall!.velocity.distance < 1.0) {
                            setState(() {
                              _dragStart = details.localPosition;
                              _dragCurrent = details.localPosition;
                            });
                          }
                        },
                        onPanUpdate: (details) {
                          if (_dragStart != null) {
                            setState(() {
                              _dragCurrent = details.localPosition;
                            });
                          }
                        },
                        onPanEnd: (details) {
                          if (_dragStart != null && _dragCurrent != null) {
                            Offset dragDelta = _dragCurrent! - _dragStart!;
                            if (dragDelta.distance > 10) {
                              state.launchBall(dragDelta);
                            }
                            setState(() {
                              _dragStart = null;
                              _dragCurrent = null;
                            });
                          }
                        },
                        child: Container(
                          color: Colors.transparent,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),

                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Target: ${state.currentLevel!.targetValue}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),

                      if (state.isCompleted)
                        Container(
                          color: Colors.black87,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Level Complete!', style: TextStyle(fontSize: 32, color: Colors.green, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Text('Strokes: ${state.strokes}', style: const TextStyle(fontSize: 24, color: Colors.white)),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Back to Level Select'),
                                )
                              ],
                            ),
                          ),
                        ),

                      if (state.showRetryPrompt && !state.isCompleted)
                        Positioned(
                          bottom: 50,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("Looks impossible...", style: TextStyle(fontSize: 20, color: Colors.redAccent)),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      state.loadLevel(state.currentLevel!);
                                    },
                                    child: const Text('Retry Level'),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AimPainter extends CustomPainter {
  final Offset ballPosition;
  final Offset dragStart;
  final Offset dragCurrent;

  AimPainter({
    required this.ballPosition,
    required this.dragStart,
    required this.dragCurrent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Offset dragDelta = dragCurrent - dragStart;
    Offset aimEnd = ballPosition - dragDelta * 2.5; 

    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(ballPosition, aimEnd, paint);
    
    if (dragDelta.distance > 0) {
      double angle = (-dragDelta).direction;
      canvas.drawLine(
        aimEnd,
        aimEnd - Offset(cos(angle - pi / 6), sin(angle - pi / 6)) * 15,
        paint,
      );
      canvas.drawLine(
        aimEnd,
        aimEnd - Offset(cos(angle + pi / 6), sin(angle + pi / 6)) * 15,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
