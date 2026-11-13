import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.email,
    super.name,
    super.displayName,
    super.avatarUrl,
    super.phone,
    super.address,
    super.nationality,
    super.dateOfBirth,
    super.gender,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        email: json['email'] as String? ?? '',
        name: json['name'] as String?,
        displayName: json['displayName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        nationality: json['nationality'] as String?,
        dateOfBirth: _parseDate(json['dateOfBirth'] as String?),
        gender: Gender.fromApi(json['gender'] as String?),
      );

  /// Body for `PUT /blockbet/infos`; only the fields being changed are included.
  static Map<String, dynamic> updateToJson(ProfileUpdate update) => {
        if (update.displayName != null) 'displayName': update.displayName,
        if (update.avatarUrl != null) 'avatarUrl': update.avatarUrl,
        if (update.phone != null) 'phone': update.phone,
        if (update.address != null) 'address': update.address,
        if (update.nationality != null) 'nationality': update.nationality,
        if (update.dateOfBirth != null) 'dateOfBirth': formatDate(update.dateOfBirth!),
        if (update.gender != null) 'gender': update.gender!.apiValue,
      };

  /// `yyyy-MM-dd`, the format the backend uses for dates.
  static String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
