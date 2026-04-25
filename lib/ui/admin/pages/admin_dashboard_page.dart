import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/admin_layout.dart';

// ─── Dashboard Page ───────────────────────────────────────────────────────────

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isMonthly = true;

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Dashboard',
      selectedIndex: 0,
      onNavSelected: (_) {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final isMedium = constraints.maxWidth < 900;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isNarrow ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(
                  isMonthly: _isMonthly,
                  onToggle: (v) => setState(() => _isMonthly = v),
                  isNarrow: isNarrow,
                ),
                const SizedBox(height: 20),
                _StatCards(isNarrow: isNarrow, isMedium: isMedium),
                const SizedBox(height: 20),
                _DonutChartsRow(isNarrow: isNarrow, isMedium: isMedium),
                const SizedBox(height: 20),
                _BottomChartsRow(isNarrow: isNarrow),
                const SizedBox(height: 20),
                _TopRegionsCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Dashboard Header ─────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.isMonthly,
    required this.onToggle,
    required this.isNarrow,
  });

  final bool isMonthly;
  final ValueChanged<bool> onToggle;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tourism Overview',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'San Pablo City — April 2024',
                style: TextStyle(color: AppColors.textGray, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TogglePill(isMonthly: isMonthly, onToggle: onToggle),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tourism Overview',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'San Pablo City — April 2024',
              style: TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ],
        ),
        const Spacer(),
        _TogglePill(isMonthly: isMonthly, onToggle: onToggle),
      ],
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({required this.isMonthly, required this.onToggle});

  final bool isMonthly;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _PillTab(
            label: 'Monthly',
            isActive: isMonthly,
            onTap: () => onToggle(true),
          ),
          _PillTab(
            label: 'Annually',
            isActive: !isMonthly,
            onTap: () => onToggle(false),
          ),
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                )
              : null,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textGray,
            fontSize: 12.5,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Stat Cards ───────────────────────────────────────────────────────────────

class _StatCards extends StatelessWidget {
  const _StatCards({required this.isNarrow, required this.isMedium});

  final bool isNarrow;
  final bool isMedium;

  static const _cards = [
    _StatCardData(
      icon: Icons.assignment_rounded,
      iconColor: AppColors.primaryCyan,
      value: '2',
      label: 'Active Accommodations',
      sub: '2 pending',
    ),
    _StatCardData(
      icon: Icons.people_alt_rounded,
      iconColor: AppColors.primaryBlue,
      value: '221',
      label: 'Tourists (This Month)',
    ),
    _StatCardData(
      icon: Icons.calendar_today_rounded,
      iconColor: AppColors.accentOrange,
      value: '2',
      label: 'Pending Registrations',
    ),
    _StatCardData(
      icon: Icons.trending_up_rounded,
      iconColor: AppColors.accentGreen,
      value: '71%',
      label: 'Submission Compliance',
      sub: 'of businesses',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (isNarrow) {
      // 2×2 grid on narrow
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatCard(data: _cards[0])),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(data: _cards[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(data: _cards[2])),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(data: _cards[3])),
            ],
          ),
        ],
      );
    }
    // Single row on medium/wide
    return Row(
      children: _cards
          .expand(
            (d) => [
              Expanded(child: _StatCard(data: d)),
              if (d != _cards.last) const SizedBox(width: 14),
            ],
          )
          .toList(),
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.sub,
  });
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? sub;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: data.iconColor, size: 22),
          const SizedBox(height: 14),
          Text(
            data.value,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: const TextStyle(color: AppColors.textGray, fontSize: 12.5),
          ),
          if (data.sub != null) ...[
            const SizedBox(height: 2),
            Text(
              data.sub!,
              style:
                  const TextStyle(color: AppColors.textSubtle, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Donut Charts Row ─────────────────────────────────────────────────────────

class _DonutChartsRow extends StatelessWidget {
  const _DonutChartsRow({required this.isNarrow, required this.isMedium});

  final bool isNarrow;
  final bool isMedium;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _DashCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardTitle(title: 'Gender Distribution'),
            const SizedBox(height: 16),
            Center(
              child: _DonutChart(
                segments: const [
                  _Segment(value: 0.6, color: AppColors.chartCyan),
                  _Segment(value: 0.3, color: AppColors.chartPurple),
                  _Segment(value: 0.1, color: AppColors.chartOrange),
                ],
                size: 130,
              ),
            ),
            const SizedBox(height: 14),
            _Legend(
              items: const [
                _LegendItem(label: 'Male', color: AppColors.chartCyan),
                _LegendItem(label: 'Female', color: AppColors.chartPurple),
              ],
            ),
          ],
        ),
      ),
      _DashCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardTitle(title: 'Top 5 Nationalities'),
            const SizedBox(height: 16),
            Center(
              child: _DonutChart(
                segments: const [
                  _Segment(value: 0.40, color: AppColors.chartGreen),
                  _Segment(value: 0.20, color: AppColors.chartBlue),
                  _Segment(value: 0.15, color: AppColors.chartOrange),
                  _Segment(value: 0.15, color: AppColors.chartPurple),
                  _Segment(value: 0.10, color: AppColors.chartGray),
                ],
                size: 130,
              ),
            ),
            const SizedBox(height: 14),
            _Legend(
              items: const [
                _LegendItem(label: 'Philippines', color: AppColors.chartGreen),
                _LegendItem(label: 'USA', color: AppColors.chartBlue),
                _LegendItem(label: 'Japan', color: AppColors.chartOrange),
                _LegendItem(label: 'Korea', color: AppColors.chartPurple),
                _LegendItem(label: 'Others', color: AppColors.chartGray),
              ],
            ),
          ],
        ),
      ),
      _DashCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardTitle(title: 'Mode of Transportation'),
            const SizedBox(height: 16),
            Center(
              child: _DonutChart(
                segments: const [
                  _Segment(value: 0.45, color: AppColors.chartCyan),
                  _Segment(value: 0.20, color: AppColors.chartGreen),
                  _Segment(value: 0.15, color: AppColors.chartBlue),
                  _Segment(value: 0.12, color: AppColors.chartOrange),
                  _Segment(value: 0.08, color: AppColors.chartGray),
                ],
                size: 130,
              ),
            ),
            const SizedBox(height: 14),
            _Legend(
              items: const [
                _LegendItem(label: 'Private Car', color: AppColors.chartCyan),
                _LegendItem(label: 'Bus', color: AppColors.chartGreen),
                _LegendItem(label: 'Van', color: AppColors.chartBlue),
                _LegendItem(label: 'Motorcycle', color: AppColors.chartOrange),
                _LegendItem(label: 'Other', color: AppColors.chartGray),
              ],
            ),
          ],
        ),
      ),
    ];

    if (isNarrow) {
      // Stack all vertically on narrow
      return Column(
        children: cards
            .expand((c) => [c, const SizedBox(height: 14)])
            .take(cards.length * 2 - 1)
            .toList(),
      );
    }
    if (isMedium) {
      // First card full-width, next two side-by-side
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: cards[1]),
              const SizedBox(width: 14),
              Expanded(child: cards[2]),
            ],
          ),
        ],
      );
    }
    // Original 3-column row
    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 14),
        Expanded(child: cards[1]),
        const SizedBox(width: 14),
        Expanded(child: cards[2]),
      ],
    );
  }
}

// ─── Bottom Charts Row ────────────────────────────────────────────────────────

class _BottomChartsRow extends StatelessWidget {
  const _BottomChartsRow({required this.isNarrow});

  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final barCard = _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(title: 'Tourist Trend (12 Months)'),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: _BarChart()),
        ],
      ),
    );

    final gaugeCard = _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(title: 'Submission Compliance'),
          const SizedBox(height: 16),
          Center(child: _GaugeChart(value: 0.71)),
          const SizedBox(height: 16),
          _ComplianceRow(
            label: 'Compliant',
            count: '1 businesses',
            color: AppColors.chartGreen,
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: 8),
          _ComplianceRow(
            label: 'Non-Compliant',
            count: '1 businesses',
            color: AppColors.accentRed,
            icon: Icons.cancel_outlined,
          ),
        ],
      ),
    );

    if (isNarrow) {
      return Column(
        children: [
          barCard,
          const SizedBox(height: 14),
          gaugeCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: barCard),
        const SizedBox(width: 14),
        Expanded(child: gaugeCard),
      ],
    );
  }
}

class _ComplianceRow extends StatelessWidget {
  const _ComplianceRow({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final String count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textGray, fontSize: 12),
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Top Regions Card ─────────────────────────────────────────────────────────

class _TopRegionsCard extends StatelessWidget {
  static const _regions = [
    _RegionData('NCR', 1.0),
    _RegionData('Laguna', 0.75),
    _RegionData('Cavite', 0.60),
    _RegionData('Batangas', 0.45),
    _RegionData('Quezon', 0.30),
  ];

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            title: 'Top Local Regions (Philippine Visitors Only)',
          ),
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
            builder: (context, constraints) {
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
    const strokeWidth = 22.0;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweepAngle = seg.value * 2 * math.pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweepAngle - 0.04, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Chart: Bar ───────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _values = [
    130.0, 140.0, 155.0, 160.0, 180.0, 210.0,
    240.0, 250.0, 245.0, 280.0, 270.0, 360.0,
  ];

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
    const yLabels = [0.0, 90.0, 180.0, 270.0, 360.0];
    const maxVal = 360.0;
    const leftPad = 36.0;
    const bottomPad = 24.0;
    final chartH = size.height - bottomPad;
    final chartW = size.width - leftPad;

    final gridPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 0.5;

    const textStyle = TextStyle(
      color: AppColors.textSubtle,
      fontSize: 10,
    );

    // Y grid lines & labels
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
    final barW = chartW / months.length * 0.5;
    final gap = chartW / months.length;

    for (int i = 0; i < months.length; i++) {
      final x = leftPad + gap * i + gap / 2 - barW / 2;
      final barH = (values[i] / maxVal) * chartH;
      final rect = Rect.fromLTWH(x, chartH - barH, barW, barH);

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.chartCyan, AppColors.chartBlue.withOpacity(0.6)],
        ).createShader(rect);

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        paint,
      );

      // Month label
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Chart: Gauge ─────────────────────────────────────────────────────────────

class _GaugeChart extends StatelessWidget {
  const _GaugeChart({required this.value});

  final double value; // 0.0 - 1.0

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _GaugePainter(value: value),
            size: const Size(130, 130),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(value * 100).toInt()}%',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'compliance rate',
                style: TextStyle(color: AppColors.textSubtle, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeW = 20.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = AppColors.chartGray
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    // Value arc
    canvas.drawArc(
      rect,
      -math.pi / 2,
      value * math.pi * 2,
      false,
      Paint()
        ..color = AppColors.chartGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Shared Card Shell ────────────────────────────────────────────────────────

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

// ─── Card Title ───────────────────────────────────────────────────────────────

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
      children: items.map((item) => _LegendDot(item: item)).toList(),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.item});

  final _LegendItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          item.label,
          style: const TextStyle(color: AppColors.textGray, fontSize: 11),
        ),
      ],
    );
  }
}