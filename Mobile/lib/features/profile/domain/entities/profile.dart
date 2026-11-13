import 'package:equatable/equatable.dart';

enum Gender {
  male('MALE', 'Male'),
  female('FEMALE', 'Female'),
  other('OTHER', 'Other');

  const Gender(this.apiValue, this.label);

  /// Value used by the backend API.
  final String apiValue;
  final String label;

  static Gender? fromApi(String? value) {
    for (final g in Gender.values) {
      if (g.apiValue == value) return g;
    }
    return null;
  }
}

class Profile extends Equatable {
  const Profile({
    required this.email,
    this.name,
    this.displayName,
    this.avatarUrl,
    this.phone,
    this.address,
    this.nationality,
    this.dateOfBirth,
    this.gender,
  });

  /// Read-only: identifies the account.
  final String email;
  final String? name;
  final String? displayName;
  final String? avatarUrl;
  final String? phone;
  final String? address;

  /// ISO 3166-1 alpha-2 country code, e.g. `VN`.
  final String? nationality;
  final DateTime? dateOfBirth;
  final Gender? gender;

  @override
  List<Object?> get props =>
      [email, name, displayName, avatarUrl, phone, address, nationality, dateOfBirth, gender];
}

/// Fields to change. `null` means "leave as is": the backend only updates provided fields.
class ProfileUpdate extends Equatable {
  const ProfileUpdate({
    this.displayName,
    this.avatarUrl,
    this.phone,
    this.address,
    this.nationality,
    this.dateOfBirth,
    this.gender,
  });

  final String? displayName;
  final String? avatarUrl;
  final String? phone;
  final String? address;
  final String? nationality;
  final DateTime? dateOfBirth;
  final Gender? gender;

  bool get isEmpty =>
      displayName == null &&
      avatarUrl == null &&
      phone == null &&
      address == null &&
      nationality == null &&
      dateOfBirth == null &&
      gender == null;

  @override
  List<Object?> get props =>
      [displayName, avatarUrl, phone, address, nationality, dateOfBirth, gender];
}
