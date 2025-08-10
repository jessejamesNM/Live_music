import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/provider_logics/theme_provider/theme_provider.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/screens/buttom_navigation_bar.dart';
import 'package:provider/provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final goRouter = GoRouter.of(context);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      appBar: AppBar(
        title: Text(
          'Configuración de Tema',
          style: TextStyle(color: colorScheme.secondary), // ✅ corregido
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.secondary, // ✅ corregido
      ),
      body:
          themeProvider.isLoading
              ? Center(
                child: CircularProgressIndicator(color: colorScheme.secondary),
              )
              : ListView(
                children: [
                  _buildThemeOption(
                    context,
                    title: 'Modo Claro',
                    value: AppTheme.light,
                    currentTheme: themeProvider.currentTheme,
                    colorScheme: colorScheme,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setTheme(value);
                      }
                    },
                  ),
                  _buildDivider(colorScheme),
                  _buildThemeOption(
                    context,
                    title: 'Modo Oscuro',
                    value: AppTheme.dark,
                    currentTheme: themeProvider.currentTheme,
                    colorScheme: colorScheme,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setTheme(value);
                      }
                    },
                  ),
                  _buildDivider(colorScheme),
                  _buildThemeOption(
                    context,
                    title: 'Usar configuración del sistema',
                    value: AppTheme.system,
                    currentTheme: themeProvider.currentTheme,
                    colorScheme: colorScheme,
                    onChanged: (value) {
                      if (value != null) {
                        themeProvider.setTheme(value);
                      }
                    },
                  ),
                ],
              ),
      bottomNavigationBar: BottomNavigationBarWidget(
        userType: userProvider.userType,
        goRouter: goRouter,
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required AppTheme value,
    required AppTheme currentTheme,
    required ColorScheme colorScheme,
    required ValueChanged<AppTheme?> onChanged,
  }) {
    return Container(
      color: colorScheme.primary,
      child: RadioListTile<AppTheme>(
        title: Text(
          title,
          style: TextStyle(
            color: colorScheme.secondary, // ✅ corregido
            fontSize: 16,
          ),
        ),
        value: value,
        groupValue: currentTheme,
        onChanged: onChanged,
        activeColor: colorScheme.secondary,
        tileColor: colorScheme.primary,
        selectedTileColor: colorScheme.primaryContainer,
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      thickness: 1,
      color: colorScheme.secondary.withOpacity(0.1), // ✅ corregido
    );
  }
}
