// Fecha de creación: 26 de abril de 2025
// Autor: KingdomOfJames
//
// Descripción:
// Esta clase `Pair` es una estructura genérica simple que permite almacenar dos elementos
// de diferentes tipos (denotados como F y S). Esta clase es útil cuando necesitas emparejar
// dos valores diferentes, como una clave y un valor, o cualquier otro par de datos que desees almacenar
// juntos. Se puede utilizar en múltiples contextos, como en la implementación de mapas, listas de pares,
// entre otros.
//
// Recomendaciones:
// - Utiliza esta clase cuando necesites emparejar valores sin necesidad de crear una nueva clase
//   para representar ese par de datos.
// - Ten cuidado con los tipos de datos que utilices, ya que esta clase es genérica y puede almacenar
//   cualquier tipo de objeto, pero depende del contexto en el que la uses para dar sentido a los tipos.
//
// Características:
// - Clase genérica que permite la creación de objetos con dos tipos de datos diferentes.
// - Proporciona un par de valores, `first` y `second`, accesibles mediante sus propiedades.
// - Simple implementación que solo permite acceder a los elementos, pero no modificar sus valores después de la inicialización.

class Pair<F, S> {
  final F first; // El primer valor del par
  final S second; // El segundo valor del par

  // Constructor que inicializa el par de valores
  Pair(this.first, this.second);
}
