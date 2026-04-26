// ─── Report Models ─────────────────────────────────────────────────────────────

enum ReportStatus { submitted, approved, draft, rejected }

class Report {
  Report({
    required this.business,
    required this.period,
    required this.totalGuests,
    required this.checkIns,
    this.submitted,
    required this.status,
  });

  final String business;
  final String period;
  final int totalGuests;
  final int checkIns;
  final String? submitted;
  ReportStatus status;

  Report copyWith({
    String? business,
    String? period,
    int? totalGuests,
    int? checkIns,
    String? submitted,
    ReportStatus? status,
  }) {
    return Report(
      business: business ?? this.business,
      period: period ?? this.period,
      totalGuests: totalGuests ?? this.totalGuests,
      checkIns: checkIns ?? this.checkIns,
      submitted: submitted ?? this.submitted,
      status: status ?? this.status,
    );
  }
}