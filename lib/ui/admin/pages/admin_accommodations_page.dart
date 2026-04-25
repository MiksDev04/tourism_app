import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/admin_layout.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum AccommodationStatus { approved, pending, rejected, warning }

class Accommodation {
  const Accommodation({
    required this.name,
    required this.type,
    required this.owner,
    required this.contact,
    required this.rooms,
    required this.status,
  });

  final String name;
  final String type;
  final String owner;
  final String contact;
  final int rooms;
  final AccommodationStatus status;
}

// ─── Sample Data ──────────────────────────────────────────────────────────────

const _accommodations = [
  Accommodation(
    name: 'Grand Hotel San Pablo',
    type: 'Hotel',
    owner: 'Juan dela Cruz',
    contact: '049-562-1234',
    rooms: 45,
    status: AccommodationStatus.approved,
  ),
  Accommodation(
    name: 'Sampaloc Lake Resort',
    type: 'Resort',
    owner: 'Pedro Reyes',
    contact: '049-562-5678',
    rooms: 30,
    status: AccommodationStatus.approved,
  ),
  Accommodation(
    name: 'Casa San Pablo Inn',
    type: 'Inn',
    owner: 'Rosa Mendoza',
    contact: '049-562-9012',
    rooms: 20,
    status: AccommodationStatus.pending,
  ),
  Accommodation(
    name: "Traveler's Lodge",
    type: 'Inn',
    owner: 'Carlos Bautista',
    contact: '049-562-3456',
    rooms: 15,
    status: AccommodationStatus.rejected,
  ),
  Accommodation(
    name: 'Paradise Resort & Spa',
    type: 'Resort',
    owner: 'Elena Garcia',
    contact: '049-562-7890',
    rooms: 35,
    status: AccommodationStatus.warning,
  ),
  Accommodation(
    name: 'Lakeview Boutique Hotel',
    type: 'Hotel',
    owner: 'Roberto Lim',
    contact: '049-562-2345',
    rooms: 25,
    status: AccommodationStatus.pending,
  ),
];

// ─── Tab Filter Model ─────────────────────────────────────────────────────────

class _FilterTab {
  const _FilterTab({required this.label, this.status});
  final String label;
  final AccommodationStatus? status; // null = All
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
  int _selectedTab = 0;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Accommodations',
      selectedIndex: 1,
      onNavSelected: (_) {},
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(),
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
            Expanded(child: _AccommodationTable(rows: _filtered)),
          ],
        ),
      ),
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
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
    return Row(
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

// ─── Accommodation Table ──────────────────────────────────────────────────────

class _AccommodationTable extends StatelessWidget {
  const _AccommodationTable({required this.rows});

  final List<Accommodation> rows;

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
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text(
                      'No accommodations found.',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  )
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.cardBorder, height: 1),
                    itemBuilder: (_, i) => _TableRow(item: rows[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: const [
          Expanded(flex: 4, child: _HeaderCell('Business Name')),
          Expanded(flex: 2, child: _HeaderCell('Type')),
          Expanded(flex: 3, child: _HeaderCell('Owner')),
          Expanded(flex: 3, child: _HeaderCell('Contact')),
          Expanded(flex: 1, child: _HeaderCell('Rooms')),
          Expanded(flex: 2, child: _HeaderCell('Status')),
          Expanded(flex: 2, child: _HeaderCell('Actions')),
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

// ─── Table Row ────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  const _TableRow({required this.item});

  final Accommodation item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        spacing: 5,
        children: [
          // Business Name with icon
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

          Expanded(flex: 2, child: _ActionButtons(status: item.status)),
        ],
      ),
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
  const _ActionButtons({required this.status});

  final AccommodationStatus status;

  @override
  Widget build(BuildContext context) {
    final showApproveReject = status == AccommodationStatus.pending;

    return Row(
      children: [
        _ActionIcon(icon: Icons.visibility_outlined, onTap: () {}),
        if (showApproveReject) ...[
          const SizedBox(width: 6),
          _ActionIcon(icon: Icons.check_circle_outline_rounded, onTap: () {}),
          const SizedBox(width: 6),
          _ActionIcon(icon: Icons.cancel_outlined, onTap: () {}),
        ],
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: AppColors.textGray, size: 18),
    );
  }
}

// ─── Convenience re-exports for AppColors used in this file ──────────────────

extension _Colors on AppColors {
  static const accentGreen = Color(0xFF00C48C);
  static const accentOrange = Color(0xFFFFB020);
  static const accentRed = Color(0xFFFF4D6A);
}
