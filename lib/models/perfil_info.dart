class PerfilInfo {
  final String username;
  final String email;
  final String city;
  final String language;
  final int coins;
  final int plantsDiscovered;

  PerfilInfo({
    required this.username,
    required this.email,
    required this.city,
    required this.language,
    required this.coins,
    required this.plantsDiscovered,
  });

  factory PerfilInfo.fromJson(Map<String, dynamic> json) {
    return PerfilInfo(
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      coins: (json['coins'] ?? 0) as int,
      plantsDiscovered: (json['plants_discovered'] ?? 0) as int,
    );
  }
}
