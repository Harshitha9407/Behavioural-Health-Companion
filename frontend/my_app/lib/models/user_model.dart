// lib/models/user_model.dart

class UserModel {
  final int? userId; // Primary key from MySQL
  final String firebaseUid; // Unique ID from Firebase
  final String email;
  final String name;
  final String? phoneNumber;
  final String? gender;
  final DateTime? dateOfBirth;
  final int age; // NOTE: Required by your DB, must be non-null when created

  UserModel({
    this.userId,
    required this.firebaseUid,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    required this.age,
  });

  // Converts backend JSON (Response) to Flutter object
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as int?,
      firebaseUid: json['firebaseUid'] as String? ?? '', // Often returned in response
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
      age: json['age'] as int? ?? 0,
    );
  }

  // Converts Flutter object to JSON Map (Request) for POST/PUT endpoints
  Map<String, dynamic> toSignUpJson() {
    return {
      // Keys MUST match your Java SignUpRequestDTO
      'email': email,
      'name': name,
      // Pass required fields, omit nullables if they are null
      if (phoneNumber != null && phoneNumber!.isNotEmpty) 'phoneNumber': phoneNumber,
      if (gender != null) 'gender': gender,
      // Format Date to YYYY-MM-DD string for Java LocalDate
      if (dateOfBirth != null)
        'dateOfBirth': dateOfBirth!.toIso8601String().split('T')[0],
      'age': age, // Must be passed as a valid int!
    };
  }
}