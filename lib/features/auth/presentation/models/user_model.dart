class User {
  final String id;
  final String email;
  final String name;
  final String phoneNumber;
  final String role;
  final String? profileImageUrl;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool hasHotel;
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
    required this.hasHotel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Support both snake_case and camelCase API responses
    final String phoneNum =
        json['mobile']?.toString() ??
        json['phone']?.toString() ??
        json['phoneNumber']?.toString() ??
        json['contact_number']?.toString() ??
        '';
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: phoneNum,
      role:
          json['role'] ??
          (json['roles'] is List && (json['roles'] as List).isNotEmpty
              ? (json['roles'] as List).first['name'] ?? 'User'
              : 'User'),
      profileImageUrl:
          json['profile'] ?? json['profileImage'] ?? json['profileImageUrl'],
      isEmailVerified:
          json['email_verified_at'] != null ||
          json['verified'] == true ||
          json['isEmailVerified'] == true,
      isPhoneVerified: json['verified'] ?? json['isPhoneVerified'] ?? false,
      hasHotel: json['hasHotel'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
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
      'hasHotel': hasHotel,
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
    bool? hasHotel,
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
      hasHotel: hasHotel ?? this.hasHotel,
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
}
