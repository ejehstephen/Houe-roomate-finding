class AppConfig {
  // Hardcoded backend URL for all platforms (web, mobile, desktop)
  // Env-based configuration and localhost fallback removed as requested.
  static const String apiBaseUrl = 'https://camp-backend-27sb.onrender.com';

  // TODO: Replace with your actual Supabase URL and Anon Key
  static const String supabaseUrl = 'https://mmzchrpwefipnmodpwor.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_x1TZRUmggwOAgT4xTiBrbg__5Ps0w__';
}
