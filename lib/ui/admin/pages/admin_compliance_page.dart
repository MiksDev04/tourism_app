// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/admin_layout.dart';
import '../../../api/admin_compliance_api.dart';
import '../../shared/widgets/paginator.dart';

// ─── Filter Options ───────────────────────────────────────────────────────────

const _activityStatusOptions = [
  'All Statuses',
  'Active',
  'Low Activity',
  'Inactive',
  'No Activity',
];

// ─── Admin Compliance Page ────────────────────────────────────────────────────

class AdminCompliancePage extends StatefulWidget {
  const AdminCompliancePage({super.key});

  @override
  State<AdminCompliancePage> createState() => _AdminCompliancePageState();
}

class _AdminCompliancePageState extends State<AdminCompliancePage> {
  // ── State ──────────────────────────────────────────────────────────────────
  List<BusinessActivityRecord> _allRecords = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  String _selectedActivityStatus = 'All Statuses';
  String _selectedBusinessStatus = 'All Business Statuses';
  String _selectedType = 'All Types';

  int _currentPage = 0;
  int _pageSize = 10;

  static const List<int> _pageSizeOptions = [10, 20, 30];

  final _searchCtrl = TextEditingController();

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final records = await AdminComplianceApi.fetchActivitySummary();
      if (mounted) {
        setState(() {
          _allRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // ── Derived type options (dynamic from data) ───────────────────────────────
  List<String> get _typeOptions {
    final types = _allRecords.map((r) => r.businessType).toSet().toList()
      ..sort();
    return ['All Types', ...types];
  }

  // ── Summary counts ─────────────────────────────────────────────────────────
  int get _activeCount => _allRecords
      .where((r) => r.activityStatus == ActivityStatus.active)
      .length;

  int get _atRiskCount => _allRecords
      .where((r) => r.activityStatus == ActivityStatus.lowActivity)
      .length;

  int get _inactiveCount => _allRecords
      .where(
        (r) =>
            r.activityStatus == ActivityStatus.inactive ||
            r.activityStatus == ActivityStatus.noActivity,
      )
      .length;

  // ── Filtered list ──────────────────────────────────────────────────────────
  List<BusinessActivityRecord> get _filtered {
    return _allRecords.where((r) {
      final q = _searchQuery.toLowerCase();
      if (q.isNotEmpty && !r.businessName.toLowerCase().contains(q)) {
        return false;
      }

      if (_selectedType != 'All Types' && r.businessType != _selectedType) {
        return false;
      }

      if (_selectedBusinessStatus != 'All Business Statuses') {
        final want = _selectedBusinessStatus == 'Warning'
            ? BusinessStatusLevel.warning
            : BusinessStatusLevel.approved;
        if (r.businessStatus != want) return false;
      }

      if (_selectedActivityStatus != 'All Statuses') {
        final target = _activityStatusFromLabel(_selectedActivityStatus);
        if (r.activityStatus != target) return false;
      }

      return true;
    }).toList();
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  int get _totalPages => (_filtered.length / _pageSize).ceil().clamp(1, 999);

  List<BusinessActivityRecord> get _pagedRows {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  void _resetPage() => _currentPage = 0;

  ActivityStatus _activityStatusFromLabel(String label) {
    switch (label) {
      case 'Active':
        return ActivityStatus.active;
      case 'Low Activity':
        return ActivityStatus.lowActivity;
      case 'Inactive':
        return ActivityStatus.inactive;
      case 'No Activity':
      default:
        return ActivityStatus.noActivity;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Compliance',
      selectedIndex: 4,
      onNavSelected: (_) {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isNarrow ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(onRefresh: _load, totalAccommodations: _pagedRows.length),
                const SizedBox(height: 20),
                if (_isLoading)
                  _LoadingState()
                else if (_error != null)
                  _ErrorState(message: _error!, onRetry: _load)
                else ...[
                  _SummaryCards(
                    active: _activeCount,
                    atRisk: _atRiskCount,
                    inactive: _inactiveCount,
                  ),
                  const SizedBox(height: 16),
                  _FilterRow(
                    searchCtrl: _searchCtrl,
                    onSearchChanged: (v) => setState(() {
                      _searchQuery = v;
                      _resetPage();
                    }),
                    selectedActivityStatus: _selectedActivityStatus,
                    onActivityStatusChanged: (v) => setState(() {
                      _selectedActivityStatus = v!;
                      _resetPage();
                    }),
                    selectedBusinessStatus: _selectedBusinessStatus,
                    onBusinessStatusChanged: (v) => setState(() {
                      _selectedBusinessStatus = v!;
                      _resetPage();
                    }),
                    selectedType: _selectedType,
                    typeOptions: _typeOptions,
                    onTypeChanged: (v) => setState(() {
                      _selectedType = v!;
                      _resetPage();
                    }),
                  ),
                  const SizedBox(height: 14),
                  _ComplianceTable(rows: _pagedRows),
                  const SizedBox(height: 12),
                  Paginator(
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                    totalItems: _filtered.length,
                    pageSize: _pageSize,
                    pageSizeOptions: _pageSizeOptions,
                    onPageSizeChanged: (size) => setState(() {
                      _pageSize = size;
                      _currentPage = 0;
                    }),
                    onPageChanged: (p) => setState(() => _currentPage = p),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.onRefresh,
    required this.totalAccommodations
    });

  final VoidCallback onRefresh;
  final int totalAccommodations;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compliance Tracker ($totalAccommodations)',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Monitor guest recording activity of registered establishments',
                style: TextStyle(color: AppColors.textGray, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          color: AppColors.textGray,
          tooltip: 'Refresh',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppColors.cardBorder),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Loading / Error States ───────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.accentGreen,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentRed.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.accentRed,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            'Failed to load compliance data',
            style: const TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(color: AppColors.textGray, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentGreen),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Cards ────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.active,
    required this.atRisk,
    required this.inactive,
  });

  final int active;
  final int atRisk;
  final int inactive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.accentGreen,
            borderColor: AppColors.accentGreen,
            value: '$active',
            label: 'Active',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SummaryCard(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.accentOrange,
            borderColor: AppColors.accentOrange,
            value: '$atRisk',
            label: 'Low Activity',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SummaryCard(
            icon: Icons.cancel_outlined,
            iconColor: AppColors.accentRed,
            borderColor: AppColors.accentRed,
            value: '$inactive',
            label: 'Inactive',
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Row ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.selectedActivityStatus,
    required this.onActivityStatusChanged,
    required this.selectedBusinessStatus,
    required this.onBusinessStatusChanged,
    required this.selectedType,
    required this.typeOptions,
    required this.onTypeChanged,
  });

  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final String selectedActivityStatus;
  final ValueChanged<String?> onActivityStatusChanged;
  final String selectedBusinessStatus;
  final ValueChanged<String?> onBusinessStatusChanged;
  final String selectedType;
  final List<String> typeOptions;
  final ValueChanged<String?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _SearchField(controller: searchCtrl, onChanged: onSearchChanged),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DropdownFilter(
                      value: selectedActivityStatus,
                      items: _activityStatusOptions,
                      onChanged: onActivityStatusChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DropdownFilter(
                      value: selectedActivityStatus,
                      items: _activityStatusOptions,
                      onChanged: onActivityStatusChanged,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              SizedBox(
                height: 38,
                width: 200,
                child: _SearchField(
                  controller: searchCtrl,
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DropdownFilter(
                  value: selectedActivityStatus,
                  items: _activityStatusOptions,
                  onChanged: onActivityStatusChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DropdownFilter(
                  value: selectedType,
                  items: typeOptions,
                  onChanged: onTypeChanged,
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'Search business...',
          hintStyle: TextStyle(color: AppColors.textSubtle, fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSubtle,
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  const _DropdownFilter({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: AppColors.cardBackground,
          iconEnabledColor: AppColors.textGray,
          style: const TextStyle(color: AppColors.textGray, fontSize: 13),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Compliance Table ─────────────────────────────────────────────────────────

class _ComplianceTable extends StatelessWidget {
  const _ComplianceTable({required this.rows});

  final List<BusinessActivityRecord> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const _TableHeader(),
          const Divider(color: AppColors.cardBorder, height: 1),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No records found.',
                style: TextStyle(color: AppColors.textGray),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.cardBorder, height: 1),
              itemBuilder: (_, i) => _ComplianceRow(record: rows[i]),
            ),
        ],
      ),
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [Expanded(child: _HeaderCell('Business / Details'))],
            ),
          );
        } else {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 3, child: _HeaderCell('Business')),
                Expanded(flex: 2, child: _HeaderCell('Type')),
                Expanded(flex: 3, child: _HeaderCell('Activity Status')),
                Expanded(flex: 2, child: _HeaderCell('Records')),
                Expanded(flex: 2, child: _HeaderCell('Guests')),
                Expanded(flex: 3, child: _HeaderCell('Last Activity')),
              ],
            ),
          );
        }
      },
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textGray,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ─── Compliance Row ───────────────────────────────────────────────────────────

class _ComplianceRow extends StatelessWidget {
  const _ComplianceRow({required this.record});

  final BusinessActivityRecord record;

  String formatLastActivity(DateTime? dt) {
    if (dt == null) return '—';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return '1 day ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (diff.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          // ── Mobile ──────────────────────────────────────────────────────────
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.businessName,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.businessType,
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [_ActivityBadge(status: record.activityStatus)],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 12,
                      color: AppColors.textSubtle,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${record.totalRecords} records · ${_formatNumber(record.totalGuests)} guests',
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppColors.textSubtle,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatLastActivity(record.lastActivity),
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          // ── Desktop ─────────────────────────────────────────────────────────
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    record.businessName,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    record.businessType,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _ActivityBadge(status: record.activityStatus),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${record.totalRecords}',
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatNumber(record.totalGuests),
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    formatLastActivity(record.lastActivity),
                    style: TextStyle(
                      color: record.lastActivity != null
                          ? AppColors.textGray
                          : AppColors.textSubtle,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

// ─── Shared Status Chip ───────────────────────────────────────────────────────
// All color/label/icon logic lives inside each badge — no external config needed.

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.color,
    required this.label,
    required this.icon,
  });

  final Color color;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Activity Status Badge ────────────────────────────────────────────────────

class _ActivityBadge extends StatelessWidget {
  const _ActivityBadge({required this.status});

  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ActivityStatus.active => const _StatusChip(
        color: AppColors.accentGreen,
        label: 'Active',
        icon: Icons.check_circle_outline_rounded,
      ),
      ActivityStatus.lowActivity => const _StatusChip(
        color: AppColors.accentOrange,
        label: 'Low Activity',
        icon: Icons.warning_amber_rounded,
      ),
      ActivityStatus.inactive => const _StatusChip(
        color: AppColors.accentRed,
        label: 'Inactive',
        icon: Icons.cancel_outlined,
      ),
      ActivityStatus.noActivity => const _StatusChip(
        color: AppColors.textSubtle,
        label: 'No Activity',
        icon: Icons.remove_circle_outline_rounded,
      ),
    };
  }
}
