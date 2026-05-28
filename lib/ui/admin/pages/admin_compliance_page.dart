// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/admin_layout.dart';
import '../../shared/pages/error_page.dart';
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

const _businessStatusOptions = [
  'All Business Statuses',
  'Approved',
  'Warning',
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
  String? _fetchError;
  int? _errorCode;

  String _searchQuery = '';
  String _selectedActivityStatus = 'All Statuses';
  String _selectedBusinessStatus = 'All Business Statuses';
  String _selectedBusinessLine = 'All Types';

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
      _fetchError = null;
      _errorCode = null;
    });
    try {
      final records = await AdminComplianceApi.fetchActivitySummary();
      if (mounted) {
        setState(() {
          _allRecords = records;
          _isLoading = false;
        });
      }
    } on SocketException catch (e) {
      if (mounted) {
        setState(() {
          _fetchError = e.toString();
          _errorCode = 503;
          _isLoading = false;
        });
      }
    } on TimeoutException catch (e) {
      if (mounted) {
        setState(() {
          _fetchError = e.toString();
          _errorCode = 408;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchError = e.toString();
          _errorCode = 500;
          _isLoading = false;
        });
      }
    }
  }

  // ── Status change ──────────────────────────────────────────────────────────

  /// Opens the Manage Status modal for [record].
  void _openActionDialog(BusinessActivityRecord record) {
    showDialog(
      context: context,
      builder: (_) => _StatusChangeDialog(
        record: record,
        onConfirm: (newStatus) => _handleStatusChange(record, newStatus),
      ),
    );
  }

  /// Calls the API and optimistically updates local state.
  Future<void> _handleStatusChange(
    BusinessActivityRecord record,
    BusinessStatusLevel newStatus,
  ) async {
    await AdminComplianceApi.updateBusinessStatus(record.id, newStatus);
    if (mounted) {
      setState(() {
        final idx = _allRecords.indexWhere((r) => r.id == record.id);
        if (idx != -1) {
          _allRecords[idx] = _allRecords[idx].copyWith(businessStatus: newStatus);
        }
      });
    }
  }

  // ── Derived type options (dynamic from data) ───────────────────────────────
  List<String> get _typeOptions {
    final types = _allRecords.expand((r) => r.businessLine).toSet().toList()
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

      if (_selectedBusinessLine != 'All Types' &&
          !r.businessLine.contains(_selectedBusinessLine)) {
        return false;
      }

      if (_selectedBusinessStatus != 'All Business Statuses') {
        final want = switch (_selectedBusinessStatus) {
          'Approved' => BusinessStatusLevel.approved,
          'Warning' => BusinessStatusLevel.warning,
          'Suspended' => BusinessStatusLevel.suspended,
          _ => BusinessStatusLevel.approved,
        };
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
      child: _fetchError != null
          ? ErrorPage(statusCode: _errorCode ?? 500, onRetry: _load)
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isNarrow ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(
                onRefresh: _load,
                totalAccommodations: _pagedRows.length,
              ),
              const SizedBox(height: 20),
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
                selectedType: _selectedBusinessLine,
                typeOptions: _typeOptions,
                onTypeChanged: (v) => setState(() {
                  _selectedBusinessLine = v!;
                  _resetPage();
                }),
              ),
              const SizedBox(height: 14),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryCyan,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                _ComplianceTable(
                  rows: _pagedRows,
                  onAction: _openActionDialog,
                ),
              if (!_isLoading) ...[
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
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.onRefresh,
    required this.totalAccommodations,
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
                'Monitor guest recording activity of registered businesses',
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
                      value: selectedBusinessStatus,
                      items: _businessStatusOptions,
                      onChanged: onBusinessStatusChanged,
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
                  value: selectedBusinessStatus,
                  items: _businessStatusOptions,
                  onChanged: onBusinessStatusChanged,
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
  const _ComplianceTable({
    required this.rows,
    required this.onAction,
  });

  final List<BusinessActivityRecord> rows;
  final ValueChanged<BusinessActivityRecord> onAction;

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
              itemBuilder: (_, i) => _ComplianceRow(
                record: rows[i],
                onAction: onAction,
              ),
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
                Expanded(flex: 3, child: _HeaderCell('Business Line')),
                Expanded(flex: 2, child: _HeaderCell('Business Status')),
                Expanded(flex: 3, child: _HeaderCell('Activity Status')),
                Expanded(flex: 2, child: _HeaderCell('Records')),
                Expanded(flex: 2, child: _HeaderCell('Guests')),
                Expanded(flex: 3, child: _HeaderCell('Last Activity')),
                Expanded(flex: 2, child: _HeaderCell('Action')),
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
  const _ComplianceRow({
    required this.record,
    required this.onAction,
  });

  final BusinessActivityRecord record;
  final ValueChanged<BusinessActivityRecord> onAction;

  String _formatLastActivity(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return '1 day ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
    final years = (diff.inDays / 365).floor();
    return years == 1 ? '1 year ago' : '$years years ago';
  }

  String _formatNumber(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  Widget _buildActionButton() {
    return OutlinedButton.icon(
      onPressed: () => onAction(record),
      icon: const Icon(Icons.manage_accounts_rounded, size: 14),
      label: const Text('Manage', style: TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryCyan,
        side: BorderSide(color: AppColors.primaryCyan.withOpacity(0.4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
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
                            record.businessLineLabel,
                            style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildActionButton(),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _ActivityBadge(status: record.activityStatus),
                    _BusinessStatusBadge(status: record.businessStatus),
                  ],
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
                      _formatLastActivity(record.lastActivity),
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
                  flex: 3,
                  child: Text(
                    record.businessLineLabel,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _BusinessStatusBadge(status: record.businessStatus),
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
                    _formatLastActivity(record.lastActivity),
                    style: TextStyle(
                      color: record.lastActivity != null
                          ? AppColors.textGray
                          : AppColors.textSubtle,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildActionButton(),
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

// ─── Status Change Dialog ─────────────────────────────────────────────────────

class _StatusChangeDialog extends StatefulWidget {
  const _StatusChangeDialog({
    required this.record,
    required this.onConfirm,
  });

  final BusinessActivityRecord record;
  final Future<void> Function(BusinessStatusLevel) onConfirm;

  @override
  State<_StatusChangeDialog> createState() => _StatusChangeDialogState();
}

class _StatusChangeDialogState extends State<_StatusChangeDialog> {
  late BusinessStatusLevel _selected;
  bool _isSaving = false;

  // ── Business rules ─────────────────────────────────────────────────────────

  /// Inactive or No Activity + currently Approved → admin can escalate to Warning.
  bool get _canSetWarning =>
      (widget.record.activityStatus == ActivityStatus.inactive ||
          widget.record.activityStatus == ActivityStatus.noActivity) &&
      widget.record.businessStatus == BusinessStatusLevel.approved;

  /// Currently Warning → admin can revert to Approved.
  bool get _canSetApproved =>
      widget.record.businessStatus == BusinessStatusLevel.warning;

  /// True when at least one action is available.
  bool get _hasAction => _canSetWarning || _canSetApproved;

  @override
  void initState() {
    super.initState();
    // Pre-select the only available target so Confirm works immediately.
    if (_canSetWarning) {
      _selected = BusinessStatusLevel.warning;
    } else if (_canSetApproved) {
      _selected = BusinessStatusLevel.approved;
    } else {
      _selected = widget.record.businessStatus;
    }
  }

  Future<void> _confirm() async {
    if (_selected == widget.record.businessStatus) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isSaving = true);
    await widget.onConfirm(_selected);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.manage_accounts_rounded,
                      color: AppColors.primaryCyan,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage Business Status',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.record.businessName,
                          style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textGray,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 20),

              // ── Current Status Row ─────────────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Current Status',
                    style: TextStyle(color: AppColors.textGray, fontSize: 12),
                  ),
                  const Spacer(),
                  _BusinessStatusBadge(status: widget.record.businessStatus),
                ],
              ),
              const SizedBox(height: 16),

              // ── No-action restriction notice ───────────────────────────────
              if (!_hasAction) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accentOrange.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.accentOrange,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'No status change is available. Warning can only be set for '
                          'Inactive or No Activity businesses, and only when their '
                          'current status is Approved.',
                          style: TextStyle(
                            color: AppColors.accentOrange,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // ── Close only ───────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textGray,
                      side: BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],

              // ── Available action option(s) ─────────────────────────────────
              if (_hasAction) ...[
                const Text(
                  'Available Action',
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),

                // Escalate → Warning
                if (_canSetWarning)
                  _StatusOption(
                    label: 'Set to Warning',
                    description:
                        'Flag this business for attention or follow-up.',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.accentOrange,
                    isSelected: _selected == BusinessStatusLevel.warning,
                    onTap: () => setState(
                      () => _selected = BusinessStatusLevel.warning,
                    ),
                  ),

                // Revert → Approved
                if (_canSetApproved)
                  _StatusOption(
                    label: 'Revert to Approved',
                    description: 'Remove warning and restore good standing.',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.accentGreen,
                    isSelected: _selected == BusinessStatusLevel.approved,
                    onTap: () => setState(
                      () => _selected = BusinessStatusLevel.approved,
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Actions ──────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textGray,
                          side: BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _confirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black54,
                                ),
                              )
                            : const Text(
                                'Confirm',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Option Tile ───────────────────────────────────────────────────────

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.4) : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? color : AppColors.textWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSubtle,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Status Chip ───────────────────────────────────────────────────────

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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
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

// ─── Business Status Badge ────────────────────────────────────────────────────

class _BusinessStatusBadge extends StatelessWidget {
  const _BusinessStatusBadge({required this.status});

  final BusinessStatusLevel status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      BusinessStatusLevel.approved => const _StatusChip(
          color: AppColors.accentGreen,
          label: 'Approved',
          icon: Icons.verified_outlined,
        ),
      BusinessStatusLevel.warning => const _StatusChip(
          color: AppColors.accentOrange,
          label: 'Warning',
          icon: Icons.warning_amber_rounded,
        ),
      BusinessStatusLevel.suspended => const _StatusChip(
          color: AppColors.accentRed,
          label: 'Suspended',
          icon: Icons.block_rounded,
        ),
    };
  }
}