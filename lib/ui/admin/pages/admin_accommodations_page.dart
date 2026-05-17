// lib/ui/admin/pages/admin_accommodations_page.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/admin_layout.dart';
import '../widgets/business_details_modal.dart';
import '../models/accommodation_models.dart';
import '../../../api/admin_accommodation_api.dart';

class _FilterTab {
  const _FilterTab({required this.label, this.status});
  final String label;
  final AccommodationStatus? status;
}

const _filterTabs = [
  _FilterTab(label: 'All'),
  _FilterTab(label: 'Pending', status: AccommodationStatus.pending),
  _FilterTab(label: 'Approved', status: AccommodationStatus.approved),
  _FilterTab(label: 'Rejected', status: AccommodationStatus.rejected),
  _FilterTab(label: 'Warning', status: AccommodationStatus.warning),
];

// ─── Accommodations Page ──────────────────────────────────────────────────────

class AdminAccommodationsPage extends StatefulWidget {
  const AdminAccommodationsPage({super.key});

  @override
  State<AdminAccommodationsPage> createState() =>
      _AdminAccommodationsPageState();
}

class _AdminAccommodationsPageState extends State<AdminAccommodationsPage> {
  final _api = AdminAccommodationApi();

  int _selectedTab = 0;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  List<Accommodation> _accommodations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccommodations();
  }

  Future<void> _loadAccommodations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final data = await _api.fetchAll();
    if (!mounted) return;
    setState(() {
      _accommodations = data;
      _isLoading = false;
    });
  }

  List<Accommodation> get _filtered {
    final tabStatus = _filterTabs[_selectedTab].status;
    return _accommodations.where((a) {
      final matchesTab = tabStatus == null || a.status == tabStatus;
      final q = _searchQuery.toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          a.name.toLowerCase().contains(q) ||
          a.owner.toLowerCase().contains(q);
      return matchesTab && matchesSearch;
    }).toList();
  }

  int _countForStatus(AccommodationStatus? status) => status == null
      ? _accommodations.length
      : _accommodations.where((a) => a.status == status).length;

  Future<void> _updateStatus(
    Accommodation item,
    AccommodationStatus newStatus, {
    String? remarks,
  }) async {
    AccommodationResult result;

    switch (newStatus) {
      case AccommodationStatus.approved:
        result = await _api.approve(item.id);
        break;
      case AccommodationStatus.rejected:
        result = await _api.reject(item.id, remarks: remarks);
        break;
      case AccommodationStatus.warning:
        result = await _api.flag(item.id, remarks: remarks);
        break;
      default:
        return;
    }

    if (!mounted) return;

    if (result.success) {
      setState(() {
        final index = _accommodations.indexWhere((a) => a.id == item.id);
        if (index != -1) {
          _accommodations[index] = item.copyWith(status: newStatus);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} has been ${newStatus.name}.'),
          backgroundColor: newStatus == AccommodationStatus.approved
              ? const Color(0xFF00C48C)
              : const Color(0xFFFF4D6A),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Something went wrong.'),
          backgroundColor: const Color(0xFFFF4D6A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Accommodations',
      selectedIndex: 1,
      onNavSelected: (_) {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;
          return RefreshIndicator(
            onRefresh: _loadAccommodations,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isNarrow ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeader(onRefresh: _loadAccommodations),
                  const SizedBox(height: 20),
                  _FilterTabBar(
                    selectedTab: _selectedTab,
                    tabs: _filterTabs,
                    countForStatus: _countForStatus,
                    onTabSelected: (i) => setState(() => _selectedTab = i),
                  ),
                  const SizedBox(height: 14),
                  _SearchBar(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 14),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.accentRed),
                        ),
                      ),
                    )
                  else
                    isNarrow
                        ? _AccommodationCardList(
                            rows: _filtered,
                            onStatusUpdate: _updateStatus,
                          )
                        : _AccommodationTable(
                            rows: _filtered,
                            onStatusUpdate: _updateStatus,
                          ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accommodations',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Manage registered accommodation establishments',
              style: TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ],
        ),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textGray),
          tooltip: 'Refresh',
        ),
      ],
    );
  }
}

// ─── Filter Tab Bar ───────────────────────────────────────────────────────────

class _FilterTabBar extends StatelessWidget {
  const _FilterTabBar({
    required this.selectedTab,
    required this.tabs,
    required this.countForStatus,
    required this.onTabSelected,
  });

  final int selectedTab;
  final List<_FilterTab> tabs;
  final int Function(AccommodationStatus?) countForStatus;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final count = countForStatus(tab.status);
          final isActive = selectedTab == i;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _FilterChip(
              label: tab.label,
              count: count,
              isActive: isActive,
              onTap: () => onTabSelected(i),
            ),
          );
        }),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                )
              : null,
          color: isActive ? null : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textGray,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.25)
                    : AppColors.cardBorder,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textGray,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textWhite, fontSize: 13.5),
        decoration: const InputDecoration(
          hintText: 'Search by name or owner...',
          hintStyle: TextStyle(color: AppColors.textSubtle, fontSize: 13.5),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSubtle,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }
}

// ─── Accommodation Table (wide screens) ──────────────────────────────────────

class _AccommodationTable extends StatelessWidget {
  const _AccommodationTable({required this.rows, required this.onStatusUpdate});

  final List<Accommodation> rows;
  final Function(Accommodation, AccommodationStatus, {String? remarks})
  onStatusUpdate;

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
          _TableHeader(),
          const Divider(color: AppColors.cardBorder, height: 1),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No accommodations found.',
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
              itemBuilder: (_, i) =>
                  _TableRow(item: rows[i], onStatusUpdate: onStatusUpdate),
            ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 4, child: _HeaderCell('Business Name')),
          Expanded(flex: 2, child: _HeaderCell('Type')),
          Expanded(flex: 3, child: _HeaderCell('Owner')),
          Expanded(flex: 3, child: _HeaderCell('Contact')),
          Expanded(flex: 1, child: _HeaderCell('Rooms')),
          Expanded(flex: 2, child: _HeaderCell('Status')),
          Expanded(flex: 1, child: _HeaderCell('Actions')),
        ],
      ),
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

class _TableRow extends StatelessWidget {
  const _TableRow({required this.item, required this.onStatusUpdate});

  final Accommodation item;
  final Function(Accommodation, AccommodationStatus, {String? remarks})
  onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryCyan.withOpacity(0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: AppColors.primaryCyan,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.type,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item.owner,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item.contact,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.rooms}',
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ),
          Expanded(flex: 2, child: _StatusBadge(status: item.status)),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.center,
              child: _ActionButtons(item: item, onStatusUpdate: onStatusUpdate),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Accommodation Card List (narrow screens) ─────────────────────────────────

class _AccommodationCardList extends StatelessWidget {
  const _AccommodationCardList({
    required this.rows,
    required this.onStatusUpdate,
  });

  final List<Accommodation> rows;
  final Function(Accommodation, AccommodationStatus, {String? remarks})
  onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No accommodations found.',
          style: TextStyle(color: AppColors.textGray),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) =>
          _AccommodationCard(item: rows[i], onStatusUpdate: onStatusUpdate),
    );
  }
}

class _AccommodationCard extends StatelessWidget {
  const _AccommodationCard({required this.item, required this.onStatusUpdate});

  final Accommodation item;
  final Function(Accommodation, AccommodationStatus, {String? remarks})
  onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryCyan.withOpacity(0.2),
                  ),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.primaryCyan,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 12),
          _CardDetail(label: 'Type', value: item.type),
          const SizedBox(height: 6),
          _CardDetail(label: 'Owner', value: item.owner),
          const SizedBox(height: 6),
          _CardDetail(label: 'Contact', value: item.contact),
          const SizedBox(height: 6),
          _CardDetail(label: 'Rooms', value: '${item.rooms}'),
          const SizedBox(height: 12),
          _ActionButtons(item: item, onStatusUpdate: onStatusUpdate),
        ],
      ),
    );
  }
}

class _CardDetail extends StatelessWidget {
  const _CardDetail({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSubtle,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textGray, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final AccommodationStatus status;

  static _BadgeStyle _styleFor(AccommodationStatus s) {
    switch (s) {
      case AccommodationStatus.approved:
        return _BadgeStyle(
          label: 'Approved',
          dot: AppColors.accentGreen,
          bg: AppColors.accentGreen,
          text: AppColors.accentGreen,
        );
      case AccommodationStatus.pending:
        return _BadgeStyle(
          label: 'Pending',
          dot: AppColors.accentOrange,
          bg: AppColors.accentOrange,
          text: AppColors.accentOrange,
        );
      case AccommodationStatus.rejected:
        return _BadgeStyle(
          label: 'Rejected',
          dot: AppColors.accentRed,
          bg: AppColors.accentRed,
          text: AppColors.accentRed,
        );
      case AccommodationStatus.warning:
        return _BadgeStyle(
          label: 'Warning',
          dot: AppColors.accentOrange,
          bg: AppColors.accentOrange,
          text: AppColors.accentOrange,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.bg.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.bg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: style.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              color: style.text,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeStyle {
  const _BadgeStyle({
    required this.label,
    required this.dot,
    required this.bg,
    required this.text,
  });
  final String label;
  final Color dot;
  final Color bg;
  final Color text;
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.item, required this.onStatusUpdate});

  final Accommodation item;
  final Function(Accommodation, AccommodationStatus, {String? remarks})
  onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    final showApproveReject = item.status == AccommodationStatus.pending;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          icon: Icons.remove_red_eye_outlined,
          tooltip: 'View Details',
          onTap: () {
            final businessDetails = BusinessDetails(
              name: item.name,
              type: item.type,
              rooms: item.rooms,
              status: item.status,
              owner: item.owner,
              permitNumber: item.permitNumber,
              registrationNumber: item.registrationNumber,
              registeredDate: item.createdAt ?? '—',
              address: item.address,
              phone: item.contact,
              email: '—',
            );

            showBusinessDetailsModal(
              context,
              businessDetails,
              onApprove: showApproveReject
                  ? () => onStatusUpdate(item, AccommodationStatus.approved)
                  : null,
              onReject: showApproveReject
                  ? () => onStatusUpdate(item, AccommodationStatus.rejected)
                  : null,
            );
          },
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: AppColors.textGray, size: 20),
      ),
    );
  }
}
