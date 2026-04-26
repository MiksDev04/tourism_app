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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              Row(
                children: const [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people_alt_rounded,
                      iconColor: AppColors.primaryCyan,
                      value: '0',
                      label: 'Guests This Month',
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.trending_up_rounded,
                      iconColor: AppColors.primaryBlue,
                      value: '51',
                      label: 'Guests This Year',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.schedule_rounded,
                      iconColor: AppColors.accentGreen,
                      value: '2.0 nights',
                      label: 'Avg. Length of Stay',
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.bed_rounded,
                      iconColor: AppColors.accentOrange,
                      value: '45',
                      label: 'Total Rooms',
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: const [
              Expanded(
                child: _StatCard(
                  icon: Icons.people_alt_rounded,
                  iconColor: AppColors.primaryCyan,
                  value: '0',
                  label: 'Guests This Month',
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.primaryBlue,
                  value: '51',
                  label: 'Guests This Year',
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: _StatCard(
                  icon: Icons.schedule_rounded,
                  iconColor: AppColors.accentGreen,
                  value: '2.0 nights',
                  label: 'Avg. Length of Stay',
                ),
              ),
              SizedBox(width: 14),
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
      },
    );
  }
}

class _ResponsiveStatCard extends StatelessWidget {
  const _ResponsiveStatCard({
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
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 62) / 2,
      child: _StatCard(
        icon: icon,
        iconColor: iconColor,
        value: value,
        label: label,
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              Row(
                children: const [
                  Expanded(child: _DonutChartCard1()),
                  SizedBox(width: 14),
                  Expanded(child: _DonutChartCard2()),
                ],
              ),
              const SizedBox(height: 14),
              const _DonutChartCard3(),
            ],
          );
        } else if (constraints.maxWidth < 600) {
          return Column(
            children: const [
              _DonutChartCard1(),
              SizedBox(height: 14),
              _DonutChartCard2(),
              SizedBox(height: 14),
              _DonutChartCard3(),
            ],
          );
        } else {
          return Row(
            children: const [
              Expanded(child: _DonutChartCard1()),
              SizedBox(width: 14),
              Expanded(child: _DonutChartCard2()),
              SizedBox(width: 14),
              Expanded(child: _DonutChartCard3()),
            ],
          );
        }
      },
    );
  }
}

class _DonutChartCard1 extends StatelessWidget {
  const _DonutChartCard1();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final chartSize = isSmallScreen ? 120.0 : 140.0;
    
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(title: 'Gender Distribution'),
          const SizedBox(height: 16),
          Center(
            child: _DonutChart(
              segments: const [
                _Segment(value: 0.60, color: AppColors.chartCyan, label: 'Male', percentage: '60%'),
                _Segment(value: 0.30, color: AppColors.chartPurple, label: 'Female', percentage: '30%'),
                _Segment(value: 0.10, color: AppColors.chartOrange, label: 'Other', percentage: '10%'),
              ],
              size: chartSize,
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
    );
  }
}

class _DonutChartCard2 extends StatelessWidget {
  const _DonutChartCard2();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final chartSize = isSmallScreen ? 120.0 : 140.0;
    
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(title: 'Top 5 Nationalities'),
          const SizedBox(height: 16),
          Center(
            child: _DonutChart(
              segments: const [
                _Segment(value: 0.38, color: AppColors.chartGreen, label: 'Philippines', percentage: '38%'),
                _Segment(value: 0.20, color: AppColors.chartBlue, label: 'USA', percentage: '20%'),
                _Segment(value: 0.18, color: AppColors.chartOrange, label: 'Japan', percentage: '18%'),
                _Segment(value: 0.14, color: AppColors.chartPurple, label: 'Korea', percentage: '14%'),
                _Segment(value: 0.10, color: AppColors.chartGray, label: 'Others', percentage: '10%'),
              ],
              size: chartSize,
            ),
          ),
          const SizedBox(height: 14),
          const _Legend(
            items: [
              _LegendItem(label: 'Philippines', color: AppColors.chartGreen),
              _LegendItem(label: 'USA', color: AppColors.chartBlue),
              _LegendItem(label: 'Japan', color: AppColors.chartOrange),
              _LegendItem(label: 'Korea', color: AppColors.chartPurple),
              _LegendItem(label: 'Others', color: AppColors.chartGray),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartCard3 extends StatelessWidget {
  const _DonutChartCard3();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final chartSize = isSmallScreen ? 120.0 : 140.0;
    
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(title: 'Mode of Transportation'),
          const SizedBox(height: 16),
          Center(
            child: _DonutChart(
              segments: const [
                _Segment(value: 0.44, color: AppColors.chartCyan, label: 'Private Car', percentage: '44%'),
                _Segment(value: 0.20, color: AppColors.chartGreen, label: 'Bus', percentage: '20%'),
                _Segment(value: 0.16, color: AppColors.chartOrange, label: 'Van', percentage: '16%'),
                _Segment(value: 0.12, color: AppColors.chartPurple, label: 'Motorcycle', percentage: '12%'),
                _Segment(value: 0.08, color: AppColors.chartGray, label: 'Other', percentage: '8%'),
              ],
              size: chartSize,
            ),
          ),
          const SizedBox(height: 14),
          const _Legend(
            items: [
              _LegendItem(label: 'Private Car', color: AppColors.chartCyan),
              _LegendItem(label: 'Bus', color: AppColors.chartGreen),
              _LegendItem(label: 'Van', color: AppColors.chartOrange),
              _LegendItem(label: 'Motorcycle', color: AppColors.chartPurple),
              _LegendItem(label: 'Other', color: AppColors.chartGray),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tourist Trend Card ───────────────────────────────────────────────────────

class _TouristTrendCard extends StatelessWidget {
  const _TouristTrendCard();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final chartHeight = mediaQuery.size.width < 500 ? 150.0 : 200.0;
    
    return _DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(title: 'Tourist Trend (2024)'),
          const SizedBox(height: 16),
          SizedBox(height: chartHeight, child: const _BarChart()),
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

class _RegionBar extends StatefulWidget {
  const _RegionBar({required this.data});
  final _RegionData data;

  @override
  State<_RegionBar> createState() => _RegionBarState();
}

class _RegionBarState extends State<_RegionBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: 0, end: widget.data.ratio).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
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
    final mediaQuery = MediaQuery.of(context);
    final labelWidth = mediaQuery.size.width < 400 ? 60.0 : 70.0;
    
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Row(
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                widget.data.name,
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
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Chart: Donut ─────────────────────────────────────────────────────────────

class _Segment {
  const _Segment({required this.value, required this.color, this.label, this.percentage});
  final double value;
  final Color color;
  final String? label;
  final String? percentage;
}

class _DonutChart extends StatefulWidget {
  const _DonutChart({required this.segments, required this.size});
  final List<_Segment> segments;
  final double size;

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart> with SingleTickerProviderStateMixin {
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

  void _checkHoveredSegment(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    
    final strokeWidth = size.width * 0.17;
    final innerRadius = radius - strokeWidth;
    final outerRadius = radius;
    
    if (distance >= innerRadius && distance <= outerRadius) {
      double angle = math.atan2(dy, dx);
      angle = (angle + math.pi * 2) % (math.pi * 2);
      double startAngle = (math.pi / 2 - angle) % (math.pi * 2);
      
      double accumulatedAngle = 0;
      for (int i = 0; i < widget.segments.length; i++) {
        final segmentAngle = widget.segments[i].value * math.pi * 2;
        if (startAngle >= accumulatedAngle && startAngle <= accumulatedAngle + segmentAngle) {
          if (_hoveredIndex != i) {
            setState(() {
              _hoveredIndex = i;
            });
          }
          return;
        }
        accumulatedAngle += segmentAngle;
      }
    }
    
    if (_hoveredIndex != -1) {
      setState(() {
        _hoveredIndex = -1;
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
          _checkHoveredSegment(localPosition, Size(widget.size, widget.size));
        }
      },
      onExit: (_) {
        setState(() {
          _hoveredIndex = -1;
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _controller.value,
            child: Transform.scale(
              scale: 0.95 + (_controller.value * 0.05),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      painter: _DonutPainter(
                        segments: widget.segments,
                        animationValue: _controller.value,
                        hoveredIndex: _hoveredIndex,
                      ),
                      size: Size(widget.size, widget.size),
                    ),
                    if (_hoveredIndex != -1 && widget.segments[_hoveredIndex].label != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.segments[_hoveredIndex].label!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.segments[_hoveredIndex].percentage!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
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
    final strokeWidth = size.width * 0.17;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    double startAngle = -math.pi / 2;
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final sweepAngle = seg.value * 2 * math.pi * animationValue;
      
      final currentStrokeWidth = (hoveredIndex == i) ? strokeWidth + 4 : strokeWidth;
      final paint = Paint()
        ..color = (hoveredIndex == i) ? seg.color.withOpacity(1.0) : seg.color
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

class _BarChartState extends State<_BarChart> with SingleTickerProviderStateMixin {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const List<double> _values = [
    22.0, 29.0, 11.0, 39.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
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

  void _checkHoveredBar(Offset position, Size size, double availableWidth) {
    const maxVal = 40.0;
    final leftPad = availableWidth < 400 ? 28.0 : 36.0;
    final bottomPad = availableWidth < 400 ? 20.0 : 24.0;
    final chartH = size.height - bottomPad;
    final chartW = size.width - leftPad;
    
    final barW = (chartW / _months.length) * (availableWidth < 500 ? 0.65 : 0.45);
    final gap = chartW / _months.length;
    
    for (int i = 0; i < _months.length; i++) {
      final x = leftPad + gap * i + gap / 2 - barW / 2;
      final barRect = Rect.fromLTWH(x, 0, barW, chartH);
      
      if (barRect.contains(position)) {
        if (_hoveredBarIndex != i && _values[i] > 0) {
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
    final mediaQuery = MediaQuery.of(context);
    final availableWidth = mediaQuery.size.width;
    
    return MouseRegion(
      onHover: (event) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final localPosition = renderBox.globalToLocal(event.position);
          _checkHoveredBar(localPosition, renderBox.size, availableWidth);
        }
      },
      onExit: (_) {
        setState(() {
          _hoveredBarIndex = -1;
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _controller.value,
                child: Transform.scale(
                  scale: 0.95 + (_controller.value * 0.05),
                  child: CustomPaint(
                    painter: _BarPainter(
                      months: _months,
                      values: _values,
                      availableWidth: availableWidth,
                      animationValue: _controller.value,
                      hoveredBarIndex: _hoveredBarIndex,
                    ),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                ),
              );
            },
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
    required this.availableWidth,
    required this.animationValue,
    required this.hoveredBarIndex,
  });
  final List<String> months;
  final List<double> values;
  final double availableWidth;
  final double animationValue;
  final int hoveredBarIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const maxVal = 40.0;
    const yLabels = [0.0, 10.0, 20.0, 30.0, 40.0];
    
    final leftPad = availableWidth < 400 ? 28.0 : 36.0;
    final bottomPad = availableWidth < 400 ? 20.0 : 24.0;
    
    final chartH = size.height - bottomPad;
    final chartW = size.width - leftPad;

    final gridPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 0.5;
    final textStyle = TextStyle(
      color: AppColors.textSubtle,
      fontSize: availableWidth < 400 ? 8 : 10,
    );

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

    final barW = (chartW / months.length) * (availableWidth < 500 ? 0.65 : 0.45);
    final gap = chartW / months.length;

    for (int i = 0; i < months.length; i++) {
      final x = leftPad + gap * i + gap / 2 - barW / 2;
      final animatedHeight = (values[i] / maxVal) * chartH * animationValue;
      final isHovered = hoveredBarIndex == i;

      if (animatedHeight > 0) {
        final rect = Rect.fromLTWH(x, chartH - animatedHeight, barW, animatedHeight);
        
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isHovered
                ? [AppColors.chartPurple, AppColors.chartPurple.withOpacity(0.9)]
                : [AppColors.chartPurple, AppColors.chartPurple.withOpacity(0.5)],
          ).createShader(rect);

        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          paint,
        );

        // Draw tooltip if hovered
        if (isHovered) {
          final tooltipText = '${values[i].toInt()} guests';
          final textPainter = TextPainter(
            text: TextSpan(
              text: tooltipText,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          
          final tooltipX = x + barW / 2 - textPainter.width / 2;
          final tooltipY = chartH - animatedHeight - 22;
          
          if (tooltipY > 0) {
            final tooltipRect = RRect.fromRectAndRadius(
              Rect.fromLTWH(tooltipX - 6, tooltipY - 2, textPainter.width + 12, textPainter.height + 4),
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

      final labelX = x - (availableWidth < 400 ? 2 : 4);
      _drawText(
        canvas,
        months[i],
        Offset(labelX, size.height - (availableWidth < 400 ? 12 : 14)),
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
  bool shouldRepaint(covariant _BarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.hoveredBarIndex != hoveredBarIndex;
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _DashCard extends StatelessWidget {
  const _DashCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 500;
    final padding = isSmallScreen ? const EdgeInsets.all(14) : const EdgeInsets.all(18);
    
    return Container(
      padding: padding,
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
    final mediaQuery = MediaQuery.of(context);
    final fontSize = mediaQuery.size.width < 500 ? 12.0 : 14.0;
    
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textWhite,
        fontSize: fontSize,
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
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 500;
    final spacing = isSmallScreen ? 8.0 : 12.0;
    final fontSize = isSmallScreen ? 10.0 : 11.0;
    
    return Wrap(
      spacing: spacing,
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
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}