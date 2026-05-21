import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum MessageType {
  compliance,
  announcement,
  general;

  /// Matches the Postgres enum values in the `messages` table.
  String get dbValue => name; // 'compliance' | 'announcement' | 'general'

  String get label => switch (this) {
    MessageType.compliance => 'Compliance',
    MessageType.announcement => 'Announcement',
    MessageType.general => 'General',
  };

  String get icon => switch (this) {
    MessageType.compliance => '⚠️',
    MessageType.announcement => '📣',
    MessageType.general => '💬',
  };
}

enum MessageStatus {
  sent,
  read,
  archived;

  String get dbValue => name;
}

// ─── Models ───────────────────────────────────────────────────────────────────

class BusinessSummary {
  const BusinessSummary({required this.id, required this.name, this.status});

  /// UUID from `businesses.id`
  final String id;

  /// `businesses.business_name`
  final String name;

  /// `businesses.status` — useful for showing inactive/pending badges in the dropdown
  final String? status;

  factory BusinessSummary.fromJson(Map<String, dynamic> json) =>
      BusinessSummary(
        id: json['id'] as String,
        name: json['business_name'] as String,
        status: json['status'] as String?,
      );
}

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.businessId,
    required this.messageType,
    required this.subject,
    required this.content,
    required this.status,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.senderName,
  });

  final String id;
  final String senderId;
  final String businessId;
  final MessageType messageType;
  final String subject;
  final String content;
  final MessageStatus status;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  /// Joined from `profiles.full_name` via the `sender` relation.
  final String? senderName;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    senderId: json['sender_id'] as String,
    businessId: json['business_id'] as String,
    messageType: MessageType.values.firstWhere(
      (e) => e.dbValue == json['message_type'],
      orElse: () => MessageType.general,
    ),
    subject: json['subject'] as String,
    content: json['content'] as String,
    status: MessageStatus.values.firstWhere(
      (e) => e.dbValue == json['status'],
      orElse: () => MessageStatus.sent,
    ),
    isRead: json['is_read'] as bool,
    createdAt: DateTime.parse(json['created_at'] as String),
    readAt: json['read_at'] != null
        ? DateTime.parse(json['read_at'] as String)
        : null,
    senderName:
        (json['sender'] as Map<String, dynamic>?)?['full_name'] as String?,
  );
}

// ─── API ──────────────────────────────────────────────────────────────────────

class MessagesApi {
  MessagesApi({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ── Businesses ─────────────────────────────────────────────────────────────

  /// Fetch all non-deleted businesses for the compose dropdown.
  /// Ordered alphabetically by business name.
  Future<List<BusinessSummary>> fetchBusinesses() async {
    final data = await _client
        .from('businesses')
        .select('id, business_name, status')
        .filter('deleted_at', 'is', null)
        .filter('status', 'eq', 'approved')
        .order('business_name', ascending: true);

    return (data as List<dynamic>)
        .map((b) => BusinessSummary.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  Future<String?> fetchReceiverName(String businessId) async {
    final data = await _client
        .from('businesses')
        .select('business_name')
        .filter('deleted_at', 'is', null)
        .filter('status', 'eq', 'approved')
        .eq('id', businessId)
        .order('business_name', ascending: true)
        .limit(1)
        .maybeSingle();

    return data?['business_name'];
  }

  // ── Send ───────────────────────────────────────────────────────────────────

  /// Send a message to a single business.
  /// `senderId` is the admin's `profiles.id`.
  Future<void> sendToOne({
    required String senderId,
    required String businessId,
    required MessageType messageType,
    required String subject,
    required String content,
  }) async {
    await _client.from('messages').insert({
      'sender_id': senderId,
      'business_id': businessId,
      'message_type': messageType.dbValue,
      'subject': subject.trim(),
      'content': content.trim(),
      // status defaults to 'sent', is_read defaults to false in DB
    });
  }

  /// Send the same message to every non-deleted business (bulk insert).
  /// Returns the count of businesses messaged.
  Future<int> sendToAll({
    required String senderId,
    required MessageType messageType,
    required String subject,
    required String content,
  }) async {
    // Fetch all active business IDs
    final businesses = await _client
        .from('businesses')
        .select('id')
        .filter('deleted_at', 'is', null)
        .filter('status', 'eq', 'approved');

    if ((businesses as List).isEmpty) return 0;

    final rows = businesses
        .map(
          (b) => {
            'sender_id': senderId,
            'business_id': b['id'] as String,
            'message_type': messageType.dbValue,
            'subject': subject.trim(),
            'content': content.trim(),
          },
        )
        .toList();

    await _client.from('messages').insert(rows);
    return rows.length;
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  /// Fetch all messages for a specific business (receiver/business-owner view).
  Future<List<Message>> fetchForBusiness(String businessId) async {
    final data = await _client
        .from('messages')
        .select('*, sender:profiles!sender_id(full_name)')
        .eq('business_id', businessId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all messages sent by an admin (sender view).
  Future<List<Message>> fetchSentByAdmin(String adminId) async {
    final data = await _client
        .from('messages')
        .select(
          '*, sender:profiles!sender_id(full_name), business:businesses(business_name)',
        )
        .eq('sender_id', adminId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  /// Mark a single message as read.
  Future<void> markAsRead(String messageId) async {
    await _client
        .from('messages')
        .update({
          'is_read': true,
          'status': MessageStatus.read.dbValue,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', messageId);
  }

  /// Archive a message.
  Future<void> archive(String messageId) async {
    await _client
        .from('messages')
        .update({'status': MessageStatus.archived.dbValue})
        .eq('id', messageId);
  }

  /// Get unread message count for a business (for badge indicators).
  Future<int> unreadCount(String businessId) async {
    final response = await _client
        .from('messages')
        .select('id')
        .eq('business_id', businessId)
        .eq('is_read', false);

    return (response as List).length;
  }
}
