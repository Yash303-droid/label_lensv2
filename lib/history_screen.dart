import 'package:flutter/material.dart';
import 'package:label_lensv2/app_colors.dart';
import 'package:label_lensv2/app_styles.dart';
import 'package:label_lensv2/auth_service.dart';
import 'package:label_lensv2/neopop_input.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:label_lensv2/scan_result.dart';


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<ScanHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = AuthService().getScanHistory();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.slate900 : AppColors.slate50,
      appBar: AppBar(
        title: Text('SCAN HISTORY', style: AppStyles.heading1.copyWith(fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? AppColors.white : AppColors.slate900),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            NeopopInput(
              hint: 'Search past scans...',
              icon: Icons.search,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<ScanHistoryItem>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Failed to load history: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No scan history found.'));
                  }

                  final historyItems = snapshot.data!;
                  return ListView.builder(
                    itemCount: historyItems.length,
                    itemBuilder: (context, index) {
                      final item = historyItems[index];
                      final result = item.result;
                      final severity = result.severity.toLowerCase();
                      final statusColor = severity == 'critical'
                          ? AppColors.rose400
                          : (severity == 'moderate' ? AppColors.amber300 : AppColors.emerald400);

                      return GestureDetector(
                        onTap: () => _showHistoryDetailDialog(context, item, isDarkMode),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? AppColors.slate800 : AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: statusColor, width: 2),
                            boxShadow: [AppStyles.getShadow(isDarkMode)],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      result.productName,
                                      style: AppStyles.bodyBold.copyWith(fontWeight: FontWeight.w900),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat.yMMMd().add_jm().format(item.createdAt.toLocal()),
                                      style: AppStyles.body.copyWith(
                                        fontSize: 12,
                                        color: isDarkMode ? Colors.white24 : AppColors.slate900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.chevron_right, color: isDarkMode ? Colors.white60 : AppColors.slate900),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryDetailDialog(BuildContext context, ScanHistoryItem item, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.slate800 : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: AppStyles.getBorderSide(isDarkMode, width: 2),
          ),
          title: Text(item.result.productName, style: AppStyles.heading1, textAlign: TextAlign.center),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.result.summary, textAlign: TextAlign.center, style: AppStyles.body),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RiskScorePieChart(
                          riskScore: item.result.riskScore, isDarkMode: isDarkMode),
                      SafeStatusWidget(isSafe: item.result.safe, isDarkMode: isDarkMode),
                    ],
                  ),
                  if (item.result.issues.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Identified Issues', style: AppStyles.heading1.copyWith(fontSize: 16)),
                    const SizedBox(height: 8),
                    ...item.result.issues.map((issue) => Text('• ${issue.reason}', style: AppStyles.body)),
                  ],
                  if (item.result.alternatives.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Suggested Alternatives', style: AppStyles.heading1.copyWith(fontSize: 16)),
                    const SizedBox(height: 8),
                    ...item.result.alternatives.map((alt) => Card(
                          color: isDarkMode ? AppColors.slate700 : AppColors.slate100,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(alt.name, style: AppStyles.bodyBold),
                                const SizedBox(height: 4),
                                Text(alt.reason, style: AppStyles.body),
                              ],
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class SafeStatusWidget extends StatelessWidget {
  final bool isSafe;
  final bool isDarkMode;

  const SafeStatusWidget(
      {Key? key, required this.isSafe, required this.isDarkMode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isSafe ? AppColors.emerald500 : AppColors.rose500;
    final icon =
        isSafe ? Icons.check_circle_outline : Icons.dangerous_outlined;
    final text = isSafe ? 'Considered Safe' : 'Potential Risks';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.slate800 : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
        boxShadow: [AppStyles.getShadow(isDarkMode)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(text, style: AppStyles.bodyBold.copyWith(color: color)),
        ],
      ),
    );
  }
}

class RiskScorePieChart extends StatelessWidget {
  final int riskScore;
  final bool isDarkMode;

  const RiskScorePieChart(
      {Key? key, required this.riskScore, required this.isDarkMode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color scoreColor;
    if (riskScore <= 30) {
      scoreColor = AppColors.emerald500;
    } else if (riskScore <= 70) {
      scoreColor = AppColors.amber300;
    } else {
      scoreColor = AppColors.rose500;
    }

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CustomPaint(
              painter: _PieChartPainter(
                percentage: riskScore,
                color: scoreColor,
                backgroundColor:
                    isDarkMode ? AppColors.slate700 : AppColors.slate200,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$riskScore',
                  style: AppStyles.heading1.copyWith(fontSize: 28, color: scoreColor)),
              Text('Risk Score',
                  style: AppStyles.body.copyWith(fontSize: 12,
                      color: isDarkMode ? AppColors.slate300 : AppColors.slate600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final int percentage;
  final Color color;
  final Color backgroundColor;

  _PieChartPainter(
      {required this.percentage,
      required this.color,
      required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Foreground arc
    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * (percentage / 100);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweepAngle, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(_PieChartPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}