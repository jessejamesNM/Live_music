import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/provider_logics/theme_provider/theme_provider.dart';
import 'package:live_music/data/provider_logics/user/user_provider.dart';
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

    // Adaptativos
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double titleFontSize = screenWidth * 0.055; // ~22 en 400px
    double optionFontSize = screenWidth * 0.045; // ~18 en 400px
    double dividerThickness = screenHeight * 0.0013; // ~1 en 750px
    double listPadding = screenWidth * 0.06; // ~24 en 400px

    return Scaffold(
      backgroundColor: colorScheme.primary,
      appBar: AppBar(
        title: Text(
          'Configuración de Tema',
          style: TextStyle(
            color: colorScheme.secondary,
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.secondary,
        centerTitle: true,
        elevation: 0,
      ),
      body: themeProvider.isLoading
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.secondary),
            )
          : ListView(
              padding: EdgeInsets.symmetric(
                  vertical: listPadding, horizontal: listPadding),
              children: [
                _buildThemeOption(
                  context,
                  title: 'Modo Claro',
                  value: AppTheme.light,
                  currentTheme: themeProvider.currentTheme,
                  colorScheme: colorScheme,
                  optionFontSize: optionFontSize,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setTheme(value);
                    }
                  },
                ),
                _buildDivider(colorScheme, dividerThickness),
                _buildThemeOption(
                  context,
                  title: 'Modo Oscuro',
                  value: AppTheme.dark,
                  currentTheme: themeProvider.currentTheme,
                  colorScheme: colorScheme,
                  optionFontSize: optionFontSize,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setTheme(value);
                    }
                  },
                ),
                _buildDivider(colorScheme, dividerThickness),
                _buildThemeOption(
                  context,
                  title: 'Usar configuración del sistema',
                  value: AppTheme.system,
                  currentTheme: themeProvider.currentTheme,
                  colorScheme: colorScheme,
                  optionFontSize: optionFontSize,
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
    required double optionFontSize,
    required ValueChanged<AppTheme?> onChanged,
  }) {
    return Container(
      color: colorScheme.primary,
      child: RadioListTile<AppTheme>(
        title: Text(
          title,
          style: TextStyle(
            color: colorScheme.secondary,
            fontSize: optionFontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        value: value,
        groupValue: currentTheme,
        onChanged: onChanged,
        activeColor: colorScheme.secondary,
        tileColor: colorScheme.primary,
        selectedTileColor: colorScheme.primaryContainer,
        contentPadding: EdgeInsets.symmetric(horizontal: 0),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme, double thickness) {
    return Divider(
      height: thickness * 12,
      thickness: thickness,
      color: colorScheme.secondary.withOpacity(0.1),
    );
  }
}