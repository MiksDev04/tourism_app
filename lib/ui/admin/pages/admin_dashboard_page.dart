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
    required this.isNarrow,
  });

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
      ],
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
      icon: Icons.groups_rounded,
      iconColor: AppColors.accentGreen,
      value: '1,842',
      label: 'Total Tourists This Year',
      sub: 'Jan – Apr 2024',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (isNarrow) {
      // 2×2 grid on narrow
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _StatCard(data: _cards[0])),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(data: _cards[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 12.5,
              ),
            ),
            if (data.sub != null) ...[
              const SizedBox(height: 2),
              Text(
                data.sub!,
                style: const TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: 11,
                ),
              ),
            ],
            // Add an empty SizedBox as placeholder for cards without sub
            if (data.sub == null) const SizedBox(height: 17),
          ],
        ),
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
                  _Segment(
                    value: 0.6,
                    color: AppColors.chartCyan,
                    label: 'Male (60%)',
                  ),
                  _Segment(
                    value: 0.4,
                    color: AppColors.chartPurple,
                    label: 'Female (40%)',
                  ),
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
                  _Segment(
                    value: 0.40,
                    color: AppColors.chartGreen,
                    label: 'Philippines (40%)',
                  ),
                  _Segment(
                    value: 0.20,
                    color: AppColors.chartBlue,
                    label: 'USA (20%)',
                  ),
                  _Segment(
                    value: 0.15,
                    color: AppColors.chartOrange,
                    label: 'Japan (15%)',
                  ),
                  _Segment(
                    value: 0.15,
                    color: AppColors.chartPurple,
                    label: 'Korea (15%)',
                  ),
                  _Segment(
                    value: 0.10,
                    color: AppColors.chartGray,
                    label: 'Others (10%)',
                  ),
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
                  _Segment(
                    value: 0.45,
                    color: AppColors.chartCyan,
                    label: 'Private Car (45%)',
                  ),
                  _Segment(
                    value: 0.20,
                    color: AppColors.chartGreen,
                    label: 'Bus (20%)',
                  ),
                  _Segment(
                    value: 0.15,
                    color: AppColors.chartBlue,
                    label: 'Van (15%)',
                  ),
                  _Segment(
                    value: 0.12,
                    color: AppColors.chartOrange,
                    label: 'Motorcycle (12%)',
                  ),
                  _Segment(
                    value: 0.08,
                    color: AppColors.chartGray,
                    label: 'Other (8%)',
                  ),
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
      return Column(children: [barCard, const SizedBox(height: 14), gaugeCard]);
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
    _RegionData('Region IV-A', 0.75),
    _RegionData('Region IV-B', 0.60),
    _RegionData('CARAGA', 0.45),
    _RegionData('CAR', 0.30),
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

class _RegionBar extends StatefulWidget {
  const _RegionBar({required this.data});

  final _RegionData data;

  @override
  State<_RegionBar> createState() => _RegionBarState();
}

class _RegionBarState extends State<_RegionBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _widthAnimation = Tween<double>(
      begin: 0,
      end: widget.data.ratio,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? Matrix4.translationValues(4, 0, 0)
            : Matrix4.identity(),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                widget.data.name,
                style: TextStyle(
                  color: _isHovered ? AppColors.textWhite : AppColors.textGray,
                  fontSize: 12.5,
                  fontWeight: _isHovered ? FontWeight.w600 : FontWeight.normal,
                ),
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
                      AnimatedBuilder(
                        animation: _widthAnimation,
                        builder: (context, child) {
                          return Container(
                            height: 10,
                            width: constraints.maxWidth * _widthAnimation.value,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.gradientStart,
                                  AppColors.gradientEnd,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            if (_isHovered) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  '${(widget.data.ratio * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
// ─── Chart: Donut ─────────────────────────────────────────────────────────────

class _Segment {
  const _Segment({required this.value, required this.color, this.label});
  final double value;
  final Color color;
  final String? label;
}

class _DonutChart extends StatefulWidget {
  const _DonutChart({required this.segments, required this.size});

  final List<_Segment> segments;
  final double size;

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        // Hover detection would require hit testing - simplified for demo
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _DonutPainter(
                    segments: widget.segments,
                    animationValue: _controller.value,
                    hoveredIndex: _hoveredIndex,
                  ),
                  size: Size(widget.size, widget.size),
                );
              },
            ),
            if (_hoveredIndex != -1 &&
                widget.segments[_hoveredIndex].label != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.segments[_hoveredIndex].label!,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.segments,
    required this.animationValue,
    required this.hoveredIndex,
  });

  final List<_Segment> segments;
  final double animationValue;
  final int hoveredIndex;

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
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final sweepAngle = seg.value * 2 * math.pi * animationValue;

      final currentStrokeWidth = (hoveredIndex == i)
          ? strokeWidth + 4
          : strokeWidth;
      final paint = Paint()
        ..color = (hoveredIndex == i) ? seg.color.withOpacity(0.9) : seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle - 0.04, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}

// ─── Chart: Bar ───────────────────────────────────────────────────────────────

class _BarChart extends StatefulWidget {
  const _BarChart();

  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart>
    with SingleTickerProviderStateMixin {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _values = [
    130.0, 140.0, 155.0, 160.0, 180.0, 210.0,
    240.0, 250.0, 245.0, 280.0, 270.0, 360.0,
  ];

  late AnimationController _controller;
  int _hoveredBarIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkHoveredBar(Offset position, Size size) {
    const leftPad = 36.0;
    const bottomPad = 24.0;
    final chartH = size.height - bottomPad;
    final chartW = size.width - leftPad;

    final barW = chartW / _months.length * 0.5;
    final gap = chartW / _months.length;

    for (int i = 0; i < _months.length; i++) {
      final x = leftPad + gap * i + gap / 2 - barW / 2;
      final barRect = Rect.fromLTWH(x, 0, barW, chartH);

      if (barRect.contains(position)) {
        if (_hoveredBarIndex != i) {
          setState(() {
            _hoveredBarIndex = i;
          });
        }
        return;
      }
    }

    if (_hoveredBarIndex != -1) {
      setState(() {
        _hoveredBarIndex = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(event.position);
          _checkHoveredBar(localPosition, renderBox.size);
        }
      },
      onExit: (_) {
        setState(() {
          _hoveredBarIndex = -1;
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _controller.value,
            child: Transform.scale(
              scale: 0.95 + (_controller.value * 0.05),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    painter: _BarPainter(
                      months: _months,
                      values: _values,
                      animationValue: _controller.value,
                      hoveredBarIndex: _hoveredBarIndex,
                    ),
                    size: Size(constraints.maxWidth, 200),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.months,
    required this.values,
    required this.animationValue,
    required this.hoveredBarIndex,
  });

  final List<String> months;
  final List<double> values;
  final double animationValue;
  final int hoveredBarIndex;

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

    const textStyle = TextStyle(color: AppColors.textSubtle, fontSize: 10);

    for (final yv in yLabels) {
      final y = chartH - (yv / maxVal) * chartH;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      _drawText(canvas, '${yv.toInt()}', Offset(0, y - 6), textStyle, size.width);
    }

    final barW = chartW / months.length * 0.5;
    final gap = chartW / months.length;

    for (int i = 0; i < months.length; i++) {
      final x = leftPad + gap * i + gap / 2 - barW / 2;
      final animatedHeight = (values[i] / maxVal) * chartH * animationValue;
      final rect = Rect.fromLTWH(x, chartH - animatedHeight, barW, animatedHeight);

      final isHovered = hoveredBarIndex == i;

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isHovered
              ? [AppColors.chartCyan, AppColors.chartCyan.withOpacity(0.8)]
              : [AppColors.chartCyan, AppColors.chartBlue],
        ).createShader(rect);

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        paint,
      );

      _drawText(canvas, months[i], Offset(x - 4, size.height - 14), textStyle, size.width);

      if (isHovered && animatedHeight > 0) {
        final tooltipText = '${values[i].toInt()} visitors';
        final textPainter = TextPainter(
          text: TextSpan(
            text: tooltipText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final tooltipX = x + barW / 2 - textPainter.width / 2;
        final tooltipY = chartH - animatedHeight - 22;

        if (tooltipY > 0) {
          final tooltipRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              tooltipX - 6,
              tooltipY - 2,
              textPainter.width + 12,
              textPainter.height + 4,
            ),
            const Radius.circular(4),
          );

          final shadowPaint = Paint()..color = Colors.black.withOpacity(0.3);
          canvas.drawRRect(tooltipRect.shift(const Offset(1, 1)), shadowPaint);

          final tooltipPaint = Paint()..color = const Color(0xFF1E293B);
          canvas.drawRRect(tooltipRect, tooltipPaint);

          textPainter.paint(canvas, Offset(tooltipX, tooltipY));
        }
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style, double maxWidth) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.hoveredBarIndex != hoveredBarIndex;
  }
}

// ─── Chart: Gauge ─────────────────────────────────────────────────────────────

class _GaugeChart extends StatefulWidget {
  const _GaugeChart({required this.value});

  final double value;

  @override
  State<_GaugeChart> createState() => _GaugeChartState();
}

class _GaugeChartState extends State<_GaugeChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _valueAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _valueAnimation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? Matrix4.translationValues(4, 0, 0)
            : Matrix4.identity(),
        child: SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _valueAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _GaugePainter(
                      value: _valueAnimation.value,
                      isHovered: _isHovered,
                    ),
                    size: const Size(130, 130),
                  );
                },
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: widget.value),
                    duration: const Duration(milliseconds: 1200),
                    builder: (context, val, child) {
                      return Text(
                        '${(val * 100).toInt()}%',
                        style: TextStyle(
                          color: _isHovered
                              ? AppColors.chartGreen
                              : AppColors.textWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                  const Text(
                    'compliance rate',
                    style: TextStyle(color: AppColors.textSubtle, fontSize: 10),
                  ),
                ],
              ),
              if (_isHovered)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '71% of businesses are compliant',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.value, required this.isHovered});

  final double value;
  final bool isHovered;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeW = 20.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

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

    final valuePaint = Paint()
      ..color = isHovered
          ? AppColors.chartGreen.withOpacity(0.9)
          : AppColors.chartGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? strokeW + 2 : strokeW
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, value * math.pi * 2, false, valuePaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.isHovered != isHovered;
  }
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