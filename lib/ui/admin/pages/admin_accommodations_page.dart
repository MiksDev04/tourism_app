import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/admin_layout.dart';
import '../widgets/business_details_modal.dart';
import '../models/accommodation_models.dart'; // Add this import

// ─── Sample Data ──────────────────────────────────────────────────────────────

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

  // Make accommodations mutable
  late List<Accommodation> _accommodations;

  @override
  void initState() {
    super.initState();
    // Initialize with sample data
    _accommodations = [
      const Accommodation(
        name: 'Grand Hotel San Pablo',
        type: 'Hotel',
        owner: 'Juan dela Cruz',
        contact: '049-562-1234',
        rooms: 45,
        status: AccommodationStatus.approved,
      ),
      const Accommodation(
        name: 'Sampaloc Lake Resort',
        type: 'Resort',
        owner: 'Pedro Reyes',
        contact: '049-562-5678',
        rooms: 30,
        status: AccommodationStatus.approved,
      ),
      const Accommodation(
        name: 'Casa San Pablo Inn',
        type: 'Inn',
        owner: 'Rosa Mendoza',
        contact: '049-562-9012',
        rooms: 20,
        status: AccommodationStatus.pending,
      ),
      const Accommodation(
        name: "Traveler's Lodge",
        type: 'Inn',
        owner: 'Carlos Bautista',
        contact: '049-562-3456',
        rooms: 15,
        status: AccommodationStatus.rejected,
      ),
      const Accommodation(
        name: 'Paradise Resort & Spa',
        type: 'Resort',
        owner: 'Elena Garcia',
        contact: '049-562-7890',
        rooms: 35,
        status: AccommodationStatus.warning,
      ),
      const Accommodation(
        name: 'Lakeview Boutique Hotel',
        type: 'Hotel',
        owner: 'Roberto Lim',
        contact: '049-562-2345',
        rooms: 25,
        status: AccommodationStatus.pending,
      ),
    ];
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

  // Method to update accommodation status
  void _updateAccommodationStatus(
    Accommodation item,
    AccommodationStatus newStatus,
  ) {
    setState(() {
      final index = _accommodations.indexWhere((a) => a.name == item.name);
      if (index != -1) {
        _accommodations[index] = Accommodation(
          name: item.name,
          type: item.type,
          owner: item.owner,
          contact: item.contact,
          rooms: item.rooms,
          status: newStatus,
        );
      }
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} has been ${newStatus.name}'),
        backgroundColor: newStatus == AccommodationStatus.approved
            ? AppColors.accentGreen
            : AppColors.accentRed,
        duration: const Duration(seconds: 2),
      ),
    );
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
          return SingleChildScrollView(
            padding: EdgeInsets.all(isNarrow ? 16 : 24),
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
                isNarrow
                    ? _AccommodationCardList(
                        rows: _filtered,
                        onStatusUpdate: _updateAccommodationStatus,
                      )
                    : _AccommodationTable(
                        rows: _filtered,
                        onStatusUpdate: _updateAccommodationStatus,
                      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: SingleChildScrollView(
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
  final Function(Accommodation, AccommodationStatus) onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: rows.isEmpty
          ? Column(
              children: [
                _TableHeader(),
                const Divider(color: AppColors.cardBorder, height: 1),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No accommodations found.',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _TableHeader(),
                const Divider(color: AppColors.cardBorder, height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: AppColors.cardBorder, height: 1),
                  itemBuilder: (_, i) => _TableRow(
                    item: rows[i],
                    onStatusUpdate: onStatusUpdate,
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

// ─── Table Row ────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  const _TableRow({required this.item, required this.onStatusUpdate});

  final Accommodation item;
  final Function(Accommodation, AccommodationStatus) onStatusUpdate;

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
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.center,
              child: _ActionButtons(
                status: item.status,
                item: item,
                onStatusUpdate: onStatusUpdate,
              ),
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
  final Function(Accommodation, AccommodationStatus) onStatusUpdate;

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
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) =>
          _AccommodationCard(item: rows[i], onStatusUpdate: onStatusUpdate),
    );
  }
}

class _AccommodationCard extends StatelessWidget {
  const _AccommodationCard({required this.item, required this.onStatusUpdate});

  final Accommodation item;
  final Function(Accommodation, AccommodationStatus) onStatusUpdate;

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
          // Top row: icon + name + status
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
          // Details grid
          _CardDetail(label: 'Type', value: item.type),
          const SizedBox(height: 6),
          _CardDetail(label: 'Owner', value: item.owner),
          const SizedBox(height: 6),
          _CardDetail(label: 'Contact', value: item.contact),
          const SizedBox(height: 6),
          _CardDetail(label: 'Rooms', value: '${item.rooms}'),
          const SizedBox(height: 12),
          // Actions
          _ActionButtons(
            status: item.status,
            item: item,
            onStatusUpdate: onStatusUpdate,
          ),
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

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.status,
    required this.item,
    required this.onStatusUpdate,
  });

  final AccommodationStatus status;
  final Accommodation item;
  final Function(Accommodation, AccommodationStatus) onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    final showApproveReject = status == AccommodationStatus.pending;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View Details button (always shown)
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
              permitNumber: 'SP-HTL-2024-006',
              registrationNumber: 'BIR-2024-LBH006',
              registeredDate: '2024-02-14',
              address: 'Palakpakin Lake Shore, San Pablo City, Laguna',
              phone: item.contact,
              email:
                  '${item.name.toLowerCase().replaceAll(' ', '')}@example.com',
            );

            showBusinessDetailsModal(
              context,
              businessDetails,
              onApprove: showApproveReject
                  ? () {
                      onStatusUpdate(item, AccommodationStatus.approved);
                    }
                  : null,
              onReject: showApproveReject
                  ? () {
                      onStatusUpdate(item, AccommodationStatus.rejected);
                    }
                  : null,
            );
          },
        ),
      ],
    );
  }
}

// Updated _ActionIcon with tooltip and custom color support
class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: color ?? AppColors.textGray, size: 20),
      ),
    );
  }
}
