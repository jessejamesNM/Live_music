// Fecha de creación: 26/04/2025
// Autor: KingdomOfJames
//
// Descripción:
// Este widget es un campo de texto personalizado (CustomTextField), que permite al usuario ingresar datos de forma flexible.
// El campo de texto tiene un estilo personalizable con un texto de marcador de posición (placeholder) y la opción de ocultar el texto ingresado (útil para contraseñas).
// Al cambiar el valor del campo, se ejecuta la función `onChanged` proporcionada por el usuario, permitiendo una gestión dinámica del estado.
//
// Características:
// - El campo tiene un borde redondeado con un radio de 8.0.
// - Permite ocultar el texto ingresado si la opción `isPassword` es verdadera, ideal para campos de contraseñas.
// - Tiene un texto de marcador de posición (`placeholder`) que aparece cuando el campo está vacío.
// - Utiliza un `ValueChanged<String>` para manejar cambios en el valor del campo de texto, proporcionando retroalimentación inmediata.
//
// Recomendaciones:
// - Este widget es útil para formularios donde el usuario necesita ingresar datos, como nombres de usuario, contraseñas, correos electrónicos, etc.
// - Asegúrate de manejar el estado de los datos correctamente utilizando el `onChanged` para actualizar el valor en el modelo de datos o el controlador del formulario.
// - Si se utiliza para contraseñas o datos sensibles, considera agregar validaciones adicionales para mejorar la seguridad y la usabilidad.

import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String value; // Valor actual del campo de texto.
  final ValueChanged<String>
  onChanged; // Función que se ejecuta cuando cambia el valor del campo.
  final String
  placeholder; // Texto de marcador de posición (placeholder) cuando el campo está vacío.
  final bool
  isPassword; // Indica si el campo de texto es para una contraseña (opcional).

  // Constructor que recibe el valor, el callback onChanged, el placeholder y la opción de ocultar el texto (para contraseñas).
  CustomTextField({
    required this.value,
    required this.onChanged,
    required this.placeholder,
    this.isPassword =
        false, // Por defecto, no se oculta el texto (no es una contraseña).
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged:
          onChanged, // Llama al callback onChanged cada vez que cambia el valor del campo.
      obscureText:
          isPassword, // Si es true, oculta el texto (ideal para contraseñas).
      decoration: InputDecoration(
        hintText:
            placeholder, // Muestra el texto de marcador de posición cuando el campo está vacío.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ), // Aplica un borde redondeado al campo de texto.
      ),
    );
  }
}
