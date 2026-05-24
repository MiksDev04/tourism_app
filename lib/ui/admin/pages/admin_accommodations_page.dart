// lib/ui/admin/pages/admin_accommodations_page.dart

// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tourism_app/core/enums/business_enums.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/layouts/admin_layout.dart';
import '../../shared/widgets/paginator.dart';
import '../widgets/business_details_modal.dart';
import '../models/accommodation_models.dart';
import '../../../api/messages_api.dart';
import '../../../core/services/session_service.dart';
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
  final _messagesApi = MessagesApi();

  int _selectedTab = 0;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  int _currentPage = 0;
  int _pageSize = 10;

  static const List<int> _pageSizeOptions = [10, 20, 30];

  List<Accommodation> _accommodations = [];
  bool _isLoading = true;
  String? _error;
  String? _senderId;
  String? _senderName;
  String? _senderEmail;
  String? _senderPhone;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _loadAccommodations();
  }

  Future<void> _loadSession() async {
    final session = SessionService.instance.current ??
        await SessionService.instance.loadAndCache();
    if (!mounted) return;
    setState(() {
      _senderId = session?.userId;
      _senderName = session?.fullName;
      _senderEmail = session?.email;
      _senderPhone = session?.phone;
    });
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

  int get _totalPages => (_filtered.length / _pageSize).ceil().clamp(1, 999);

  int get _clampedPage => _currentPage.clamp(0, _totalPages - 1);

  List<Accommodation> get _pagedRows {
    final start = _clampedPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
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
        result = await _api.approve(item.id, remarks: remarks);
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

      await _sendDecisionLetter(item, newStatus, remarks: remarks);

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

  Future<void> _sendDecisionLetter(
    Accommodation item,
    AccommodationStatus newStatus, {
    String? remarks,
  }) async {
    if (newStatus != AccommodationStatus.approved) {
      return;
    }

    final senderId = _senderId;
    final senderName = _senderName;
    final senderEmail = _senderEmail;
    final senderPhone = _senderPhone;

    if (senderId == null ||
        senderName == null ||
        senderEmail == null ||
        senderPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accommodation was updated, but the decision letter could not be sent because the admin session is missing.'),
          backgroundColor: Color(0xFFFFA000),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final subject = 'Accommodation Application Approved';
    final remarksText = remarks?.trim();
    final remarksSection = remarksText?.isNotEmpty == true
      ? '\n\nRemarks: $remarksText'
      : '';
    final body = '''We’re pleased to let you know your accommodation application has been approved.$remarksSection''';

    final messageType = MessageType.announcement;

    try {
      final letter = buildOfficialMessageLetter(
        recipient: item.name,
        subject: subject,
        messageContent: body,
        senderFullName: senderName,
        senderEmail: senderEmail,
        senderPhone: senderPhone,
        messageType: messageType,
      );

      await _messagesApi.sendToSelected(
        senderId: senderId,
        businessIds: [item.id],
        messageType: messageType,
        subject: subject,
        content: letter,
      );

      unawaited(MessageBadgeController.instance.refresh());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Accommodation was updated, but the decision letter failed to send: $e'),
          backgroundColor: const Color(0xFFFFA000),
          duration: const Duration(seconds: 4),
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
                    onTabSelected: (i) => setState(() {
                      _selectedTab = i;
                      _currentPage = 0;
                    }),
                  ),
                  const SizedBox(height: 14),
                  _SearchBar(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() {
                      _searchQuery = v;
                      _currentPage = 0;
                    }),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isNarrow
                            ? _AccommodationCardList(
                                rows: _pagedRows,
                                onStatusUpdate: _updateStatus,
                              )
                            : _AccommodationTable(
                                rows: _pagedRows,
                                onStatusUpdate: _updateStatus,
                              ),
                        const SizedBox(height: 12),
                        Paginator(
                          currentPage: _clampedPage,
                          totalPages: _totalPages,
                          totalItems: _filtered.length,
                          pageSize: _pageSize,
                          pageSizeOptions: _pageSizeOptions,
                          onPageSizeChanged: (size) => setState(() {
                            _pageSize = size;
                            _currentPage = 0;
                          }),
                          onPageChanged: (page) => setState(() {
                            _currentPage = page;
                          }),
                        ),
                      ],
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Accommodations',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Manage registered accommodation establishments',
                  style: TextStyle(color: AppColors.textGray, fontSize: 13),
                ),
              ),
            ],
          ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (!isNarrow) {
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

        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(tabs.length, (i) {
            final tab = tabs[i];
            final count = countForStatus(tab.status);
            final isActive = selectedTab == i;
            return _FilterChip(
              label: tab.label,
              count: count,
              isActive: isActive,
              onTap: () => onTabSelected(i),
            );
          }),
        );
      },
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
          Expanded(flex: 3, child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: _HeaderCell('Business Name'),
          )),
          Expanded(flex: 2, child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: _HeaderCell('Type'),
          )),
          Expanded(flex: 3, child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: _HeaderCell('Business Line'),
          )),
          Expanded(flex: 2, child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: _HeaderCell('Owner'),
          )),
          Expanded(flex: 2, child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: _HeaderCell('Contact'),
          )),
          Expanded(flex: 1, child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: _HeaderCell('Rooms'),
          )),
          Expanded(flex: 2, child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: _HeaderCell('Status'),
          )),
          Expanded(flex: 2, child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: _HeaderCell('Actions'),
          )),
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
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.businessType.label,
                style: const TextStyle(color: AppColors.textGray, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.businessLineLabel,
                style: const TextStyle(color: AppColors.textGray, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.owner,
                style: const TextStyle(color: AppColors.textGray, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.contact,
                style: const TextStyle(color: AppColors.textGray, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${item.rooms}',
                style: const TextStyle(color: AppColors.textGray, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(status: item.status),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _ActionButtons(item: item, onStatusUpdate: onStatusUpdate),
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
          _CardDetail(label: 'Type', value: item.businessType.label),
          const SizedBox(height: 6),
          _CardDetail(label: 'Business Line', value: item.businessLineLabel),
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
        return _BadgeStyle(label: 'Approved', color: AppColors.accentGreen);
      case AccommodationStatus.pending:
        return _BadgeStyle(label: 'Pending', color: AppColors.accentOrange);
      case AccommodationStatus.rejected:
        return _BadgeStyle(label: 'Rejected', color: AppColors.accentRed);
      case AccommodationStatus.warning:
        return _BadgeStyle(label: 'Warning', color: AppColors.accentOrange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: style.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
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
  const _BadgeStyle({required this.label, required this.color});
  final String label;
  final Color color;
}

String _formatRegisteredDate(String? rawValue) {
  final value = rawValue?.trim() ?? '';
  if (value.isEmpty) return '—';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final local = parsed.toLocal();
  return '${monthNames[local.month - 1]} ${local.day}, ${local.year}';
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.item, required this.onStatusUpdate});

  final Accommodation item;
  final Function(Accommodation, AccommodationStatus, {String? remarks})
  onStatusUpdate;

  Future<void> _showRemarksModal(
    BuildContext context, {
    required AccommodationStatus action,
  }) async {
    final isApprove = action == AccommodationStatus.approved;
    final color = isApprove ? const Color(0xFF00C48C) : const Color(0xFFFF4D6A);
    final icon = isApprove
        ? Icons.check_circle_outline_rounded
        : Icons.cancel_outlined;
    final label = isApprove ? 'Approve' : 'Reject';

    final remarksCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => Material(
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$label Application',
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: AppColors.textGray,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textGray,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.cardBorder, height: 1),
                  const SizedBox(height: 20),

                  // ── Remarks Field ─────────────────────────────────────────
                  const Text(
                    'Remarks',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This will be visible to the business owner.',
                    style: TextStyle(color: AppColors.textSubtle, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: remarksCtrl,
                    maxLines: 4,
                    minLines: 3,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add remarks (optional)...',
                      hintStyle: const TextStyle(
                        color: AppColors.textSubtle,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppColors.cardBorder.withOpacity(0.2),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.cardBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.cardBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: color.withOpacity(0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Buttons ───────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _ModalButton(
                          label: 'Cancel',
                          color: AppColors.textGray,
                          onTap: () => Navigator.of(ctx).pop(false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ModalButton(
                          label: label,
                          color: color,
                          filled: true,
                          onTap: () => Navigator.of(ctx).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final remarks = remarksCtrl.text.trim();
      onStatusUpdate(item, action, remarks: remarks.isEmpty ? null : remarks);
    }

    remarksCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPending = item.status == AccommodationStatus.pending;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── View Details ──────────────────────────────────────────────────
        _ActionIcon(
          icon: Icons.remove_red_eye_outlined,
          tooltip: 'View Details',
          onTap: () {
            showBusinessDetailsModal(
              context,
              BusinessDetails(
                name: item.name,
                tradeName: item.tradeName,
                type: item.businessType.label,
                businessLine: item.businessLineLabel,
                rooms: item.rooms,
                status: item.status,
                owner: item.owner,
                permitNumber: item.permitNumber,
                registrationNumber: item.registrationNumber,
                registeredDate: _formatRegisteredDate(item.createdAt),
                address: item.address,
                street: item.street,
                barangay: item.barangay,
                cityMunicipality: item.cityMunicipality,
                province: item.province,
                region: item.region,
                phone: item.contact,
                email: item.email ?? '—',
                permitFileUrl: item.permitFileUrl,
                validIdUrl: item.validIdUrl,
              ),
            );
          },
        ),

        // ── Approve (pending only) ────────────────────────────────────────
        if (isPending) ...[
          const SizedBox(width: 8),
          _ActionIcon(
            icon: Icons.check_circle_outline_rounded,
            tooltip: 'Approve',
            color: const Color(0xFF00C48C),
            onTap: () => _showRemarksModal(
              context,
              action: AccommodationStatus.approved,
            ),
          ),
          const SizedBox(width: 8),

          // ── Reject (pending only) ─────────────────────────────────────
          _ActionIcon(
            icon: Icons.cancel_outlined,
            tooltip: 'Reject',
            color: const Color(0xFFFF4D6A),
            onTap: () => _showRemarksModal(
              context,
              action: AccommodationStatus.rejected,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Modal Button ─────────────────────────────────────────────────────────────

class _ModalButton extends StatefulWidget {
  const _ModalButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  State<_ModalButton> createState() => _ModalButtonState();
}

class _ModalButtonState extends State<_ModalButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.filled
        ? (_hovered ? widget.color : widget.color.withOpacity(0.85))
        : (_hovered
              ? widget.color.withOpacity(0.15)
              : widget.color.withOpacity(0.08));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.filled
                  ? Colors.transparent
                  : widget.color.withOpacity(_hovered ? 0.5 : 0.25),
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.filled ? Colors.white : widget.color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Action Icon ──────────────────────────────────────────────────────────────

class _ActionIcon extends StatefulWidget {
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
  State<_ActionIcon> createState() => _ActionIconState();
}

class _ActionIconState extends State<_ActionIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.textGray;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip ?? '',
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hovered ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              color: _hovered ? color : color.withOpacity(0.7),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
