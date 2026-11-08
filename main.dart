import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://mtptprbkazfjgjqejfdv.supabase.co', // بدلها بالرابط ديالك
    anonKey: 'sb_publishable_dXsjXwlLihQGlTmo5qs0Rg_vY4sCv4Q', // بدلها بالمفتاح ديالك
  );
  runApp(const MotoApp());
}

class MotoApp extends StatelessWidget {
  const MotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'موتارد',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      // الواجهة من اليمين لليسار
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        return auth.currentSession == null
            ? const LoginScreen()
            : const HomeScreen();
      },
    );
  }
}
