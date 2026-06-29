import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import '../../main/screens/main_shell_screen.dart';

class SessionController extends StatefulWidget {
  const SessionController({super.key});

  @override
  State<SessionController> createState() => _SessionControllerState();
}

class _SessionControllerState extends State<SessionController> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _listenToAuthChanges();
  }

  void _checkAuthState() {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() {
      _isAuthenticated = session != null;
      _isLoading = false;
    });
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (mounted) {
        setState(() {
          _isAuthenticated = session != null;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthenticated) {
      return const LoginScreen();
    }

    return const MainShellScreen();
  }
}
