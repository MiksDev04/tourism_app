import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/business_layout.dart';

// ─── Business Dashboard Page ──────────────────────────────────────────────────

class BusinessDashboardPage extends StatelessWidget {
  const BusinessDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BusinessLayout(
      title: 'Dashboard',
      selectedIndex: 0,
      onNavSelected: (_) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HotelHeader(),
            const SizedBox(height: 20),
            const _StatCards(),
            const SizedBox(height: 20),
            const _DonutChartsRow(),
            const SizedBox(height: 20),
            const _TouristTrendCard(),
            const SizedBox(height: 20),
            const _TopRegionsCard(),
          ],
        ),
      ),
    );
  }
}

// ─── Hotel Header ─────────────────────────────────────────────────────────────

class _HotelHeader extends StatelessWidget {
  const _HotelHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grand Hotel San Pablo',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Hotel  •  45 Rooms  •  Maharlika Highway',
          style: TextStyle(color: AppColors.textGray, fontSize: 13),
        ),
      ],
    );
  }
}

// ─── Stat Cards ───────────────────────────────────────────────────────────────

class _StatCards extends StatelessWidget {
  const _StatCards();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_alt_rounded,
            iconColor: AppColors.primaryCyan,
            value: '0',
            label: 'Guests This Month',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.primaryBlue,
            value: '51',
            label: 'Guests This Year',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule_rounded,
            iconColor: AppColors.accentGreen,
            value: '2.0 nights',
            label: 'Avg. Length of Stay',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            icon: Icons.bed_rounded,
            iconColor: AppColors.accentOrange,
            value: '45',
            label: 'Total Rooms',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textGray, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

// ─── Donut Charts Row ─────────────────────────────────────────────────────────

class _DonutChartsRow extends StatelessWidget {
  const _DonutChartsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DashCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle(title: 'Gender Distribution'),
                const SizedBox(height: 16),
                Center(
                  child: _DonutChart(
                    segments: const [
                      _Segment(value: 0.60, color: AppColors.chartCyan),
                      _Segment(value: 0.30, color: AppColors.chartPurple),
                      _Segment(value: 0.10, color: AppColors.chartOrange),
                    ],
                    size: 140,
                  ),
                ),
                const SizedBox(height: 14),
                const _Legend(
                  items: [
                    _LegendItem(label: 'Male', color: AppColors.chartCyan),
                    _LegendItem(label: 'Female', color: AppColors.chartPurple),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _DashCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle(title: 'Top 5 Nationalities'),
                const SizedBox(height: 16),
                Center(
                  child: _DonutChart(
                    segments: const [
                      _Segment(value: 0.38, color: AppColors.chartGreen),
                      _Segment(value: 0.20, color: AppColors.chartBlue),
                      _Segment(value: 0.18, color: AppColors.chartOrange),
                      _Segment(value: 0.14, color: AppColors.chartPurple),
                      _Segment(value: 0.10, color: AppColors.chartGray),
                    ],
                    size: 140,
                  ),
                ),
                const SizedBox(height: 14),
                const _Legend(
                  items: [
                    _LegendItem(
                      label: 'Philippines',
                      color: AppColors.chartGreen,
                    ),
                    _LegendItem(label: 'USA', color: AppColors.chartBlue),
                    _LegendItem(label: 'Japan', color: AppColors.chartOrange),
                    _LegendItem(label: 'Korea', color: AppColors.chartPurple),
                    _LegendItem(label: 'Others', color: AppColors.chartGray),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _DashCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle(title: 'Mode of Transportation'),
                const SizedBox(height: 16),
                Center(
                  child: _DonutChart(
                    segments: const [
                      _Segment(value: 0.44, color: AppColors.chartCyan),
                      _Segment(value: 0.20, color: AppColors.chartGreen),
                      _Segment(value: 0.16, color: AppColors.chartOrange),
                      _Segment(value: 0.12, color: AppColors.chartPurple),
                      _Segment(value: 0.08, color: AppColors.chartGray),
                    ],
                    size: 140,
                  ),
                ),
                const SizedBox(height: 14),
                const _Legend(
                  items: [
                    _LegendItem(
                      label: 'Private Car',
                      color: AppColors.chartCyan,
                    ),
                    _LegendItem(label: 'Bus', color: AppColors.chartGreen),
                    _LegendItem(label: 'Van', color: AppColors.chartOrange),
                    _LegendItem(
                      label: 'Motorcycle',
                      color: AppColors.chartPurple,
                    ),
                    _LegendItem(label: 'Other', color: AppColors.chartGray),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tourist Trend Card ───────────────────────────────────────────────────────

class _TouristTrendCard extends StatelessWidget {
  const _TouristTrendCard();

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(title: 'Tourist Trend (2024)'),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: _BarChart()),
        ],
      ),
    );
  }
}

// ─── Top Regions Card ─────────────────────────────────────────────────────────

class _TopRegionsCard extends StatelessWidget {
  const _TopRegionsCard();

  static const _regions = [
    _RegionData('NCR', 1.0),
    _RegionData('Laguna', 0.72),
    _RegionData('Cavite', 0.55),
    _RegionData('Batangas', 0.42),
    _RegionData('Quezon', 0.28),
  ];

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(title: 'Top Local Regions (Philippine Visitors)'),
          const SizedBox(height: 16),
          ..._regions.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RegionBar(data: r),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionData {
  const _RegionData(this.name, this.ratio);
  final String name;
  final double ratio;
}

class _RegionBar extends StatelessWidget {
  const _RegionBar({required this.data});
  final _RegionData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            data.name,
            style: const TextStyle(color: AppColors.textGray, fontSize: 12.5),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (_, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Container(
                    height: 10,
                    width: constraints.maxWidth * data.ratio,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Chart: Donut ─────────────────────────────────────────────────────────────

class _Segment {
  const _Segment({required this.value, required this.color});
  final double value;
  final Color color;
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.segments, required this.size});
  final List<_Segment> segments;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DonutPainter(segments: segments)),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.segments});
  final List<_Segment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweepAngle = seg.value * 2 * math.pi;
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle - 0.04,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Chart: Bar ───────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  // Only Jan–Apr have data, rest are 0
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static final _values =
      <double>[22.0, 29.0, 11.0, 39.0, 0, 0, 0, 0, 0, 0, 0, 0];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarPainter(months: _months, values: _values),
      size: Size.infinite,
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({required this.months, required this.values});
  final List<String> months;
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    const maxVal = 40.0;
    const yLabels = [0.0, 10.0, 20.0, 30.0, 40.0];
    const leftPad = 36.0;
    const bottomPad = 24.0;
    final chartH = size.height - bottomPad;
    final chartW = size.width - leftPad;

    final gridPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 0.5;
    const textStyle = TextStyle(color: AppColors.textSubtle, fontSize: 10);

    // Y grid + labels
    for (final yv in yLabels) {
      final y = chartH - (yv / maxVal) * chartH;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      _drawText(
        canvas,
        '${yv.toInt()}',
        Offset(0, y - 6),
        textStyle,
        size.width,
      );
    }

    // Bars
    final barW = chartW / months.length * 0.45;
    final gap = chartW / months.length;

    for (int i = 0; i < months.length; i++) {
      final x = leftPad + gap * i + gap / 2 - barW / 2;
      final barH = (values[i] / maxVal) * chartH;

      if (barH > 0) {
        final rect = Rect.fromLTWH(x, chartH - barH, barW, barH);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.chartPurple,
                AppColors.chartPurple.withOpacity(0.5),
              ],
            ).createShader(rect),
        );
      }

      _drawText(
        canvas,
        months[i],
        Offset(x - 4, size.height - 14),
        textStyle,
        size.width,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
    double maxWidth,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _DashCard extends StatelessWidget {
  const _DashCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textWhite,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _LegendItem {
  const _LegendItem({required this.label, required this.color});
  final String label;
  final Color color;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.items});
  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item.label,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
