import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/business_layout.dart';
import '../widgets/archive_guest_dialog.dart';
import '../widgets/edit_guest_dialog.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum GuestRecordStatus { active, archived }

class GuestRecord {
  const GuestRecord({
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.guests,
    required this.rooms,
    required this.purpose,
    required this.transport,
    required this.status,
    required this.demographics, // Add this
  });

  final String checkIn;
  final String checkOut;
  final String nights;
  final int guests;
  final int rooms;
  final String purpose;
  final String transport;
  final GuestRecordStatus status;
  final GuestDemographics? demographics; // New field
}

// Add a demographics model
class GuestDemographics {
  const GuestDemographics({
    required this.ageGroups,
    required this.genderDistribution,
    required this.countries,
  });

  final Map<String, int> ageGroups; // e.g., {"18-25": 2, "26-35": 5}
  final Map<String, int> genderDistribution; // e.g., {"Male": 4, "Female": 6}
  final Map<String, int> countries; // e.g., {"USA": 5, "Canada": 3}
}

// ─── Sample Data ──────────────────────────────────────────────────────────────

// ─── Filter Options ───────────────────────────────────────────────────────────

enum _Filter { all, active, archived }

// ─── Guest Records Page ───────────────────────────────────────────────────────

class BusinessGuestRecordsPage extends StatefulWidget {
  const BusinessGuestRecordsPage({super.key});

  @override
  State<BusinessGuestRecordsPage> createState() =>
      _BusinessGuestRecordsPageState();
}

class _BusinessGuestRecordsPageState extends State<BusinessGuestRecordsPage> {
  final List<GuestRecord> _records = [
    GuestRecord(
      checkIn: '2024-04-01',
      checkOut: '2024-04-03',
      nights: '2 nights',
      guests: 10,
      rooms: 4,
      purpose: 'Leisure',
      transport: 'Private Car',
      status: GuestRecordStatus.active,
      demographics: const GuestDemographics(
        ageGroups: {'18-25': 2, '26-35': 5, '36-50': 3},
        genderDistribution: {'Male': 6, 'Female': 4},
        countries: {'USA': 5, 'Canada': 3, 'UK': 2},
      ),
    ),
    // ... other records with demographics
  ];
  _Filter _activeFilter = _Filter.all;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  Future<void> _onArchive(GuestRecord record) async {
    final confirmed = await showArchiveGuestDialog(context);
    if (confirmed != true) return;

    setState(() {
      final idx = _records.indexOf(record);
      if (idx == -1) return;
      _records[idx] = GuestRecord(
        checkIn: record.checkIn,
        checkOut: record.checkOut,
        nights: record.nights,
        guests: record.guests,
        rooms: record.rooms,
        purpose: record.purpose,
        transport: record.transport,
        status: GuestRecordStatus.archived, // ← only this changes
        demographics: const GuestDemographics(
          ageGroups: {'18-25': 2, '26-35': 5, '36-50': 3},
          genderDistribution: {'Male': 6, 'Female': 4},
          countries: {'USA': 5, 'Canada': 3, 'UK': 2},
        ),
      );
    });
  }

  Future<void> _onEdit(GuestRecord record) async {
    final updated = await showEditGuestDialog(context, record: record);
    if (updated == null) return;

    setState(() {
      final idx = _records.indexOf(record);
      if (idx == -1) return;
      _records[idx] = updated; // replace in-place with edited version
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<GuestRecord> get _filtered {
    return _records.where((r) {
      final matchesFilter = switch (_activeFilter) {
        _Filter.all => true,
        _Filter.active => r.status == GuestRecordStatus.active,
        _Filter.archived => r.status == GuestRecordStatus.archived,
      };
      final q = _searchQuery.toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          r.checkIn.contains(q) ||
          r.purpose.toLowerCase().contains(q) ||
          r.transport.toLowerCase().contains(q);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BusinessLayout(
      title: 'Guest Records',
      selectedIndex: 2,
      onNavSelected: (_) {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isNarrow ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(
                  activeFilter: _activeFilter,
                  onFilterChanged: (f) => setState(() => _activeFilter = f),
                  isNarrow: isNarrow,
                ),
                const SizedBox(height: 16),
                _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 14),
                _GuestTable(
                  records: _filtered,
                  isNarrow: isNarrow,
                  onEdit: _onEdit, // ← add
                  onArchive: _onArchive, // ← add
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
  const _PageHeader({
    required this.activeFilter,
    required this.onFilterChanged,
    required this.isNarrow,
  });

  final _Filter activeFilter;
  final ValueChanged<_Filter> onFilterChanged;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final filterRow = _FilterToggle(
      activeFilter: activeFilter,
      onChanged: onFilterChanged,
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_TitleSubtitle(), const SizedBox(height: 12), filterRow],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [_TitleSubtitle(), const Spacer(), filterRow],
    );
  }
}

class _TitleSubtitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guest Records',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'View and manage all guest entries',
          style: TextStyle(color: AppColors.textGray, fontSize: 13),
        ),
      ],
    );
  }
}

// ─── Filter Toggle ────────────────────────────────────────────────────────────

class _FilterToggle extends StatelessWidget {
  const _FilterToggle({required this.activeFilter, required this.onChanged});

  final _Filter activeFilter;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterTab(
            label: 'All',
            isActive: activeFilter == _Filter.all,
            onTap: () => onChanged(_Filter.all),
          ),
          _FilterTab(
            label: 'Active',
            isActive: activeFilter == _Filter.active,
            onTap: () => onChanged(_Filter.active),
          ),
          _FilterTab(
            label: 'Archived',
            isActive: activeFilter == _Filter.archived,
            onTap: () => onChanged(_Filter.archived),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                )
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textGray,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
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
          hintText: 'Search by date or purpose...',
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

// ─── Guest Table ──────────────────────────────────────────────────────────────

// ─── Guest Table ──────────────────────────────────────────────────────────────

class _GuestTable extends StatelessWidget {
  const _GuestTable({
    required this.records,
    required this.isNarrow,
    required this.onEdit,
    required this.onArchive,
  });

  final List<GuestRecord> records;
  final bool isNarrow;
  final ValueChanged<GuestRecord> onEdit;
  final ValueChanged<GuestRecord> onArchive;

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
          if (!isNarrow) _TableHeader(),
          if (!isNarrow) const Divider(color: AppColors.cardBorder, height: 1),
          records.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No records found.',
                      style: TextStyle(color: AppColors.textGray),
                    ),
                  ),
                )
              : Column(
                  children: records.map((r) {
                    return Column(
                      children: [
                        if (isNarrow)
                          _RecordCard(
                            record: r,
                            onEdit: onEdit,
                            onArchive: onArchive,
                          )
                        else
                          _RecordRow(
                            record: r,
                            onEdit: onEdit,
                            onArchive: onArchive,
                          ),
                        if (r != records.last)
                          const Divider(color: AppColors.cardBorder, height: 1),
                      ],
                    );
                  }).toList(),
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: _HeaderCell('Check-in')),
          Expanded(flex: 3, child: _HeaderCell('Check-out')),
          Expanded(flex: 2, child: _HeaderCell('Nights')),
          Expanded(flex: 1, child: _HeaderCell('Guests')),
          Expanded(flex: 1, child: _HeaderCell('Rooms')),
          Expanded(flex: 2, child: _HeaderCell('Purpose')),
          Expanded(flex: 3, child: _HeaderCell('Transport')),
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

// ─── Table Row (wide screens) ─────────────────────────────────────────────────

// ─── Table Row (wide screens) ─────────────────────────────────────────────────

class _RecordRow extends StatefulWidget {
  const _RecordRow({
    required this.record,
    required this.onEdit,
    required this.onArchive,
  });

  final GuestRecord record;
  final ValueChanged<GuestRecord> onEdit;
  final ValueChanged<GuestRecord> onArchive;

  @override
  State<_RecordRow> createState() => _RecordRowState();
}

class _RecordRowState extends State<_RecordRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  r.checkIn,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  r.checkOut,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  r.nights,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${r.guests}',
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${r.rooms}',
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  r.purpose,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  r.transport,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(flex: 2, child: _StatusBadge(status: r.status)),
              Expanded(
                flex: 2,
                child: _ActionButtons(
                  status: r.status,
                  expanded: _expanded,
                  onToggleExpand: () => setState(() => _expanded = !_expanded),
                  onEdit: () => widget.onEdit(r),
                  onArchive: () => widget.onArchive(r),
                ),
              ),
            ],
          ),
        ),
        if (_expanded) _ExpandedDetails(record: r),
      ],
    );
  }
}

// ─── Record Card (narrow screens) ────────────────────────────────────────────

class _RecordCard extends StatefulWidget {
  const _RecordCard({
    required this.record,
    required this.onEdit, // ← add
    required this.onArchive, // ← add
  });

  final GuestRecord record;
  final ValueChanged<GuestRecord> onEdit; // ← add
  final ValueChanged<GuestRecord> onArchive; // ← add

  @override
  _RecordCardState createState() => _RecordCardState();
}

class _RecordCardState extends State<_RecordCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.checkIn,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.checkOut}  •  ${r.nights}',
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: r.status),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _InfoChip(label: 'Guests', value: '${r.guests}'),
              _InfoChip(label: 'Rooms', value: '${r.rooms}'),
              _InfoChip(label: 'Purpose', value: r.purpose),
              _InfoChip(label: 'Transport', value: r.transport),
            ],
          ),
          if (r.status == GuestRecordStatus.active) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _IconBtn(
                  icon: Icons.edit_outlined,
                  onTap: () => widget.onEdit(widget.record),
                ),
                const SizedBox(width: 8),
                _IconBtn(
                  icon: Icons.archive_outlined,
                  onTap: () => widget.onArchive(widget.record),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textGray,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
          if (_expanded) _ExpandedDetails(record: r),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.textSubtle),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: AppColors.textGray),
          ),
        ],
      ),
    );
  }
}

// ─── Expanded Details ─────────────────────────────────────────────────────────

class _ExpandedDetails extends StatelessWidget {
  const _ExpandedDetails({required this.record});
  final GuestRecord record;

  @override
  Widget build(BuildContext context) {
    final demographics = record.demographics;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guest Demographic Breakdown',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          if (demographics != null) ...[
            // Small table format
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Table(
                border: TableBorder.all(
                  color: AppColors.cardBorder,
                  width: 0.5,
                ),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(3),
                },
                children: [
                  // Header row
                  TableRow(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Category',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Details',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Age Groups row
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Age Groups',
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: demographics.ageGroups.entries.map((entry) {
                            return Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 11,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  // Gender row
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Gender',
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: demographics.genderDistribution.entries.map((entry) {
                            return Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 11,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  // Countries row
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Countries',
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: demographics.countries.entries.map((entry) {
                            return Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 11,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const Text(
              'No demographic data available for this entry.',
              style: TextStyle(color: AppColors.textSubtle, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}


class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final GuestRecordStatus status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == GuestRecordStatus.active;
    final color = isActive ? AppColors.accentGreen : AppColors.textGray;
    final label = isActive ? 'active' : 'archived';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.status,
    required this.expanded,
    required this.onToggleExpand,
    required this.onEdit, // ← add
    required this.onArchive, // ← add
  });

  final GuestRecordStatus status;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onEdit; // ← add
  final VoidCallback onArchive; // ← add

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (status == GuestRecordStatus.active) ...[
          _IconBtn(icon: Icons.edit_outlined, onTap: onEdit), // ← was () {}
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.archive_outlined,
            onTap: onArchive,
          ), // ← was () {}
          const SizedBox(width: 8),
        ],
        _IconBtn(
          icon: expanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          onTap: onToggleExpand,
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: AppColors.textGray, size: 17),
    );
  }
}
