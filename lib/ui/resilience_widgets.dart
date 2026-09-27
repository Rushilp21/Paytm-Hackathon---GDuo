import 'dart:convert';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'components.dart';
import 'theme.dart';

const pathColors = [blue, teal, violet, amber, Color(0xFFCD508C)];

Future<void> exportScenario(
  BuildContext context,
  String name,
  Object data,
) async {
  try {
    await FilePicker.platform.saveFile(
      fileName: '$name.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: utf8.encode(const JsonEncoder.withIndent('  ').convert(data)),
    );
  } catch (_) {
    if (context.mounted) {
      toast(
        context,
        'Export unavailable. Try exporting from Privacy or another device.',
      );
    }
  }
}

class ControlSlider extends StatelessWidget {
  final String label, value;
  final double current, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  const ControlSlider({
    required this.label,
    required this.value,
    required this.current,
    this.min = 0,
    required this.max,
    required this.divisions,
    required this.onChanged,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          children: [
            Text(label),
            Text(
              value,
              style: const TextStyle(color: blue, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Slider(
          value: current.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: value,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class StatTiles extends StatelessWidget {
  final List<(String, String, String)> items;
  const StatTiles(this.items, {super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final cols = c.maxWidth > 850
          ? items.length
          : c.maxWidth > 460
          ? 2
          : 1;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items
            .map(
              (item) => SizedBox(
                width: math.max(0, (c.maxWidth - (cols - 1) * 12) / cols),
                child: Panel(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$3,
                        style: const TextStyle(fontSize: 11, color: teal),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class ProjectionChart extends StatelessWidget {
  final List<List<double>> series;
  final List<String> names;
  final List<Color> colors;
  final String horizontalLabel;
  const ProjectionChart({
    required this.series,
    required this.names,
    required this.colors,
    this.horizontalLabel = 'Months from today',
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final all = series.expand((s) => s).toList();
    final low = math.min(0.0, all.reduce(math.min));
    final high = math.max(1.0, all.reduce(math.max));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${money(high, compact: true)}  •  projected range  •  ${money(low, compact: true)}',
          style: const TextStyle(fontSize: 11, color: muted),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'Projection chart. Exact values appear in the table below.',
          child: SizedBox(
            height: 230,
            child: CustomPaint(
              painter: _ProjectionPainter(series, colors, low, high),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [const Text('0'), Text('${series.first.length - 1}')],
        ),
        Center(
          child: Text(
            horizontalLabel,
            style: const TextStyle(fontSize: 11, color: muted),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 10,
          children: List.generate(
            names.length,
            (i) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10, color: colors[i]),
                const SizedBox(width: 5),
                Text(names[i], style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectionPainter extends CustomPainter {
  final List<List<double>> series;
  final List<Color> colors;
  final double low, high;
  _ProjectionPainter(this.series, this.colors, this.low, this.high);
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = line
      ..strokeWidth = 1;
    double y(double v) =>
        size.height - 8 - (v - low) / (high - low) * (size.height - 16);
    for (var i = 0; i <= 4; i++) {
      canvas.drawLine(
        Offset(0, i * size.height / 4),
        Offset(size.width, i * size.height / 4),
        grid,
      );
    }
    canvas.drawLine(
      Offset(0, y(0)),
      Offset(size.width, y(0)),
      Paint()
        ..color = muted
        ..strokeWidth = 1,
    );
    for (var i = 0; i < series.length; i++) {
      final path = Path();
      for (var j = 0; j < series[i].length; j++) {
        final x = j / math.max(1, series[i].length - 1) * size.width;
        if (j == 0) {
          path.moveTo(x, y(series[i][j]));
        } else {
          path.lineTo(x, y(series[i][j]));
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[i]
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProjectionPainter old) => true;
}
