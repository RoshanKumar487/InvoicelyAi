import 'dart:async';

import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/storage/token_storage.dart';
import 'data/repositories/auth_repository.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/dashboard/data/dashboard_repository.dart';
import 'features/shell/presentation/app_shell.dart';
import 'theme/app_theme.dart';

class InvoicelyApp extends StatefulWidget {
  const InvoicelyApp({super.key});

  @override
  State<InvoicelyApp> createState() => _InvoicelyAppState();
}

class _InvoicelyAppState extends State<InvoicelyApp> {
  late final TokenStorage _tokenStorage;
  late final ApiClient _apiClient;
  late final AuthController _authController;
  late final DashboardRepository _dashboardRepository;

  @override
  void initState() {
    super.initState();
    _tokenStorage = TokenStorage();
    _apiClient = ApiClient(tokenStorage: _tokenStorage);
    _authController = AuthController(
      AuthRepository(apiClient: _apiClient, tokenStorage: _tokenStorage),
    );
    unawaited(_authController.restoreSession());
    _dashboardRepository = DashboardRepository(apiClient: _apiClient);
  }

  @override
  void dispose() {
    _authController.dispose();
    _apiClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _authController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Invoicely AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          home: _authController.isRestoring
              ? const _StartupScreen()
              : _authController.session == null
                  ? AuthScreen(
                      controller: _authController,
                      startupError: _authController.startupError,
                    )
                  : AppShell(
                      session: _authController.session!,
                      onLogout: _authController.logout,
                    apiClient: _apiClient,
                    dashboardRepository: _dashboardRepository,
                  ),
        );
      },
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Restoring your Invoicely session...'),
          ],
        ),
      ),
    );
  }
}
