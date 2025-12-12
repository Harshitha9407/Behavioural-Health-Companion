class ProfileUpdate {
  final String? name;
  final String? phoneNumber;
  final String? gender;
  final int? age;
  final DateTime? dateOfBirth;

  ProfileUpdate({
    this.name,
    this.phoneNumber,
    this.gender,
    this.age,
    this.dateOfBirth,
  });

  factory ProfileUpdate.fromJson(Map<String, dynamic> json) {
    return ProfileUpdate(
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      gender: json['gender'],
      age: json['age'],
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (dateOfBirth != null) 
        'dateOfBirth': dateOfBirth!.toIso8601String().split('T')[0],
    };
  }
}