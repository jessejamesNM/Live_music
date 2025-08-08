// Fecha de creación: 2025-04-22
// Autor: KingdomOfJames
//
// Descripción:
// Pantalla de registro para artistas mediante correo electrónico y contraseña.
// La pantalla permite ingresar el nombre, apellido, correo electrónico y contraseña
// con validaciones en tiempo real para la contraseña y el correo electrónico.
// El botón de registro se habilita solo cuando todos los campos son válidos.
//
// Recomendaciones:
// - Asegurarse de que los campos de entrada de texto estén correctamente validados
//   antes de enviar el formulario para evitar errores de registro.
// - Considerar la posibilidad de agregar una validación más estricta para la contraseña
//   en términos de longitud y complejidad dependiendo de las políticas de seguridad de la plataforma.
//
// Características:
// - Validación en tiempo real de los requisitos de la contraseña (longitud, mayúsculas,
//   minúsculas, números y caracteres especiales).
// - Uso de un indicador de carga mientras se realiza el registro.
// - Manejo de errores para mostrar mensajes relevantes en caso de campos vacíos o
//   correo/contraseña no válidos.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/data/model/global_variables.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../../data/repositories/providers_repositories/user_repository.dart';
import '../../../../../../resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

// Pantalla de registro para artistas usando email y contraseña
class RegisterArtistMailScreen extends StatefulWidget {
  @override
  _RegisterArtistMailScreenState createState() =>
      _RegisterArtistMailScreenState();
}

class _RegisterArtistMailScreenState extends State<RegisterArtistMailScreen> {
  // Estados para controlar carga, errores y validaciones de contraseña
  bool isLoading = false;
  String errorMessage = "";
  Map<String, bool> passwordValidation = {};

  // Controladores para los campos del formulario
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inicializa el estado de validación de contraseña
    passwordValidation = {
      AppStrings.passwordLengthReq: false,
      AppStrings.passwordUppercaseReq: false,
      AppStrings.passwordLowercaseReq: false,
      AppStrings.passwordNumberReq: false,
      AppStrings.passwordSpecialCharReq: false,
    };
    // Escucha cambios en el campo de contraseña para actualizar validaciones
    passwordController.addListener(_updatePasswordValidation);
  }

  @override
  void dispose() {
    // Remueve el listener cuando se destruye el widget
    passwordController.removeListener(_updatePasswordValidation);
    super.dispose();
  }

  // Actualiza las validaciones de contraseña en tiempo real
  void _updatePasswordValidation() {
    setState(() {
      passwordValidation = isPasswordValid(passwordController.text);
    });
  }

  // Verifica si un correo es válido
  bool isEmailValid(String email) {
    return emailPattern.hasMatch(email);
  }

  // Verifica múltiples requisitos de una contraseña y devuelve el resultado
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

  // Maneja el proceso de registro cuando el usuario presiona el botón
  Future<void> _handleRegistration() async {
    final name = nameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Validación básica de campos vacíos
    if (name.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = AppStrings.emptyFieldsError);
      return;
    }

    // Validación de correo
    if (!isEmailValid(email)) {
      setState(() => errorMessage = AppStrings.invalidEmailError);
      return;
    }

    // Validación de requisitos de contraseña
    if (!passwordValidation.values.every((isValid) => isValid)) {
      setState(() => errorMessage = AppStrings.passwordRequirementsError);
      return;
    }

    // Muestra indicador de carga
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final userRepository = UserRepository(sharedPreferences);
      final role = AppStrings.artist;

      // Intenta registrar el usuario
      final errorMsg = await userRepository.registerUser(
        email,
        password,
        role,
        name,
        lastName,
      );

      // Si no hay error, redirige al usuario a la pantalla de espera de confirmación
      if (errorMsg == null) {
        if (mounted) context.go(AppStrings.waitingConfirmScreenRoute);
      } else {
        setState(() => errorMessage = errorMsg);
      }
    } catch (e) {
      setState(() => errorMessage = AppStrings.unexpectedError);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    // Constantes de diseño para mantener coherencia visual
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
              // Botón para volver atrás
              Padding(
                padding: const EdgeInsets.only(top: iconPaddingTop),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 26.0),
                  color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                  onPressed: () => context.pop(),
                ),
              ),
              // Título de la pantalla
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

              // Campos del formulario
              _buildFormFields(
                colorScheme: colorScheme,
                borderValue: borderValue,
                contentPaddingTFVertical: contentPaddingTFVertical,
                contentPaddingTFHorizontal: contentPaddingTFHorizontal,
                textFieldSpacing: textFieldSpacing,
              ),
              SizedBox(height: textFieldSpacing * 1.5),

              // Botón de registro
              _buildRegisterButton(
                colorScheme: colorScheme,
                buttonHeight: buttonHeight,
                buttonBorderRadius: buttonBorderRadius,
              ),

              // Mensaje de error si existe
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

              // Texto y lista de requisitos de contraseña
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

  // Construye los campos del formulario
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
          _buildTextField(
            controller: passwordController,
            hintText: AppStrings.password,
            obscureText: true,
            colorScheme: colorScheme,
            borderValue: borderValue,
            contentPaddingTFVertical: contentPaddingTFVertical,
            contentPaddingTFHorizontal: contentPaddingTFHorizontal,
          ),
        ],
      ),
    );
  }

  // Crea un TextField estilizado
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Map<String, Color?> colorScheme,
    required double borderValue,
    required double contentPaddingTFVertical,
    required double contentPaddingTFHorizontal,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: colorScheme[AppStrings.primaryColor] ?? Colors.white,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(borderValue),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(borderValue),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
          ),
          borderRadius: BorderRadius.circular(borderValue),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: contentPaddingTFVertical,
          horizontal: contentPaddingTFHorizontal,
        ),
      ),
      style: TextStyle(
        color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
      ),
    );
  }

  // Botón para iniciar el registro
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
              ? CircularProgressIndicator(
                color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
              )
              : Text(
                AppStrings.signUp,
                style: TextStyle(
                  color: colorScheme[AppStrings.secondaryColor] ?? Colors.black,
                ),
              ),
    );
  }

  // Muestra los requisitos de la contraseña con check/cross dinámicos
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
