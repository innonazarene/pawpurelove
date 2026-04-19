import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/care_log.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  final String petId;
  const AnalyticsScreen({super.key, required this.petId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  List<CareLog> _allLogs = [];
  
  Map<CareType, int> _typeCounts = {};
  List<MapEntry<DateTime, int>> _weeklyDailyActivity = [];
  List<CareLog> _weightLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = await StorageService.getInstance();
    final logs = storage.getCareLogsByPet(widget.petId);

    // Filter weights
    final weights = logs.where((l) => l.type == CareType.weightLog && l.value != null).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Distribution
    final counts = <CareType, int>{};
    for (final log in logs) {
      counts[log.type] = (counts[log.type] ?? 0) + 1;
    }

    // Weekly activity
    final now = DateTime.now();
    final Map<String, int> dailyCounts = {};
    // Initialize last 7 days
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      dailyCounts[DateFormat('yyyy-MM-dd').format(day)] = 0;
    }

    for (final log in logs) {
      if (log.dateTime.isAfter(now.subtract(const Duration(days: 7)))) {
        final key = DateFormat('yyyy-MM-dd').format(log.dateTime);
        if (dailyCounts.containsKey(key)) {
          dailyCounts[key] = dailyCounts[key]! + 1;
        }
      }
    }

    final weeklyList = dailyCounts.entries.map((e) {
      return MapEntry(DateTime.parse(e.key), e.value);
    }).toList();
    weeklyList.sort((a, b) => a.key.compareTo(b.key));

    setState(() {
      _allLogs = logs;
      _weightLogs = weights;
      _typeCounts = counts;
      _weeklyDailyActivity = weeklyList;
      _isLoading = false;
    });
  }

  Color _getColorForType(CareType type) {
    switch (type.category) {
      case 'daily': return AppColors.dailyCare;
      case 'health': return AppColors.health;
      case 'memory': return AppColors.memory;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allLogs.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Activity Distribution'),
                      const SizedBox(height: 16),
                      _buildPieChartSection(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Activity - Last 7 Days'),
                      const SizedBox(height: 16),
                      _buildBarChartSection(),
                      if (_weightLogs.length > 1) ...[
                        const SizedBox(height: 32),
                        _buildSectionTitle('Weight Trend'),
                        const SizedBox(height: 16),
                        _buildLineChartSection(),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: AppColors.textLight.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No data to analyze yet!',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textBrown),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep tracking activities to generate reports.',
            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textBrown,
      ),
    );
  }

  Widget _buildSummaryCards() {
    int totalLogs = _allLogs.length;
    int thisWeek = _weeklyDailyActivity.fold(0, (sum, entry) => sum + entry.value);
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Logs',
            totalLogs.toString(),
            Icons.format_list_bulleted_rounded,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'This Week',
            thisWeek.toString(),
            Icons.trending_up_rounded,
            AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textBrown),
                ),
                Text(
                  title,
                  style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection() {
    if (_typeCounts.isEmpty) return const SizedBox();

    final List<PieChartSectionData> sections = [];
    final List<Widget> legends = [];

    _typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..forEach((entry) {
        final percent = (entry.value / _allLogs.length) * 100;
        final color = _getColorForType(entry.key);
        
        sections.add(
          PieChartSectionData(
            color: color,
            value: entry.value.toDouble(),
            title: '${percent.toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );

        legends.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(entry.key.label, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textDark)),
                const Spacer(),
                Text('${entry.value}', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textBrown)),
              ],
            ),
          ),
        );
      });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...legends,
        ],
      ),
    );
  }

  Widget _buildBarChartSection() {
    final maxCount = _weeklyDailyActivity.fold<int>(0, (max, e) => e.value > max ? e.value : max);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxCount > 0 ? (maxCount + 2).toDouble() : 5.0,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _weeklyDailyActivity.length) {
                    final date = _weeklyDailyActivity[index].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('E').format(date),
                        style: GoogleFonts.nunito(color: AppColors.textMuted, fontSize: 12),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value % 1 == 0) {
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.nunito(color: AppColors.textMuted, fontSize: 12),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _weeklyDailyActivity.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value.toDouble(),
                  color: AppColors.primary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLineChartSection() {
    final List<FlSpot> spots = [];
    double minX = _weightLogs.first.dateTime.millisecondsSinceEpoch.toDouble();
    double maxX = _weightLogs.last.dateTime.millisecondsSinceEpoch.toDouble();
    double minY = _weightLogs.first.value!;
    double maxY = _weightLogs.first.value!;

    for (var log in _weightLogs) {
      if (log.value != null) {
        spots.add(FlSpot(log.dateTime.millisecondsSinceEpoch.toDouble(), log.value!));
        if (log.value! < minY) minY = log.value!;
        if (log.value! > maxY) maxY = log.value!;
      }
    }

    if (minX == maxX) {
      minX -= const Duration(days: 1).inMilliseconds;
      maxX += const Duration(days: 1).inMilliseconds;
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: (minY - 1).floorToDouble(),
          maxY: (maxY + 1).ceilToDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.health,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.health.withValues(alpha: 0.2),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MMM d').format(date),
                      style: GoogleFonts.nunito(color: AppColors.textMuted, fontSize: 10),
                    ),
                  );
                },
                interval: (maxX - minX) / 3 > 0 ? (maxX - minX) / 3 : 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: GoogleFonts.nunito(color: AppColors.textMuted, fontSize: 12),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
