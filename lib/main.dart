
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: TukangPayBootstrap(),
    ),
  );
}

class TukangPayBootstrap extends StatefulWidget {
  const TukangPayBootstrap({super.key});

  @override
  State<TukangPayBootstrap> createState() =>
      _TukangPayBootstrapState();
}

class _TukangPayBootstrapState
    extends State<TukangPayBootstrap> {

  bool _loading = true;
  String? _error;

  GoRouter? _router;
  AuthRefreshNotifier? _authNotifier;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // ==========================================
  // INITIALIZE APPLICATION
  // ==========================================

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final url = SupabaseConfig.supabaseUrl.trim();
      final key = SupabaseConfig.supabaseKey.trim();

      debugPrint('================================');
      debugPrint('TUKANGPAY INITIALIZATION');
      debugPrint('SUPABASE URL: ${url.isEmpty ? "EMPTY" : "OK"}');
      debugPrint('SUPABASE KEY: ${key.isEmpty ? "EMPTY" : "OK"}');
      debugPrint('================================');

      // Validate Supabase configuration
      if (url.isEmpty || key.isEmpty) {
        throw Exception(
          'Supabase URL atau Publishable Key belum diatur.',
        );
      }

      final uri = Uri.tryParse(url);

      if (uri == null ||
          !uri.hasScheme ||
          !uri.hasAuthority ||
          (uri.scheme != 'https' && uri.scheme != 'http')) {
        throw Exception('Format Supabase URL tidak valid.');
      }

      // Initialize Indonesian date format
      await initializeDateFormatting('id_ID', null);

      // Initialize Supabase
      await Supabase.initialize(
        url: url,
        publishableKey: key,
      );

      debugPrint('SUPABASE INITIALIZED SUCCESSFULLY');

      if (!mounted) return;

      // Initialize authentication listener
      _authNotifier = AuthRefreshNotifier();

      // Initialize application router
      _router = createAppRouter(_authNotifier!);

      setState(() {
        _loading = false;
        _error = null;
      });

    } catch (e, stackTrace) {
      debugPrint('TUKANGPAY INITIALIZATION ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ==========================================
  // DISPOSE
  // ==========================================

  @override
  void dispose() {
    _router?.dispose();
    _authNotifier?.dispose();

    super.dispose();
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {

    // LOADING SCREEN
    if (_loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Menyiapkan TukangPay...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ERROR SCREEN
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 64,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Gagal Menjalankan TukangPay',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    SelectableText(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _initializeApp,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // MAIN APPLICATION
    return TukangPayApp(
      router: _router!,
    );
  }
}

// ==========================================
// TUKANGPAY APPLICATION
// ==========================================

class TukangPayApp extends StatelessWidget {
  final GoRouter router;

  const TukangPayApp({
    super.key,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'daywork',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
