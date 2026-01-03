import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiParticle {
  late double x, y, size, speed, angle, spin;
  late Color color;
  ConfettiParticle() {
    final r = Random();
    x = r.nextDouble(); y = -0.1; size = r.nextDouble() * 10 + 5; speed = r.nextDouble() * 0.02 + 0.01; angle = r.nextDouble() * 2 * pi; spin = r.nextDouble() * 0.2 - 0.1;
    color = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.pink][r.nextInt(6)];
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double anim;
  ConfettiPainter(this.particles, this.anim);
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      p.y += p.speed + 0.01 * anim; p.angle += p.spin;
      final paint = Paint()..color = p.color.withOpacity(1.0 - anim);
      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.angle);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6), paint);
      canvas.restore();
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}