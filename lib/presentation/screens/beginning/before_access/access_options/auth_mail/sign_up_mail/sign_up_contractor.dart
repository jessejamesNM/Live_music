// -----------------------------------------------------------------------------
// Fecha de creación: 22 de abril de 2025
// Autor: KingdomOfJames
//
// Descripción: Esta pantalla permite el registro de un contratista, solicitando
// nombre, apellido, correo electrónico y contraseña. Se valida que todos los
// campos estén completos, que el correo electrónico tenga un formato válido y
// que la contraseña cumpla con ciertos requisitos de seguridad (longitud mínima,
// caracteres en mayúsculas y minúsculas, números y caracteres especiales).
//
// Recomendaciones:
// - Asegúrate de que todos los campos sean validados antes de enviar la solicitud.
// - Considera agregar validaciones más avanzadas para el correo electrónico (como
//   verificar la existencia del dominio).
// - Asegúrate de manejar posibles errores correctamente, mostrando mensajes
//   claros al usuario.
//
// Características:
// - Interfaz limpia y sencilla, con campos de texto para la entrada de datos.
// - Validación de la contraseña en tiempo real, mostrando los requisitos cumplidos.
// - Mensajes de error para campos vacíos, correo no válido o contraseña incorrecta.
// - Botón de registro que realiza la acción de registro una vez validados los datos.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:live_music/data/model/global_variables.dart';
import 'package:live_music/data/repositories/providers_repositories/user_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

class RegisterContractorMailScreen extends StatefulWidget {
  @override
  _RegisterContractorMailScreenState createState() =>
      _RegisterContractorMailScreenState();
}

class _RegisterContractorMailScreenState
    extends State<RegisterContractorMailScreen> {
  bool isLoading = false;
  String errorMessage = "";
  Map<String, bool> passwordValidation = {};
  bool _obscurePassword = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    passwordValidation = {
      AppStrings.passwordLengthReq: false,
      AppStrings.passwordUppercaseReq: false,
      AppStrings.passwordLowercaseReq: false,
      AppStrings.passwordNumberReq: false,
      AppStrings.passwordSpecialCharReq: false,
    };
    passwordController.addListener(_updatePasswordValidation);
  }

  @override
  void dispose() {
    passwordController.removeListener(_updatePasswordValidation);
    super.dispose();
  }

  void _updatePasswordValidation() {
    setState(() {
      passwordValidation = isPasswordValid(passwordController.text);
    });
  }

  bool isEmailValid(String email) => emailPattern.hasMatch(email);

  Map<String, bool> isPasswordValid(String password) {
    return {
      AppStrings.passwordLengthReq: password.length >= 8,
      AppStrings.passwordUppercaseReq: password.contains(RegExp(r'[A-Z]')),
      AppStrings.passwordLowercaseReq: password.contains(RegExp(r'[a-z]')),
      AppStrings.passwordNumberReq: password.contains(RegExp(r'[0-9]')),
      AppStrings.passwordSpecialCharReq: password.contains(RegExp(r'[^a-zA-Z0-9]')),
    };
  }

  Future<void> _handleRegistration() async {
    final name = nameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = AppStrings.emptyFieldsError);
      return;
    }

    if (!isEmailValid(email)) {
      setState(() => errorMessage = AppStrings.invalidEmailError);
      return;
    }

    if (!passwordValidation.values.every((v) => v)) {
      setState(() => errorMessage = AppStrings.passwordRequirementsError);
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final userRepository = UserRepository(sharedPreferences);
      final role = AppStrings.contractor;

      final errorMsg = await userRepository.registerUser(
        email,
        password,
        role,
        name,
        lastName,
      );

      if (errorMsg == null) {
        if (mounted) context.go(AppStrings.waitingConfirmScreenRoute);
      } else {
        setState(() => errorMessage = errorMsg);
      }
    } catch (e) {
      debugPrint('Error en registro: $e');
      setState(() => errorMessage = AppStrings.unexpectedError);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    // Medidas adaptativas según pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final horizontalPadding = screenWidth * 0.06;
    final verticalSpacing = screenHeight * 0.02;
    final titleFontSize = screenWidth * 0.065;
    final textFontSize = screenWidth * 0.045;
    final iconSize = screenWidth * 0.06;
    final textFieldVerticalPadding = screenHeight * 0.018;
    final textFieldHorizontalPadding = screenWidth * 0.04;
    final borderRadius = screenWidth * 0.035;
    final buttonHeight = screenHeight * 0.065;
    final passwordIconSize = screenWidth * 0.055;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: verticalSpacing),
              IconButton(
                icon: Icon(Icons.arrow_back, size: iconSize),
                color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                onPressed: () => context.pop(),
              ),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppStrings.signUp,
                    style: TextStyle(
                      color:
                          colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: verticalSpacing * 1.5),

              _buildFormFields(
                colorScheme: colorScheme,
                borderRadius: borderRadius,
                verticalPadding: textFieldVerticalPadding,
                horizontalPadding: textFieldHorizontalPadding,
                fontSize: textFontSize,
                passwordIconSize: passwordIconSize,
                verticalSpacing: verticalSpacing,
              ),

              SizedBox(height: verticalSpacing),

              _buildRegisterButton(
                colorScheme: colorScheme,
                buttonHeight: buttonHeight,
                borderRadius: borderRadius,
              ),

              if (errorMessage.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: verticalSpacing / 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      errorMessage,
                      style: TextStyle(
                        color: colorScheme[AppStrings.redColor] ?? Colors.red,
                        fontSize: textFontSize * 0.9,
                      ),
                    ),
                  ),
                ),

              SizedBox(height: verticalSpacing),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppStrings.password,
                  style: TextStyle(
                    color:
                        colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                    fontSize: textFontSize * 0.9,
                  ),
                ),
              ),
              SizedBox(height: verticalSpacing * 0.5),
              _buildPasswordRequirements(
                colorScheme: colorScheme,
                fontSize: textFontSize * 0.8,
                iconSize: passwordIconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields({
    required Map<String, Color?> colorScheme,
    required double borderRadius,
    required double verticalPadding,
    required double horizontalPadding,
    required double fontSize,
    required double passwordIconSize,
    required double verticalSpacing,
  }) {
    return Column(
      children: [
        _buildTextField(
          controller: nameController,
          hintText: AppStrings.names,
          colorScheme: colorScheme,
          borderRadius: borderRadius,
          verticalPadding: verticalPadding,
          horizontalPadding: horizontalPadding,
          fontSize: fontSize,
        ),
        SizedBox(height: verticalSpacing),
        _buildTextField(
          controller: lastNameController,
          hintText: AppStrings.lastNames,
          colorScheme: colorScheme,
          borderRadius: borderRadius,
          verticalPadding: verticalPadding,
          horizontalPadding: horizontalPadding,
          fontSize: fontSize,
        ),
        SizedBox(height: verticalSpacing),
        _buildTextField(
          controller: emailController,
          hintText: AppStrings.email,
          colorScheme: colorScheme,
          borderRadius: borderRadius,
          verticalPadding: verticalPadding,
          horizontalPadding: horizontalPadding,
          fontSize: fontSize,
        ),
        SizedBox(height: verticalSpacing),
        _buildPasswordTextField(
          controller: passwordController,
          hintText: AppStrings.password,
          colorScheme: colorScheme,
          borderRadius: borderRadius,
          verticalPadding: verticalPadding,
          horizontalPadding: horizontalPadding,
          fontSize: fontSize,
          passwordIconSize: passwordIconSize,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Map<String, Color?> colorScheme,
    required double borderRadius,
    required double verticalPadding,
    required double horizontalPadding,
    required double fontSize,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme[AppStrings.secondaryColor] ?? Colors.grey,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme[AppStrings.essentialColor] ?? Colors.blue,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
        hintStyle: TextStyle(
          color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.6) ??
              Colors.grey,
          fontSize: fontSize,
        ),
      ),
      style: TextStyle(
        color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
        fontSize: fontSize,
      ),
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String hintText,
    required Map<String, Color?> colorScheme,
    required double borderRadius,
    required double verticalPadding,
    required double horizontalPadding,
    required double fontSize,
    required double passwordIconSize,
  }) {
    return TextField(
      controller: controller,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme[AppStrings.secondaryColor] ?? Colors.grey,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme[AppStrings.essentialColor] ?? Colors.blue,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
        hintStyle: TextStyle(
          color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.6) ??
              Colors.grey,
          fontSize: fontSize,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
            size: passwordIconSize,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
      style: TextStyle(
        color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
        fontSize: fontSize,
      ),
    );
  }

  Widget _buildRegisterButton({
    required Map<String, Color?> colorScheme,
    required double buttonHeight,
    required double borderRadius,
  }) {
    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme[AppStrings.essentialColor] ?? Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: buttonHeight * 0.6,
                height: buttonHeight * 0.6,
                child: CircularProgressIndicator(color: Colors.white),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppStrings.signUp,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  Widget _buildPasswordRequirements({
    required Map<String, Color?> colorScheme,
    required double fontSize,
    required double iconSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: passwordValidation.entries.map((entry) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: iconSize * 0.2),
          child: Row(
            children: [
              Icon(
                entry.value ? Icons.check : Icons.close,
                color: entry.value
                    ? colorScheme[AppStrings.correctGreen] ?? Colors.green
                    : colorScheme[AppStrings.redColor] ?? Colors.red,
                size: iconSize,
              ),
              SizedBox(width: iconSize * 0.5),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color:
                          colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}