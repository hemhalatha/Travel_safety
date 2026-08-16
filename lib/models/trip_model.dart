import 'dart:convert';

/// Represents the lifecycle state of a trip.
enum TripStatus { active, completed, cancelled }

/// Immutable data model for a single trip.
///
/// [id]              — millisecond epoch string, unique per trip.
/// [destination]     — user-entered destination text.
/// [durationMinutes] — expected trip duration in minutes.
/// [startTime]       — when the trip was started.
/// [endTime]         — when the trip was ended (null while active).
/// [status]          — lifecycle state.
class TripModel {
  final String id;
  final String destination;
  final int durationMinutes;
  final DateTime startTime;
  final DateTime? endTime;
  final TripStatus status;

  const TripModel({
    required this.id,
    required this.destination,
    required this.durationMinutes,
    required this.startTime,
    this.endTime,
    required this.status,
  });

  // ── Computed ───────────────────────────────────────────────────────────────

  bool get isActive => status == TripStatus.active;

  /// Elapsed time since the trip started (uses endTime when completed).
  Duration get elapsed =>
      (endTime ?? DateTime.now()).difference(startTime);

  /// Minutes remaining until expected trip end.
  /// Negative when trip is delayed.
  int get remainingMinutes =>
      durationMinutes - DateTime.now().difference(startTime).inMinutes;

  /// True when an active trip has exceeded its expected duration.
  bool get isDelayed =>
      isActive &&
      DateTime.now().difference(startTime).inMinutes > durationMinutes;

  // ── Mutation ───────────────────────────────────────────────────────────────

  TripModel copyWith({
    String? id,
    String? destination,
    int? durationMinutes,
    DateTime? startTime,
    DateTime? endTime,
    TripStatus? status,
  }) =>
      TripModel(
        id: id ?? this.id,
        destination: destination ?? this.destination,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        status: status ?? this.status,
      );

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'destination': destination,
        'durationMinutes': durationMinutes,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'status': status.name,
      };

  factory TripModel.fromMap(Map<String, dynamic> map) => TripModel(
        id: map['id'] as String,
        destination: map['destination'] as String,
        durationMinutes: (map['durationMinutes'] as num).toInt(),
        startTime: DateTime.parse(map['startTime'] as String),
        endTime: map['endTime'] != null
            ? DateTime.parse(map['endTime'] as String)
            : null,
        status: TripStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => TripStatus.completed,
        ),
      );

  String toJson() => jsonEncode(toMap());

  factory TripModel.fromJson(String source) =>
      TripModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
