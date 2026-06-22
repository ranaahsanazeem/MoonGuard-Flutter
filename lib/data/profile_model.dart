import "dart:math" as math;

class Education {
  final String? school;
  final String? grade;

  const Education({this.school, this.grade});

  factory Education.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const Education();
    return Education(
      school: j["school"] as String?,
      grade: j["grade"] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (school != null) "school": school,
        if (grade != null) "grade": grade,
      };
}

class Schedule {
  final String? breakfast;
  final String? study;
  final String? play;
  final String? lunch;
  final String? dinner;
  final String? sleep;

  const Schedule({
    this.breakfast,
    this.study,
    this.play,
    this.lunch,
    this.dinner,
    this.sleep,
  });

  factory Schedule.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const Schedule();
    return Schedule(
      breakfast: j["breakfast"] as String?,
      study: j["study"] as String?,
      play: j["play"] as String?,
      lunch: j["lunch"] as String?,
      dinner: j["dinner"] as String?,
      sleep: j["sleep"] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (breakfast != null) m["breakfast"] = breakfast;
    if (study != null) m["study"] = study;
    if (play != null) m["play"] = play;
    if (lunch != null) m["lunch"] = lunch;
    if (dinner != null) m["dinner"] = dinner;
    if (sleep != null) m["sleep"] = sleep;
    return m;
  }
}

class Profile {
  final String id;
  final String role;
  final String? name;
  final String? phone;
  final String? countryCode;
  final String? imageUrl;
  final String? salary;
  final String? location;
  final String? address;
  final String? fatherName;
  final String? motherName;
  final String? emergencyContact;
  final List<String>? interests;
  final Education? education;
  final int? age;
  final String? gender;
  final List<String>? languages;
  final Schedule? schedule;
  final String? parentKey;
  final String? parentId;
  final bool profileCompleted;
  final int onboardingStep;
  final bool locationTracking;
  final bool activityAlerts;
  final bool studyAlerts;
  final bool sleepAlerts;
  final bool locationSharing;
  final bool learningReminders;
  final bool parentMonitoringAlerts;
  final String? fcmToken;

  const Profile({
    required this.id,
    required this.role,
    this.name,
    this.phone,
    this.countryCode,
    this.imageUrl,
    this.salary,
    this.location,
    this.address,
    this.fatherName,
    this.motherName,
    this.emergencyContact,
    this.interests,
    this.education,
    this.age,
    this.gender,
    this.languages,
    this.schedule,
    this.parentKey,
    this.parentId,
    this.profileCompleted = false,
    this.onboardingStep = 1,
    this.locationTracking = true,
    this.activityAlerts = true,
    this.studyAlerts = true,
    this.sleepAlerts = true,
    this.locationSharing = true,
    this.learningReminders = true,
    this.parentMonitoringAlerts = true,
    this.fcmToken,
  });

  factory Profile.fromRow(Map<String, dynamic> data) {
    return Profile(
      id: data["id"] as String,
      role: data["role"] as String? ?? "parent",
      name: data["name"] as String?,
      phone: data["phone"] as String?,
      countryCode: data["country_code"] as String?,
      imageUrl: data["image_url"] as String?,
      salary: data["salary"] as String?,
      location: data["location"] as String?,
      address: data["address"] as String?,
      fatherName: data["father_name"] as String?,
      motherName: data["mother_name"] as String?,
      emergencyContact: data["emergency_contact"] as String?,
      interests: (data["interests"] as List?)?.cast<String>(),
      education: Education.fromJson(data["education"] as Map<String, dynamic>?),
      age: data["age"] as int?,
      gender: data["gender"] as String?,
      languages: (data["languages"] as List?)?.cast<String>(),
      schedule: Schedule.fromJson(data["schedule"] as Map<String, dynamic>?),
      parentKey: data["parent_key"] as String?,
      parentId: data["parent_id"] as String?,
      profileCompleted: data["profile_completed"] as bool? ?? false,
      onboardingStep: (data["onboarding_step"] as int?) ?? 1,
      locationTracking: data["location_tracking"] as bool? ?? true,
      activityAlerts: data["activity_alerts"] as bool? ?? true,
      studyAlerts: data["study_alerts"] as bool? ?? true,
      sleepAlerts: data["sleep_alerts"] as bool? ?? true,
      locationSharing: data["location_sharing"] as bool? ?? true,
      learningReminders: data["learning_reminders"] as bool? ?? true,
      parentMonitoringAlerts: data["parent_monitoring_alerts"] as bool? ?? true,
      fcmToken: data["fcm_token"] as String?,
    );
  }
}

String generateParentKey() {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  final r = math.Random();
  final b = StringBuffer();
  for (var i = 0; i < 8; i++) {
    b.write(chars[r.nextInt(chars.length)]);
  }
  return b.toString();
}
