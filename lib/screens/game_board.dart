import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../state/game_state.dart';
import '../widgets/interactive_circle.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;

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
        context.read<GameState>().tick(dt);
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<GameState>().initialize(size);
          }
        });

        return DragTarget<FactorDragData>(
          onAcceptWithDetails: (details) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final Offset localOffset = renderBox.globalToLocal(details.offset);
            
            context.read<GameState>().splitCircle(
              details.data.source,
              details.data.factor,
              localOffset,
            );
          },
          builder: (context, candidateData, rejectedData) {
            return Consumer<GameState>(
              builder: (context, gameState, child) {
                return Stack(
                  children: [
                    Container(
                      color: const Color(0xFF1E1E2C), // Modern dark background
                    ),
                    ...gameState.circles.map((circle) {
                      return Positioned(
                        key: ValueKey(circle.id),
                        left: circle.position.dx - circle.radius,
                        top: circle.position.dy - circle.radius,
                        child: InteractiveCircle(circle: circle),
                      );
                    }),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
