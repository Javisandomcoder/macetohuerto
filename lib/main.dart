import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:macetohuerto/l10n/app_localizations.dart';
import 'pages/home_page.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  try {
    await notificationService.init();
    // Solicita permisos de notificación al inicio para evitar silencios
    await notificationService.ensurePermissions();
  } catch (error, stackTrace) {
    debugPrint('Notification init failed: ' + error.toString());
    debugPrintStack(stackTrace: stackTrace);
  }
  runApp(const ProviderScope(child: MacetohuertoApp()));
}

class MacetohuertoApp extends StatelessWidget {
  const MacetohuertoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch theme mode from provider
    return Consumer(builder: (context, ref, _) {
      final themeMode = ref.watch(themeModeProvider);
      return MaterialApp(
      title: 'MacetoApp',
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      theme: buildLightTheme(const Color(0xFF2E7D32)),
      darkTheme: buildDarkTheme(const Color(0xFF2E7D32)),
      themeMode: themeMode,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      home: const HomePage(),
    );
    });
  }
}

