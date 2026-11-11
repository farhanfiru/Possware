import 'package:shared_preferences/shared_preferences.dart';

class SupabaseConfig {
  static const String defaultUrl = '';
  static const String defaultAnonKey = '';

  static const String _keyUrl = 'supabase_url';
  static const String _keyAnonKey = 'supabase_anon_key';
  static const String _keyRestaurantName = 'restaurant_name';
  static const String _keyRestaurantAddress = 'restaurant_address';
  static const String _keyRestaurantPhone = 'restaurant_phone';

  static Future<String> getUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUrl) ?? defaultUrl;
  }

  static Future<String> getAnonKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAnonKey) ?? defaultAnonKey;
  }

  static const String defaultRestaurantName = 'Restaurent';
  static const String defaultRestaurantAddress = 'Kerala';
  static const String defaultRestaurantPhone = '+91 123456789';

  static Future<String> getRestaurantName() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_keyRestaurantName);
    if (val != null && val.isNotEmpty && val != 'Delicious Bites Cafe') {
      return val;
    }
    return defaultRestaurantName;
  }

  static Future<String> getRestaurantAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_keyRestaurantAddress);
    if (val != null && val.isNotEmpty && val != '123 Food Street, Downtown') {
      return val;
    }
    return defaultRestaurantAddress;
  }

  static Future<String> getRestaurantPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_keyRestaurantPhone);
    if (val != null && val.isNotEmpty && val != '+91 98765 43210') {
      return val;
    }
    return defaultRestaurantPhone;
  }

  static Future<void> saveConfig({
    required String url,
    required String anonKey,
    String? restaurantName,
    String? restaurantAddress,
    String? restaurantPhone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUrl, url.trim());
    await prefs.setString(_keyAnonKey, anonKey.trim());
    if (restaurantName != null) await prefs.setString(_keyRestaurantName, restaurantName.trim());
    if (restaurantAddress != null) await prefs.setString(_keyRestaurantAddress, restaurantAddress.trim());
    if (restaurantPhone != null) await prefs.setString(_keyRestaurantPhone, restaurantPhone.trim());
  }
}
