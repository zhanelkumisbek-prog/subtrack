class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final DateTime createdAt;
  final String? currency;
  final bool notificationsEnabled;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    required this.createdAt,
    this.currency = 'USD',
    this.notificationsEnabled = true,
  });

  String get firstName {
    if (displayName == null) return email.split('@').first;
    return displayName!.split(' ').first;
  }

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      phoneNumber: data['phoneNumber'],
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      currency: data['currency'] ?? 'USD',
      notificationsEnabled: data['notificationsEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'currency': currency,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  AppUser copyWith({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? currency,
    bool? notificationsEnabled,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt,
      currency: currency ?? this.currency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
