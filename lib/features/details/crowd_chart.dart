import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CrowdChart extends StatelessWidget {
  const CrowdChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Times',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.7,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barTouchData: BarTouchData(
                enabled: false,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.transparent,
                  tooltipPadding: EdgeInsets.zero,
                  tooltipMargin: 8,
                  getTooltipItem:
                      (
                        BarChartGroupData group,
                        int groupIndex,
                        BarChartRodData rod,
                        int rodIndex,
                      ) {
                        return BarTooltipItem(
                          rod.toY.round().toString(),
                          const TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      const style = TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      );
                      String text;
                      switch (value.toInt()) {
                        case 0:
                          text = '10am';
                          break;
                        case 1:
                          text = '12pm';
                          break;
                        case 2:
                          text = '2pm';
                          break;
                        case 3:
                          text = '4pm';
                          break;
                        case 4:
                          text = '6pm';
                          break;
                        case 5:
                          text = '8pm';
                          break;
                        case 6:
                          text = '10pm';
                          break;
                        default:
                          return Container();
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4,
                        child: Text(text, style: style),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                _makeGroupData(0, 30), // 10am
                _makeGroupData(1, 50), // 12pm
                _makeGroupData(2, 80, isHigh: true), // 2pm (Peak)
                _makeGroupData(3, 70), // 4pm
                _makeGroupData(4, 90, isHigh: true), // 6pm (Peak)
                _makeGroupData(5, 60), // 8pm
                _makeGroupData(6, 40), // 10pm
              ],
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, {bool isHigh = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isHigh ? Colors.redAccent : Colors.blue.shade300,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}
