import "package:latlong2/latlong.dart" show LatLng;

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.parentId,
    required this.name,
    this.age,
    this.deviceLabel,
    this.avatarUrl,
    this.childUserId,
    required this.createdAt,
    this.geofenceLat,
    this.geofenceLng,
    this.geofenceRadiusM,
    this.geofenceEnabled = false,
  });

  final String id;
  final String parentId;
  final String name;
  final int? age;
  final String? deviceLabel;
  final String? avatarUrl;
  final String? childUserId;
  final DateTime createdAt;
  final double? geofenceLat;
  final double? geofenceLng;
  final double? geofenceRadiusM;
  final bool geofenceEnabled;

  factory ChildProfile.fromMap(Map<String, dynamic> m) {
    return ChildProfile(
      id: m["id"] as String,
      parentId: m["parent_id"] as String,
      name: m["name"] as String,
      age: m["age"] as int?,
      deviceLabel: m["device_label"] as String?,
      avatarUrl: m["avatar_url"] as String?,
      childUserId: m["child_user_id"] as String?,
      createdAt: DateTime.parse(m["created_at"] as String),
      geofenceLat: (m["geofence_lat"] as num?)?.toDouble(),
      geofenceLng: (m["geofence_lng"] as num?)?.toDouble(),
      geofenceRadiusM: (m["geofence_radius_m"] as num?)?.toDouble(),
      geofenceEnabled: m["geofence_enabled"] as bool? ?? false,
    );
  }
}

class LocationPoint {
  const LocationPoint({
    required this.id,
    required this.childProfileId,
    required this.position,
    this.accuracyM,
    required this.recordedAt,
  });

  final int id;
  final String childProfileId;
  final LatLng position;
  final double? accuracyM;
  final DateTime recordedAt;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.parentUserId,
    required this.childProfileId,
    required this.senderUserId,
    required this.messageType,
    this.body,
    this.storagePath,
    required this.createdAt,
  });

  final String id;
  final String parentUserId;
  final String childProfileId;
  final String senderUserId;
  final String messageType;
  final String? body;
  final String? storagePath;
  final DateTime createdAt;
}

class BlockedKeyword {
  const BlockedKeyword({
    required this.id,
    required this.parentId,
    this.childProfileId,
    required this.keyword,
    required this.isActive,
  });

  final String id;
  final String parentId;
  final String? childProfileId;
  final String keyword;
  final bool isActive;
}

class BlockedApp {
  const BlockedApp({
    required this.id,
    required this.parentId,
    required this.childProfileId,
    required this.packageName,
    this.appLabel,
    required this.manualBlock,
    required this.blurScreen,
    this.strictPin = true,
  });

  final String id;
  final String parentId;
  final String childProfileId;
  final String packageName;
  final String? appLabel;
  final bool manualBlock;
  final bool blurScreen;
  final bool strictPin;
}

class ParentAlert {
  const ParentAlert({
    required this.id,
    required this.parentId,
    required this.childProfileId,
    required this.kind,
    this.body,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String parentId;
  final String childProfileId;
  final String kind;
  final String? body;
  final bool read;
  final DateTime createdAt;
}

class Routine {
  const Routine({
    required this.id,
    required this.parentId,
    required this.childProfileId,
    required this.kind,
    required this.title,
    this.timeOfDay,
    required this.daysMask,
    required this.isEnabled,
    this.notes,
    this.repeatsDaily = true,
  });

  final String id;
  final String parentId;
  final String childProfileId;
  final String kind;
  final String title;
  final String? timeOfDay;
  final int daysMask;
  final bool isEnabled;
  final String? notes;
  /// When true, local notification repeats daily at [timeOfDay] (if set).
  final bool repeatsDaily;
}
