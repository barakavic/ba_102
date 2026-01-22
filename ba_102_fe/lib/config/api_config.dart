class ApiConfig {
  // Use local network IP so both emulator and physical devices can connect
  static const String baseUrl = "http://192.168.100.132:8080";
  
  static String get transactionsUrl => "$baseUrl/api/transactions";
  static String get categoriesUrl => "$baseUrl/api/categories";
  static String get plansUrl => "$baseUrl/api/plans";
  static String get goalsUrl => "$baseUrl/api/goals";
}
