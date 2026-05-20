// ─── Report Models ────────────────────────────────────────────────────────────
// Supports Approach 2: Generate → Upload to Supabase Storage → Save reference
//
// Required Supabase migration (run once):
// ─────────────────────────────────────────────────────────────────────────────
// CREATE TYPE report_submission_status AS ENUM
//   ('draft', 'submitted', 'approved', 'rejected');
//
// CREATE TABLE public.reports (
//   id                uuid        NOT NULL DEFAULT gen_random_uuid(),
//   business_id       uuid        NOT NULL REFERENCES public.businesses(id),
//   report_type       varchar     NOT NULL DEFAULT 'DAE-1B',
//   period_month      int         NOT NULL CHECK (period_month BETWEEN 1 AND 12),
//   period_year       int         NOT NULL CHECK (period_year >= 2000),
//   total_guests      int         NOT NULL DEFAULT 0,
//   check_ins         int         NOT NULL DEFAULT 0,
//   file_url          varchar,
//   status            report_submission_status NOT NULL DEFAULT 'submitted',
//   remarks           text,
//   generated_at      timestamptz NOT NULL DEFAULT now(),
//   generated_by      uuid        REFERENCES public.profiles(id),
//   updated_at        timestamptz NOT NULL DEFAULT now(),
//   CONSTRAINT reports_pkey PRIMARY KEY (id),
//   CONSTRAINT reports_unique_period UNIQUE (business_id, period_month, period_year, report_type)
// );
//
// CREATE INDEX idx_reports_business_id   ON public.reports (business_id);
// CREATE INDEX idx_reports_period        ON public.reports (period_year, period_month);
// CREATE INDEX idx_reports_status        ON public.reports (status);
//
// -- Supabase Storage bucket (run in dashboard or via API):
// -- Bucket name: "reports"  |  Public: true  |  Allowed MIME: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
//
// -- Required Postgres RPC for aggregated report data:
// CREATE OR REPLACE FUNCTION get_report_data(
//   p_business_id uuid, p_month int, p_year int
// )
// RETURNS TABLE (
//   country            varchar,
//   residence_category text,
//   sex                text,
//   day                int,
//   total_count        bigint
// )
// LANGUAGE sql SECURITY DEFINER AS $$
//   SELECT
//     gb.country,
//     gb.residence_category::text,
//     gb.sex::text,
//     EXTRACT(DAY FROM gr.check_in)::int AS day,
//     SUM(gb.count)                       AS total_count
//   FROM guest_breakdowns gb
//   JOIN guest_records gr ON gb.guest_record_id = gr.id
//   WHERE gr.business_id = p_business_id
//     AND EXTRACT(MONTH FROM gr.check_in) = p_month
//     AND EXTRACT(YEAR  FROM gr.check_in) = p_year
//     AND gr.is_deleted = false
//     AND gr.status     = 'active'
//   GROUP BY gb.country, gb.residence_category, gb.sex, day;
// $$;
// ─────────────────────────────────────────────────────────────────────────────

// ignore_for_file: constant_identifier_names

enum ReportStatus { submitted, approved, rejected, draft }

extension ReportStatusX on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.submitted: return 'Submitted';
      case ReportStatus.approved:  return 'Approved';
      case ReportStatus.rejected:  return 'Rejected';
      case ReportStatus.draft:     return 'Draft';
    }
  }

  static ReportStatus fromString(String? value) {
    switch (value) {
      case 'submitted': return ReportStatus.submitted;
      case 'approved':  return ReportStatus.approved;
      case 'rejected':  return ReportStatus.rejected;
      default:          return ReportStatus.draft;
    }
  }
}

// ─── Report ───────────────────────────────────────────────────────────────────

class Report {
  final String id;
  final String businessId;
  final String business;

  /// Human-readable period e.g. "April 2024"
  final String period;
  final int periodMonth;
  final int periodYear;

  final int totalGuests;
  final int checkIns;

  /// ISO-8601 date string from generated_at e.g. "2024-05-02"
  final String? submitted;

  final ReportStatus status;
  final String? fileUrl;
  final String? remarks;
  final String reportType;

  const Report({
    required this.id,
    required this.businessId,
    required this.business,
    required this.period,
    required this.periodMonth,
    required this.periodYear,
    required this.totalGuests,
    required this.checkIns,
    this.submitted,
    required this.status,
    this.fileUrl,
    this.remarks,
    this.reportType = 'DAE-1B',
  });

  // ── Deserialisation ──────────────────────────────────────────────────────

  factory Report.fromJson(Map<String, dynamic> json) {
    const monthNames = [
      'January', 'February', 'March', 'April',    'May',      'June',
      'July',    'August',   'September', 'October', 'November', 'December',
    ];

    final month = (json['period_month'] as num).toInt();
    final year  = (json['period_year']  as num).toInt();

    final businessMap = json['businesses'] as Map<String, dynamic>?;

    return Report(
      id:          json['id']          as String,
      businessId:  json['business_id'] as String,
      business:    businessMap?['business_name'] as String? ?? 'Unknown Business',
      period:      '${monthNames[month - 1]} $year',
      periodMonth: month,
      periodYear:  year,
      totalGuests: (json['total_guests'] as num?)?.toInt() ?? 0,
      checkIns:    (json['check_ins']    as num?)?.toInt() ?? 0,
      submitted:   json['generated_at'] != null
          ? (json['generated_at'] as String).substring(0, 10)
          : null,
      status:    ReportStatusX.fromString(json['status'] as String?),
      fileUrl:   json['file_url']    as String?,
      remarks:   json['remarks']     as String?,
      reportType: json['report_type'] as String? ?? 'DAE-1B',
    );
  }

  // ── Mutation helpers ─────────────────────────────────────────────────────

  Report copyWith({
    ReportStatus? status,
    String? fileUrl,
    String? remarks,
  }) {
    return Report(
      id:          id,
      businessId:  businessId,
      business:    business,
      period:      period,
      periodMonth: periodMonth,
      periodYear:  periodYear,
      totalGuests: totalGuests,
      checkIns:    checkIns,
      submitted:   submitted,
      status:      status  ?? this.status,
      fileUrl:     fileUrl  ?? this.fileUrl,
      remarks:     remarks  ?? this.remarks,
      reportType:  reportType,
    );
  }

  @override
  String toString() =>
      'Report($reportType · $business · $period · ${status.label})';
}

// ─── Business Option (for dropdowns) ─────────────────────────────────────────

class BusinessOption {
  final String id;
  final String name;

  const BusinessOption({required this.id, required this.name});

  factory BusinessOption.fromJson(Map<String, dynamic> json) {
    return BusinessOption(
      id:   json['id']            as String,
      name: json['business_name'] as String,
    );
  }

  @override
  String toString() => name;
}

// ─── Review Report Data (passed to the review modal widget) ──────────────────
// NOTE: Update your review_report_modal.dart to accept the new fields
//       reportId, fileUrl, and remarks.

class ReviewReportData {
  final String reportId;
  final String business;
  final String period;
  final int totalGuests;
  final int checkIns;
  final String? submitted;
  final ReportStatus status;
  final String? fileUrl;
  final String? remarks;

  const ReviewReportData({
    required this.reportId,
    required this.business,
    required this.period,
    required this.totalGuests,
    required this.checkIns,
    this.submitted,
    required this.status,
    this.fileUrl,
    this.remarks,
  });

  factory ReviewReportData.fromReport(Report r) {
    return ReviewReportData(
      reportId:    r.id,
      business:    r.business,
      period:      r.period,
      totalGuests: r.totalGuests,
      checkIns:    r.checkIns,
      submitted:   r.submitted,
      status:      r.status,
      fileUrl:     r.fileUrl,
      remarks:     r.remarks,
    );
  }
}