class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? _userKey;
  String? _userEmail;

  String? get userKey => _userKey;
  String? get userEmail => _userEmail;

  void setUser(String userKey, String userEmail) {
    _userKey = userKey;
    _userEmail = userEmail;
  }

  void clearUser() {
    _userKey = null;
    _userEmail = null;
  }

  bool get isLoggedIn => _userKey != null;
}
