import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LineChartCard extends StatelessWidget {
  const LineChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2837).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFC62D), width: 2.5),
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
          colors: [Colors.purpleAccent, Colors.deepPurpleAccent],
        ),
        _buildLineData(
          points: [1.2, 1.4, 2, 2.2, 2.5, 2.9, 3.6],
          colors: [Colors.amberAccent, Colors.orangeAccent],
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
        stops: const [0.0, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      barWidth: 3.5,
      isStrokeCapRound: true,
      belowBarData: BarAreaData(show: false),
      dotData: FlDotData(show: false),
    );
  }
}
