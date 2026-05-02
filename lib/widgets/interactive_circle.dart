import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/circle_model.dart';
import '../state/game_state.dart';
import '../utils/math_utils.dart';

class FactorDragData {
  final CircleModel source;
  final int factor;

  FactorDragData(this.source, this.factor);
}

class InteractiveCircle extends StatefulWidget {
  final CircleModel circle;

  const InteractiveCircle({super.key, required this.circle});

  @override
  State<InteractiveCircle> createState() => _InteractiveCircleState();
}

class _InteractiveCircleState extends State<InteractiveCircle> {
  List<int> _getFactors(FactorMode mode) {
    int val = widget.circle.value;
    if (widget.circle.isPrime || val <= 1) return [];

    List<int> result;
    switch (mode) {
      case FactorMode.prime:
        result = MathUtils.getPrimeFactors(val);
        break;
      case FactorMode.sqrt:
        result = MathUtils.getAllFactors(
          val,
        ).where((f) => f <= sqrt(val)).toList();
        break;
      case FactorMode.all:
        var all = MathUtils.getAllFactors(val);
        if (all.length > 8) {
          int seed = (DateTime.now().millisecondsSinceEpoch ~/ 2000);
          all.shuffle(Random(seed));
          result = all.take(8).toList();
        } else {
          result = all;
        }
        break;
    }

    // Ensure duplicate factors aren't shown at the same time
    return result.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    Color baseColor = widget.circle.isPrime
        ? Colors.orangeAccent
        : Colors.lightBlueAccent;

    return GestureDetector(
      onPanUpdate: (details) {
        context.read<GameState>().applyForce(widget.circle, details.delta * 8);
      },
      child: Container(
        width: widget.circle.radius * 2,
        height: widget.circle.radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              baseColor.withValues(alpha: 0.9),
              baseColor.withValues(alpha: 0.6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(widget.circle.radius * 0.15),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${widget.circle.value}',
                  style: TextStyle(
                    fontSize: widget.circle.radius * 0.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black45,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ..._buildFactors(gameState.factorMode),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFactors(FactorMode mode) {
    List<int> factors = _getFactors(mode);
    if (factors.isEmpty) return [];

    List<Widget> factorWidgets = [];
    double angleStep = 2 * pi / factors.length;

    double estimatedFactorRadius = max(18.0, widget.circle.radius * 0.25 + 4);
    double orbitRadius = max(
      0.0,
      widget.circle.radius - estimatedFactorRadius - 8,
    );

    for (int i = 0; i < factors.length; i++) {
      double angle = i * angleStep;
      double dx = cos(angle) * orbitRadius;
      double dy = sin(angle) * orbitRadius;

      factorWidgets.add(
        Transform.translate(
          offset: Offset(dx, dy),
          child: Draggable<FactorDragData>(
            data: FactorDragData(widget.circle, factors[i]),
            feedback: _buildFactorFeedback(factors[i]),
            childWhenDragging: Opacity(
              opacity: 0.1,
              child: _buildFactorWidget(factors[i]),
            ),
            child: _buildFactorWidget(factors[i]),
          ),
        ),
      );
    }
    return factorWidgets;
  }

  Widget _buildFactorWidget(int factor) {
    double fontSize = min(22.0, widget.circle.radius * 0.25);
    double maxSize = widget.circle.radius * 0.6;
    return Container(
      padding: const EdgeInsets.all(8),
      constraints: BoxConstraints(maxWidth: maxSize, maxHeight: maxSize),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.35),
      ),
      child: Text(
        '$factor',
        style: TextStyle(
          fontSize: max(14.0, fontSize),
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFactorFeedback(int factor) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.9),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: Text(
          '$factor',
          style: const TextStyle(
            fontSize: 24,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
