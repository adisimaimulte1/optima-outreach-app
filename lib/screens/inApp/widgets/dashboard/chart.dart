import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/events/event_feedback.dart';

enum ChartMode { eventHistory, creditUsage, eventImpact }



class LineChartCard extends StatefulWidget {
  const LineChartCard({super.key});

  @override
  State<LineChartCard> createState() => LineChartCardState();
}

class LineChartCardState extends State<LineChartCard> {
  ChartMode currentMode = ChartMode.eventHistory;

  final Map<ChartMode, List<double>> chartData = {
    ChartMode.eventHistory: [],
    ChartMode.creditUsage: [],
    ChartMode.eventImpact: [],
  };



  @override
  void initState() {
    super.initState();
    _populateChartData();
  }

  void _populateChartData() {
    final now = DateTime.now();
    final last16Days = List.generate(16, (i) => now.subtract(Duration(days: 15 - i)));

    final List<double> historyData = List.filled(16, 0);
    final List<double> creditsData = List.filled(16, 0);
    final List<double> impactData = List.filled(16, 0);

    for (final event in events) {
      final date = event.selectedDate;
      if (date == null) continue;

      for (int i = 0; i < 16; i++) {
        if (_isSameDay(date, last16Days[i])) {
          historyData[i] += 1;
        }
      }
    }

    final creditMap = creditHistoryMap.value;

    for (int i = 0; i < 16; i++) {
      final dateKey = DateFormat('yyyy-MM-dd').format(last16Days[i]);
      final entry = creditMap[dateKey];
      if (entry != null) {
        creditsData[i] = entry.usedCredits + entry.usedSubCredits;
      }

      // Now calculate impact for the same day
      final day = last16Days[i];
      final feedbacksForDay = <EventFeedback>[];

      for (final event in events) {
        final date = event.selectedDate;
        if (date == null || !_isSameDay(date, day)) continue;
        feedbacksForDay.addAll(event.feedback);
      }

      if (feedbacksForDay.isEmpty) {
        impactData[i] = 0;
        continue;
      }

      double totalImpact = 0;

      for (final feedback in feedbacksForDay) {
        if (!feedback.completed) continue;

        final starsScore = feedback.stars.clamp(0, 5) / 5; // 50%
        final organizedScore = feedback.wasOrganizedWell ? 0.2 : 0; // 20%
        final recommendScore = feedback.wouldRecommend ? 0.2 : 0;   // 20%
        final contactScore = feedback.wantsToBeContacted ? 0.1 : 0; // 10%

        final individualScore = (starsScore * 0.5) + organizedScore + recommendScore + contactScore;
        totalImpact += individualScore.clamp(0, 1);
      }

      final totalSub = feedbacksForDay.where((f) => f.completed).length;
      double avgImpact;

      if (totalSub != 0) {
        avgImpact = totalImpact / feedbacksForDay.where((f) => f.completed).length;
      } else { avgImpact = 0; }

      impactData[i] = (avgImpact * 100).clamp(0, 100); // percent
    }


    chartData[ChartMode.eventHistory] = historyData;
    chartData[ChartMode.creditUsage] = creditsData;
    chartData[ChartMode.eventImpact] = impactData;
  }



  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: combinedEventsListenable,
      builder: (context, _) {
        _populateChartData();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: inAppForegroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: textDimColor, width: 1.2),
          ),
          child: Column(
            children: [
              _buildTabs(),
              const SizedBox(height: 4),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 2.5,
                width: double.infinity,
                color: textDimColor.withOpacity(0.4),
              ),
              SizedBox(
                height: 160,
                child: LineChart(
                  _buildChartData(chartData[currentMode]!),
                  duration: const Duration(milliseconds: 800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabs() {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 455).clamp(0.10, 1.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ChartMode.values.map((mode) {
        final isActive = currentMode == mode;
        final label = switch (mode) {
          ChartMode.eventHistory => "Event History",
          ChartMode.creditUsage => "Credits Used",
          ChartMode.eventImpact => "Impact",
        };

        return GestureDetector(
          onTap: () => setState(() => currentMode = mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: 14 * scale,
              vertical: 6 * scale,
            ),
            decoration: BoxDecoration(
              color: isActive ? textHighlightedColor.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(10 * scale),
              border: Border.all(
                color: isActive ? textHighlightedColor : Colors.transparent,
                width: 2 * scale,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.bold,
                color: isActive ? textHighlightedColor : textColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  LineChartData _buildChartData(List<double> points) {
    final maxY = (points.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble();

    final spots = List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i]));

    return LineChartData(
      minX: -1,
      maxX: 16,
      minY: 0,
      maxY: maxY < 2 ? 2 : maxY,
      clipData: FlClipData.none(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: textDimColor.withOpacity(0.15),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: textDimColor.withOpacity(0.5), width: 1),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 25,
            interval: 1,
            getTitlesWidget: (value, _) {
              final index = value.toInt();
              if (index < 0 || index >= 18) return const SizedBox.shrink();

              const tickIndexes = [0, 3, 6, 9, 12, 15];
              if (!tickIndexes.contains(index)) return const SizedBox.shrink();

              final date = DateTime.now().subtract(Duration(days: 15 - index));
              return Transform.translate(
                offset: const Offset(0, 8),
                child: Text(
                  DateFormat('MM/dd').format(date),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 0,
            interval: _getYInterval(points),
            getTitlesWidget: (value, _) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: textHighlightedColor,
          barWidth: 4,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(show: false),
          dotData: FlDotData(show: false),
          showingIndicators: List.generate(points.length, (i) => i),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (barData, indexes) {
          return indexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: textSecondaryHighlightedColor,
                strokeWidth: 2.5,
                dashArray: [4, 4],
              ),
              FlDotData(show: false),
            );
          }).toList();
        },

        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: inAppForegroundColor,
          tooltipRoundedRadius: 10,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          tooltipMargin: 24,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipBorder: BorderSide(
            color: textHighlightedColor,
            width: 3,
          ),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final isImpact = currentMode == ChartMode.eventImpact;
              final isCredits = currentMode == ChartMode.creditUsage;

              final formatted = isImpact
                  ? "${spot.y.toStringAsFixed(0)}%" // whole number + %
                  : (isCredits
                  ? "◉ ${spot.y.toStringAsFixed(2)}"
                  : "${spot.y.toInt()}");

              return LineTooltipItem(
                formatted,
                TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: textHighlightedColor,
                ),
              );
            }).toList();
          },
        ),


      ),

    );

  }



  double _getYInterval(List<double> values) {
    final max = values.reduce((a, b) => a > b ? a : b);
    if (max <= 1) return 1;
    if (max <= 5) return 1;
    if (max <= 10) return 2;
    return (max / 5).ceilToDouble();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
