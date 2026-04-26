// lib/ui/admin/models/accommodation_models.dart
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