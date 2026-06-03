class User {
  final String id;
  final String email;
  final String name;
  final String phoneNumber;
  final String role;
  final String? profileImageUrl;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool twoFactorEnabled;
  final Map<String, bool>? notificationSettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    this.twoFactorEnabled = false,
    this.notificationSettings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone'] ?? json['phoneNumber'] ?? 'Not provided',
      role: json['role'] ?? 'OWNER',
      profileImageUrl: json['profileImage'] ?? json['profileImageUrl'],
      isEmailVerified: json['verified'] ?? json['isEmailVerified'] ?? false,
      isPhoneVerified: json['verified'] ?? json['isPhoneVerified'] ?? false,
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      notificationSettings: json['notificationSettings'] != null 
          ? Map<String, bool>.from(json['notificationSettings']) 
          : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'twoFactorEnabled': twoFactorEnabled,
      'notificationSettings': notificationSettings,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? role,
    String? profileImageUrl,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? twoFactorEnabled,
    Map<String, bool>? notificationSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, role: $role)';
  }

  // Helper methods
  bool get isFullyVerified => isEmailVerified && isPhoneVerified;
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  
  String get displayName => name.isNotEmpty ? name : email.split('@')[0];
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }
}
