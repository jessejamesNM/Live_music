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

// Clase principal que define la pantalla de registro de contratistas
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

  bool isEmailValid(String email) {
    return emailPattern.hasMatch(email);
  }

  Map<String, bool> isPasswordValid(String password) {
    return {
      AppStrings.passwordLengthReq: password.length >= 8,
      AppStrings.passwordUppercaseReq: password.contains(RegExp(r'[A-Z]')),
      AppStrings.passwordLowercaseReq: password.contains(RegExp(r'[a-z]')),
      AppStrings.passwordNumberReq: password.contains(RegExp(r'[0-9]')),
      AppStrings.passwordSpecialCharReq: password.contains(
        RegExp(r'[^a-zA-Z0-9]'),
      ),
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

    if (!passwordValidation.values.every((isValid) => isValid)) {
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
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    const double borderValue = 15.0;
    const double contentPaddingTFVertical = 6.0;
    const double contentPaddingTFHorizontal = 12.0;
    const double iconPaddingTop = 16.0;
    const double textFieldSpacing = 8.0;
    const double buttonHeight = 40.0;
    const double buttonBorderRadius = 17.0;
    const double titleFontSize = 26.0;
    const double passwordHintFontSize = 15.0;
    const double passwordHintIconSize = 16.0;

    return Scaffold(
      backgroundColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: iconPaddingTop),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 26.0),
                  color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                  onPressed: () => context.pop(),
                ),
              ),
              Center(
                child: Text(
                  AppStrings.signUp,
                  style: TextStyle(
                    color:
                        colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                    fontSize: titleFontSize,
                  ),
                ),
              ),
              SizedBox(height: textFieldSpacing * 2),

              _buildFormFields(
                colorScheme: colorScheme,
                borderValue: borderValue,
                contentPaddingTFVertical: contentPaddingTFVertical,
                contentPaddingTFHorizontal: contentPaddingTFHorizontal,
                textFieldSpacing: textFieldSpacing,
              ),
              SizedBox(height: textFieldSpacing * 1.5),

              _buildRegisterButton(
                colorScheme: colorScheme,
                buttonHeight: buttonHeight,
                buttonBorderRadius: buttonBorderRadius,
              ),

              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: textFieldSpacing),
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      color: colorScheme[AppStrings.redColor] ?? Colors.red,
                    ),
                  ),
                ),

              SizedBox(height: textFieldSpacing * 1.5),

              Text(
                AppStrings.password,
                style: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                  fontSize: passwordHintFontSize,
                ),
              ),
              _buildPasswordRequirements(
                colorScheme: colorScheme,
                passwordHintIconSize: passwordHintIconSize,
                textFieldSpacing: textFieldSpacing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields({
    required Map<String, Color?> colorScheme,
    required double borderValue,
    required double contentPaddingTFVertical,
    required double contentPaddingTFHorizontal,
    required double textFieldSpacing,
  }) {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          _buildTextField(
            controller: nameController,
            hintText: AppStrings.names,
            colorScheme: colorScheme,
            borderValue: borderValue,
            contentPaddingTFVertical: contentPaddingTFVertical,
            contentPaddingTFHorizontal: contentPaddingTFHorizontal,
          ),
          SizedBox(height: textFieldSpacing),
          _buildTextField(
            controller: lastNameController,
            hintText: AppStrings.lastNames,
            colorScheme: colorScheme,
            borderValue: borderValue,
            contentPaddingTFVertical: contentPaddingTFVertical,
            contentPaddingTFHorizontal: contentPaddingTFHorizontal,
          ),
          SizedBox(height: textFieldSpacing),
          _buildTextField(
            controller: emailController,
            hintText: AppStrings.email,
            colorScheme: colorScheme,
            borderValue: borderValue,
            contentPaddingTFVertical: contentPaddingTFVertical,
            contentPaddingTFHorizontal: contentPaddingTFHorizontal,
          ),
          SizedBox(height: textFieldSpacing),
          _buildPasswordTextField(
            controller: passwordController,
            hintText: AppStrings.password,
            colorScheme: colorScheme,
            borderValue: borderValue,
            contentPaddingTFVertical: contentPaddingTFVertical,
            contentPaddingTFHorizontal: contentPaddingTFHorizontal,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Map<String, Color?> colorScheme,
    required double borderValue,
    required double contentPaddingTFVertical,
    required double contentPaddingTFHorizontal,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme[AppStrings.secondaryColor] ?? Colors.grey,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(borderValue),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme[AppStrings.secondaryColor] ?? Colors.grey,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(borderValue),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme[AppStrings.essentialColor] ?? Colors.blue,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(borderValue),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: contentPaddingTFVertical,
          horizontal: contentPaddingTFHorizontal,
        ),
        hintStyle: TextStyle(
          color:
              colorScheme[AppStrings.secondaryColor]?.withOpacity(0.6) ??
              Colors.grey,
        ),
      ),
      style: TextStyle(
        color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
      ),
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String hintText,
    required Map<String, Color?> colorScheme,
    required double borderValue,
    required double contentPaddingTFVertical,
    required double contentPaddingTFHorizontal,
  }) {
    return TextField(
      controller: controller,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme[AppStrings.secondaryColor] ?? Colors.grey,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(borderValue),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme[AppStrings.secondaryColor] ?? Colors.grey,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(borderValue),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme[AppStrings.essentialColor] ?? Colors.blue,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(borderValue),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: contentPaddingTFVertical,
          horizontal: contentPaddingTFHorizontal,
        ),
        hintStyle: TextStyle(
          color:
              colorScheme[AppStrings.secondaryColor]?.withOpacity(0.6) ??
              Colors.grey,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      style: TextStyle(
        color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
      ),
    );
  }

  Widget _buildRegisterButton({
    required Map<String, Color?> colorScheme,
    required double buttonHeight,
    required double buttonBorderRadius,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : _handleRegistration,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme[AppStrings.essentialColor] ?? Colors.white,
        minimumSize: Size(double.infinity, buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonBorderRadius),
        ),
      ),
      child:
          isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Text(AppStrings.signUp, style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildPasswordRequirements({
    required Map<String, Color?> colorScheme,
    required double passwordHintIconSize,
    required double textFieldSpacing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          passwordValidation.entries.map((entry) {
            return Row(
              children: [
                Icon(
                  entry.value ? Icons.check : Icons.close,
                  color:
                      entry.value
                          ? colorScheme[AppStrings.correctGreen] ?? Colors.green
                          : colorScheme[AppStrings.redColor] ?? Colors.red,
                  size: passwordHintIconSize,
                ),
                SizedBox(width: textFieldSpacing),
                Text(
                  entry.key,
                  style: TextStyle(
                    color:
                        colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }
}
