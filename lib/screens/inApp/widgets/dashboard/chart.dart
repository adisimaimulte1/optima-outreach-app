import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:optima/globals.dart';

class LineChartCard extends StatelessWidget {
  const LineChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: inAppForegroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textDimColor,
          width: 1.2,
        ),
      ),
      child: SizedBox(
        height: 120,
        child: LineChart(
          _buildChartData(),
          duration: const Duration(milliseconds: 800),
        ),
      ),
    );
  }

  LineChartData _buildChartData() {
    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        _buildLineData(
          points: [2, 2.2, 2, 2.8, 3.2, 3, 3.8],
          colors: [Colors.purple, Colors.deepPurple],
        ),
        _buildLineData(
          points: [1, 1.1, 1.5, 1.7, 2, 2.3, 2.7], // shifted down to avoid overlap
          colors: [Colors.orange, Colors.deepOrange],
        ),
      ],
    );
  }

  LineChartBarData _buildLineData({
    required List<double> points,
    required List<Color> colors,
  }) {
    return LineChartBarData(
      spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i])),
      isCurved: true,
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        stops: const [0.0, 1.0],
      ),
      barWidth: 4.5,
      isStrokeCapRound: true,
      shadow: const Shadow(
        blurRadius: 8,
        color: Colors.black54,
        offset: Offset(0, 2),
      ),
      belowBarData: BarAreaData(show: false),
      dotData: FlDotData(show: false),
    );
  }
}
