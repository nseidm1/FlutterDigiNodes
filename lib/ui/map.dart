import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class MapItem {
  const MapItem(this.lat, this.lng, this.color);

  final double lat;
  final double lng;
  final Color color;

  math.Point<double> mercator() {
    final sinLatitude = math.sin(this.lat * math.pi / 180);
    final x = (this.lng + 180.0) / 360.0;
    final y = (0.5 - math.log((1.0 + sinLatitude) / (1.0 - sinLatitude)) / (4 * math.pi));
    return math.Point<double>(x, y);
  }

  factory MapItem.fromJson(Map<String, dynamic> json) {
    return MapItem(json['latitude'], json['longitude'], Colors.blue);
  }
}

class MapWidget extends StatelessWidget {
  const MapWidget({
    Key key,
    this.items,
  }) : super(key: key);

  final List<MapItem> items;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1024.0 / 1024.0,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(
                'assets/world.png',
                fit: BoxFit.fill,
                //color: Colors.black54,
                //colorBlendMode: BlendMode.srcOver,
              ),
              CustomPaint(
                painter: _MapItemPainter(
                  items: items,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapItemPainter extends CustomPainter {
  final List<MapItem> items;

  _MapItemPainter({
    @required this.items,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in items) {
      final pos = item.mercator();
      canvas.drawCircle(
        Offset(pos.x * size.width, pos.y * size.height),
        2.0,
        Paint()..color = item.color,
      );
    }
  }

  @override
  bool shouldRepaint(_MapItemPainter old) => ListEquality().equals(this.items, old.items);
}
