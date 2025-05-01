import 'package:shared_preferences/shared_preferences.dart';

class LocalProfileCache {
  static Future<void> saveProfile({
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_email', email);
    if (photoUrl != null) {
      await prefs.setString('profile_photoUrl', photoUrl);
    }
  }

  static Future<Map<String, String>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('profile_name') ?? '',
      'email': prefs.getString('profile_email') ?? '',
      'photoUrl': prefs.getString('profile_photoUrl') ?? '',
    };
  }
}
