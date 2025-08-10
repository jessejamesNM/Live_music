/*
  Fecha de creación: 26/04/2025
  Autor: KingdomOfJames

  Descripción:
  Este archivo define un conversor personalizado `ListStringConverter` utilizado por el ORM Floor
  para convertir entre listas de Strings (`List<String>`) y su representación en texto (`String`).
  Permite almacenar listas de manera compacta dentro de un solo campo de la base de datos.

  Características:
  - Conversión automática de List<String> a String para almacenamiento.
  - Conversión automática de String a List<String> para recuperación de datos.
  - Uso sencillo y reutilizable en entidades de Floor donde se necesiten listas.

  Recomendaciones:
  - Validar que las cadenas no contengan comas internas si quieres evitar conflictos en la conversión.
  - Considerar un esquema de serialización más robusto (como JSON) si las listas son complejas o anidadas.
  - Añadir pruebas unitarias para verificar la correcta codificación y decodificación de casos especiales.

*/

import 'package:floor/floor.dart';

// Clase que implementa un convertidor entre List<String> y String para Floor
class ListStringConverter extends TypeConverter<List<String>, String> {
  // Método que decodifica un String de la base de datos a una List<String>
  @override
  List<String> decode(String databaseValue) {
    // Separamos el String en partes usando comas y eliminamos espacios innecesarios
    return databaseValue.split(',').map((e) => e.trim()).toList();
  }

  // Método que codifica una List<String> a un solo String para almacenamiento
  @override
  String encode(List<String> value) {
    // Unimos todos los elementos de la lista en un String separado por comas
    return value.join(',');
  }
}
