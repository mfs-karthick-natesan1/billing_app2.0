import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _businessId;
  bool _isLoading = true;

  bool get isAuthenticated => _isAuthenticated;
  String? get businessId => _businessId;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
    AuthService.authStateChanges.listen((_) {
      _isAuthenticated = AuthService.currentUser != null;
      _businessId = AuthService.businessId;
      notifyListeners();
    });
  }

  Future<void> _init() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await AuthService.loadBusinessId();
      _isAuthenticated = true;
      _businessId = AuthService.businessId;
    }
    _isLoading = false;
    notifyListeners();
  }
}
