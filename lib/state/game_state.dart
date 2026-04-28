import 'dart:math';
import 'package:flutter/material.dart';
import '../models/circle_model.dart';

enum FactorMode { prime, all, sqrt }

class GameState extends ChangeNotifier {
  List<CircleModel> circles = [];
  Size screenSize = Size.zero;
  FactorMode factorMode = FactorMode.prime;

  int startingNumber = 360;

  void initialize(Size size) {
    if (screenSize == size) return;
    screenSize = size;
    if (circles.isEmpty) reset();
  }

  void setFactorMode(FactorMode mode) {
    factorMode = mode;
    notifyListeners();
  }

  void setStartingNumber(int number) {
    startingNumber = number;
    reset();
  }

  void reset() {
    circles.clear();
    final center = Offset(screenSize.width / 2, screenSize.height / 2);
    circles.add(
      CircleModel(
        id: UniqueKey().toString(),
        value: startingNumber,
        position: center,
        velocity: const Offset(0, 0),
      ),
    );
    notifyListeners();
  }

  void applyForce(CircleModel circle, Offset force) {
    circle.velocity += force;
  }

  void splitCircle(CircleModel source, int factor, Offset newPosition) {
    if (source.value % factor != 0) return;

    source.updateValue(source.value ~/ factor);

    Offset dir = newPosition - source.position;
    double dist = dir.distance;
    Offset vel = dist > 0 ? (dir / dist) * 200 : const Offset(200, 200);

    // Give opposite velocity to source, capped
    Offset recoil = vel * (factor / source.value);
    // if (recoil.distance > 1000) {
    //   recoil = (recoil / recoil.distance) * 1000;
    // }
    source.velocity -= recoil;

    circles.add(
      CircleModel(
        id: UniqueKey().toString(),
        value: factor,
        position: newPosition,
        velocity: vel,
      ),
    );
    notifyListeners();
  }

  void tick(double dt) {
    if (circles.isEmpty || screenSize == Size.zero) return;

    bool changed = false;

    const double friction = 0.95;
    const double maxVelocity = 3000.0;
    for (var circle in circles) {
      if (circle.velocity.distance > maxVelocity) {
        circle.velocity =
            (circle.velocity / circle.velocity.distance) * maxVelocity;
      }

      if (circle.velocity.distance > 0.5) {
        circle.position += circle.velocity * dt;
        circle.velocity *= pow(friction, dt * 60.0).toDouble();
        changed = true;
      } else if (circle.velocity.distance > 0) {
        circle.velocity = Offset.zero;
        changed = true;
      }

      // Boundaries
      if (circle.position.dx - circle.radius < 0) {
        circle.position = Offset(circle.radius, circle.position.dy);
        circle.velocity = Offset(-circle.velocity.dx, circle.velocity.dy);
      } else if (circle.position.dx + circle.radius > screenSize.width) {
        circle.position = Offset(
          screenSize.width - circle.radius,
          circle.position.dy,
        );
        circle.velocity = Offset(-circle.velocity.dx, circle.velocity.dy);
      }

      if (circle.position.dy - circle.radius < 0) {
        circle.position = Offset(circle.position.dx, circle.radius);
        circle.velocity = Offset(circle.velocity.dx, -circle.velocity.dy);
      } else if (circle.position.dy + circle.radius > screenSize.height) {
        circle.position = Offset(
          circle.position.dx,
          screenSize.height - circle.radius,
        );
        circle.velocity = Offset(circle.velocity.dx, -circle.velocity.dy);
      }
    }

    // Collisions
    List<CircleModel> toRemove = [];
    List<CircleModel> toAdd = [];

    for (int i = 0; i < circles.length; i++) {
      if (toRemove.contains(circles[i])) continue;
      for (int j = i + 1; j < circles.length; j++) {
        if (toRemove.contains(circles[j])) continue;

        var c1 = circles[i];
        var c2 = circles[j];

        var dist = (c1.position - c2.position).distance;
        if (dist < c1.radius + c2.radius) {
          int newValue = c1.value * c2.value;
          double m1 = c1.value.toDouble();
          double m2 = c2.value.toDouble();
          Offset newVel = (c1.velocity * m1 + c2.velocity * m2) / (m1 + m2);
          Offset newPos = (c1.position + c2.position) / 2;

          var newCircle = CircleModel(
            id: UniqueKey().toString(),
            value: newValue,
            position: newPos,
            velocity: newVel,
          );

          toRemove.add(c1);
          toRemove.add(c2);
          toAdd.add(newCircle);
          changed = true;
          break;
        }
      }
    }

    if (toRemove.isNotEmpty) {
      circles.removeWhere((c) => toRemove.contains(c));
      circles.addAll(toAdd);
    }

    if (changed) {
      notifyListeners();
    }
  }
}
