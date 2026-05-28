import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/session_service.dart';
// ─── Enums ────────────────────────────────────────────────────────────────────

enum MessageType {
  compliance,
  announcement,
  general;

  /// Matches the Postgres enum value in the `messages` table.
  String get dbValue => name;

  String get label => switch (this) {
        MessageType.compliance   => 'Compliance',
        MessageType.announcement => 'Announcement',
        MessageType.general      => 'General',
      };

  String get icon => switch (this) {
        MessageType.compliance   => '⚠️',
        MessageType.announcement => '📣',
        MessageType.general      => '💬',
      };
}

/// Matches the `recipient_status` Postgres enum on `message_recipients`.
enum RecipientStatus {
  unread,
  read,
  archived;

  String get dbValue => name;
}

/// Builds the official tourism-office letter format used by compose message
/// and by automated accommodation decisions.
String buildOfficialMessageLetter({
  required String recipient,
  required String subject,
  required String messageContent,
  required String senderFullName,
  required String senderEmail,
  required String senderPhone,
  required MessageType messageType,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  const months = [
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
  final dateStr = '${months[current.month - 1]} ${current.day}, ${current.year}';
  final typeLabel = switch (messageType) {
    MessageType.compliance => 'COMPLIANCE NOTICE',
    MessageType.announcement => 'ANNOUNCEMENT',
    MessageType.general => 'GENERAL NOTICE',
  };
  final ref = 'MSG-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';

  return '''REPUBLIC OF THE PHILIPPINES
CITY OF SAN PABLO
OFFICE OF TOURISM

$dateStr

To: $recipient
Re: ${subject.isEmpty ? '(no subject)' : subject}

$typeLabel

Dear Establishment Representative,

${messageContent.isEmpty ? '(no content)' : messageContent}

This notice is duly issued by the San Pablo City Tourism Office and is valid even without a handwritten signature, being an official electronic communication of the office.

For questions and concerns, please contact us at $senderEmail or call us at $senderPhone, or visit our office at the San Pablo City Hall.

Respectfully,

$senderFullName
Tourism Officer
San Pablo City Tourism Office

---
This is an official communication from the San Pablo City Tourism Office.
Reference No.: $ref''';
}

/// Shared unread-count cache for business navigation badges.
class MessageBadgeController {
  MessageBadgeController._();

  static final MessageBadgeController instance = MessageBadgeController._();

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  bool _isRefreshing = false;

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final session = await SessionService.instance.loadAndCache();
      final businessId = session?.businessId;

      if (businessId == null) {
        unreadCount.value = 0;
        return;
      }

      final count = await MessagesApi().fetchUnreadCount(businessId);
      unreadCount.value = count;
    } catch (_) {
      unreadCount.value = 0;
    } finally {
      _isRefreshing = false;
    }
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

/// Lightweight business representation used in the compose dropdown.
/// Only approved + warning businesses are eligible as message recipients.
class BusinessSummary {
  const BusinessSummary({
    required this.id,
    required this.name,
    required this.status,
  });

  /// `businesses.id` — UUID used as the FK in `message_recipients`.
  final String id;

  /// `businesses.business_name`
  final String name;

  /// `businesses.status` — used to show status badges in the dropdown
  /// and to guard against sending to ineligible businesses.
  final String status;

  /// Only approved and warning businesses can receive messages.
  bool get isEligible => status == 'approved' || status == 'warning';

  factory BusinessSummary.fromJson(Map<String, dynamic> json) =>
      BusinessSummary(
        id:     json['id']            as String,
        name:   json['business_name'] as String,
        status: json['status']        as String,
      );
}

/// Represents a row from `messages` joined with its sender profile.
/// Used on the admin outbox side.
class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.messageType,
    required this.subject,
    required this.content,
    required this.isBroadcast,
    required this.createdAt,
    this.senderName,
  });

  final String      id;
  final String      senderId;
  final MessageType messageType;
  final String      subject;
  final String      content;

  /// True when the message was sent via "All Businesses".
  /// False when sent to a specific selection.
  final bool        isBroadcast;

  final DateTime    createdAt;

  /// Joined from `profiles.full_name` via the `sender` relation.
  final String?     senderName;

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id:          json['id']          as String,
        senderId:    json['sender_id']   as String,
        messageType: MessageType.values.firstWhere(
          (e) => e.dbValue == json['message_type'],
          orElse: () => MessageType.general,
        ),
        subject:     json['subject']     as String,
        content:     json['content']     as String,
        isBroadcast: json['is_broadcast'] as bool,
        createdAt:   DateTime.parse(json['created_at'] as String),
        senderName:  (json['sender'] as Map<String, dynamic>?)?['full_name']
                         as String?,
      );
}

/// Represents a row from `message_recipients` joined with its parent message.
/// Used on the business inbox side.
class InboxMessage {
  const InboxMessage({
    required this.recipientId,
    required this.messageId,
    required this.businessId,
    required this.status,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    // joined from messages
    required this.messageType,
    required this.subject,
    required this.content,
    required this.isBroadcast,
    required this.sentAt,
    this.senderName,
  });

  // ── message_recipients fields ──────────────────────────────────────────────
  final String          recipientId; // message_recipients.id
  final String          messageId;
  final String          businessId;
  final RecipientStatus status;
  final bool            isRead;
  final DateTime        createdAt;   // when this recipient row was created (= send time)
  final DateTime?       readAt;

  // ── joined from messages ───────────────────────────────────────────────────
  final MessageType messageType;
  final String      subject;
  final String      content;
  final bool        isBroadcast;
  final DateTime    sentAt;      // messages.created_at
  final String?     senderName;

  factory InboxMessage.fromJson(Map<String, dynamic> json) {
    final msg = json['message'] as Map<String, dynamic>;
    return InboxMessage(
      recipientId:  json['id']          as String,
      messageId:    json['message_id']  as String,
      businessId:   json['business_id'] as String,
      status: RecipientStatus.values.firstWhere(
        (e) => e.dbValue == json['status'],
        orElse: () => RecipientStatus.unread,
      ),
      isRead:    json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt:    json['read_at'] != null
                     ? DateTime.parse(json['read_at'] as String)
                     : null,
      messageType: MessageType.values.firstWhere(
        (e) => e.dbValue == msg['message_type'],
        orElse: () => MessageType.general,
      ),
      subject:     msg['subject']      as String,
      content:     msg['content']      as String,
      isBroadcast: msg['is_broadcast'] as bool,
      sentAt:      DateTime.parse(msg['created_at'] as String),
      senderName:  (msg['sender'] as Map<String, dynamic>?)?['full_name']
                       as String?,
    );
  }
}

/// Per-business read state for a single message.
/// Used in the admin delivery report.
class DeliveryReceipt {
  const DeliveryReceipt({
    required this.recipientId,
    required this.businessId,
    required this.businessName,
    required this.businessStatus,
    required this.status,
    required this.isRead,
    this.readAt,
  });

  final String          recipientId;
  final String          businessId;
  final String          businessName;
  final String          businessStatus;
  final RecipientStatus status;
  final bool            isRead;
  final DateTime?       readAt;

  factory DeliveryReceipt.fromJson(Map<String, dynamic> json) {
    final biz = json['business'] as Map<String, dynamic>;
    return DeliveryReceipt(
      recipientId:    json['id']          as String,
      businessId:     json['business_id'] as String,
      businessName:   biz['business_name'] as String,
      businessStatus: biz['status']        as String,
      status: RecipientStatus.values.firstWhere(
        (e) => e.dbValue == json['status'],
        orElse: () => RecipientStatus.unread,
      ),
      isRead: json['is_read'] as bool,
      readAt: json['read_at'] != null
                  ? DateTime.parse(json['read_at'] as String)
                  : null,
    );
  }
}

// ─── API ──────────────────────────────────────────────────────────────────────

class MessagesApi {
  MessagesApi({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ── Businesses ─────────────────────────────────────────────────────────────

  /// Fetches all approved + warning businesses for the compose dropdown.
  /// These are the only statuses eligible to receive messages.
  /// 
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
  Future<List<BusinessSummary>> fetchEligibleBusinesses() async {
    final data = await _client
        .from('businesses')
        .select('id, business_name, status')
        .inFilter('status', ['approved', 'warning'])
        .filter('deleted_at', 'is', null)
        .order('business_name', ascending: true);

    return (data as List<dynamic>)
        .map((b) => BusinessSummary.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  // ── Send ───────────────────────────────────────────────────────────────────

  /// Send a message to a specific selection of businesses.
  /// Inserts one row into `messages`, then one row per business
  /// into `message_recipients`.
  ///
  /// The [businessIds] list should only contain approved/warning IDs —
  /// the UI enforces this, but only eligible businesses will have rows
  /// in `message_recipients` because they were loaded via [fetchEligibleBusinesses].
  Future<String> sendToSelected({
    required String           senderId,
    required List<String>     businessIds,
    required MessageType      messageType,
    required String           subject,
    required String           content,
  }) async {
    assert(businessIds.isNotEmpty, 'businessIds must not be empty');

    // 1. Insert the single canonical message record.
    final msgResult = await _client
        .from('messages')
        .insert({
          'sender_id':    senderId,
          'message_type': messageType.dbValue,
          'subject':      subject.trim(),
          'content':      content.trim(),
          'is_broadcast': false,
        })
        .select('id')
        .single();

    final messageId = msgResult['id'] as String;

    // 2. Bulk insert one recipient row per business.
    final recipients = businessIds
        .map((bizId) => {
              'message_id':  messageId,
              'business_id': bizId,
              // status defaults to 'unread', is_read defaults to false in DB
            })
        .toList();

    await _client.from('message_recipients').insert(recipients);

    return messageId;
  }

  /// Send a broadcast message to all approved + warning businesses.
  /// Snapshots eligible businesses at this exact moment — businesses
  /// registered or approved after this call will NOT see the message.
  ///
  /// Returns the message ID and the count of recipients inserted.
  Future<({String messageId, int recipientCount})> sendToAll({
    required String      senderId,
    required MessageType messageType,
    required String      subject,
    required String      content,
  }) async {
    // 1. Snapshot eligible business IDs right now.
    final businesses = await _client
        .from('businesses')
        .select('id')
        .inFilter('status', ['approved', 'warning'])
        .filter('deleted_at', 'is', null);

    final bizIds = (businesses as List<dynamic>)
        .map((b) => b['id'] as String)
        .toList();

    if (bizIds.isEmpty) return (messageId: '', recipientCount: 0);

    // 2. Insert the single canonical message record.
    final msgResult = await _client
        .from('messages')
        .insert({
          'sender_id':    senderId,
          'message_type': messageType.dbValue,
          'subject':      subject.trim(),
          'content':      content.trim(),
          'is_broadcast': true,
        })
        .select('id')
        .single();

    final messageId = msgResult['id'] as String;

    // 3. Bulk insert one recipient row per eligible business.
    final recipients = bizIds
        .map((bizId) => {
              'message_id':  messageId,
              'business_id': bizId,
            })
        .toList();

    await _client.from('message_recipients').insert(recipients);

    return (messageId: messageId, recipientCount: bizIds.length);
  }

  // ── Admin: Outbox ──────────────────────────────────────────────────────────

  /// Fetches all messages sent by the admin, newest first.
  Future<List<Message>> fetchSentByAdmin(String adminId) async {
    final data = await _client
        .from('messages')
        .select('*, sender:profiles!sender_id(full_name)')
        .eq('sender_id', adminId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the per-business delivery report for a single message.
  /// Shows which businesses have read, not read, or archived the message.
  Future<List<DeliveryReceipt>> fetchDeliveryReport(String messageId) async {
    final data = await _client
        .from('message_recipients')
        .select('*, business:businesses(business_name, status)')
        .eq('message_id', messageId)
        .order('is_read', ascending: true)    // unread first
        .order('business(business_name)', ascending: true);

    return (data as List<dynamic>)
        .map((r) => DeliveryReceipt.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ── Business: Inbox ────────────────────────────────────────────────────────

  /// Fetches all inbox messages for a business, newest first.
  /// Excludes archived messages by default — pass [includeArchived] to show them.
  Future<List<InboxMessage>> fetchInbox(
    String businessId, {
    bool includeArchived = false,
  }) async {
    var query = _client
        .from('message_recipients')
        .select(
          '*, message:messages(*, sender:profiles!sender_id(full_name))',
        )
        .eq('business_id', businessId);

    if (!includeArchived) {
      query = query.neq('status', RecipientStatus.archived.dbValue);
    }

    final data = await query.order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((r) => InboxMessage.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Returns the unread message count for a business (for badge indicators).
  Future<int> fetchUnreadCount(String businessId) async {
    final response = await _client
        .from('message_recipients')
        .select('id')
        .eq('business_id', businessId)
        .eq('is_read', false);

    return (response as List).length;
  }

  // ── Business: Update State ─────────────────────────────────────────────────

  /// Marks a recipient row as read.
  /// Updates `message_recipients` only — `messages` is immutable.
  Future<void> markAsRead(String recipientId) async {
    await _client
        .from('message_recipients')
        .update({
          'is_read': true,
          'status':  RecipientStatus.read.dbValue,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', recipientId)
        .eq('is_read', false); // no-op if already read

    unawaited(MessageBadgeController.instance.refresh());
  }

  /// Archives a recipient row so it no longer appears in the default inbox.
  Future<void> archive(String recipientId) async {
    await _client
        .from('message_recipients')
        .update({'status': RecipientStatus.archived.dbValue})
        .eq('id', recipientId);

    unawaited(MessageBadgeController.instance.refresh());
  }
}
