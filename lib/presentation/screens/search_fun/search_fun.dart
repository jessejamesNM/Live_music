// Fecha: 26 de abril de 2025
// Autor: KingdomOfJames
//
// Descripción:
// Esta pantalla muestra la funcionalidad de búsqueda para que los usuarios busquen otros usuarios en la aplicación,
// filtrados según los criterios de búsqueda proporcionados. La interfaz incluye un campo de texto para buscar,
// una lista de resultados y un indicador de carga cuando se realizan consultas.
//
// Características:
// - Búsqueda en tiempo real de usuarios mediante un campo de texto.
// - Muestra un listado de usuarios que coinciden con los criterios de búsqueda.
// - Diseño responsive con una barra de navegación en la parte inferior.
// - Manejo de estados de carga mientras se realizan las consultas de búsqueda.
//
// Recomendaciones:
// - Asegurarse de que el campo de búsqueda tenga una interacción intuitiva con los usuarios.
// - Considerar agregar paginación si los resultados de búsqueda pueden llegar a ser muy largos.
// - Mantener la consistencia visual con el resto de la aplicación, especialmente con el esquema de colores.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../data/provider_logics/nav_buttom_bar_components/home/search_fun_provider.dart';
import '../../../data/provider_logics/user/user_provider.dart';
import '../buttom_navigation_bar.dart';

// Pantalla de búsqueda para encontrar usuarios por nombre o apodo.
class SearchFunScreen extends StatelessWidget {
  final GoRouter goRouter;

  // Constructor que recibe una instancia de GoRouter para navegar entre pantallas
  SearchFunScreen({required this.goRouter});

  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(
      context,
    ); // Obtiene el esquema de colores de la app.
    final searchFunProvider = Provider.of<SearchFunProvider>(
      context,
    ); // Proveedor de lógica de búsqueda.
    final userProvider = Provider.of<UserProvider>(
      context,
    ); // Proveedor de datos del usuario.
    final userType = userProvider.userType; // Tipo de usuario actual.
    final isArtist =
        userType == AppStrings.artist; // Determina si el usuario es un artista.

    return Scaffold(
      backgroundColor:
          colorScheme[AppStrings.primaryColor], // Establece el color de fondo.
      bottomNavigationBar: BottomNavigationBarWidget(
        goRouter: goRouter,
        userType: userType,
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 48.0,
          left: 16,
          right: 16,
          bottom: 8,
        ),
        child: Column(
          children: [
            // Barra de navegación superior con botón de retroceso.
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, size: 28),
                    color: colorScheme[AppStrings.secondaryColor],
                    onPressed:
                        () =>
                            goRouter.pop(), // Retrocede a la pantalla anterior.
                  ),
                ),
                Text(
                  AppStrings.explore, // Título de la pantalla.
                  style: TextStyle(
                    fontSize: 24,
                    color: colorScheme[AppStrings.secondaryColor],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Campo de búsqueda.
            _buildSearchField(
              controller: _searchController,
              colorScheme: colorScheme,
              onSearch: () {
                final query =
                    _searchController.text
                        .trim(); // Obtiene el texto de búsqueda.

                if (query.isNotEmpty) {
                  searchFunProvider.searchUsers(
                    query,
                  ); // Inicia la búsqueda si el texto no está vacío.
                }
              },
            ),
            SizedBox(height: 20),
            // Resultados de la búsqueda.
            Expanded(
              child: _buildSearchResults(
                colorScheme: colorScheme,
                searchFunProvider: searchFunProvider,
                userProvider: userProvider,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget que construye el campo de búsqueda.
  Widget _buildSearchField({
    required TextEditingController controller,
    required Map<String, Color?> colorScheme,
    required VoidCallback onSearch,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme[AppStrings.backgroundColor],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme[AppStrings.secondaryColor]!,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
        decoration: InputDecoration(
          hintText: AppStrings.searchUsersHint, // Texto del hint.
          hintStyle: TextStyle(
            color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme[AppStrings.secondaryColor],
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.send,
              color: colorScheme[AppStrings.essentialColor],
            ),
            onPressed:
                onSearch, // Ejecuta la búsqueda cuando se presiona el botón.
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted:
            (_) => onSearch(), // Ejecuta la búsqueda cuando se presiona Enter.
      ),
    );
  }

  // Widget que construye los resultados de la búsqueda.
  Widget _buildSearchResults({
    required Map<String, Color?> colorScheme,
    required SearchFunProvider searchFunProvider,
    required UserProvider userProvider,
  }) {
    return Consumer<SearchFunProvider>(
      // Escucha los cambios en el proveedor de búsqueda.
      builder: (context, provider, child) {
        if (provider.isLoading) {
          // Si está cargando, muestra un indicador de progreso.
          return Center(
            child: CircularProgressIndicator(
              color: colorScheme[AppStrings.secondaryColor],
            ),
          );
        }

        if (provider.userDataList.isNotEmpty) {
          return ListView.builder(
            itemCount: provider.userDataList.length,
            itemBuilder: (context, index) {
              final userData = provider.userDataList[index];
              return UserItem(
                userData: userData,
                onClick: () {
                  userProvider.setOtherUserId(userData.userId);
                  goRouter.push(
                    AppStrings.profileArtistScreenWSRoute,
                  ); // Navega al perfil del artista.
                  userProvider.loadUserData(
                    userData.userId,
                  ); // Carga los datos del usuario.
                },
                userProvider: userProvider,
                colorScheme: colorScheme,
              );
            },
          );
        }

        return Center(
          child: Text(
            provider.hasSearched
                ? AppStrings
                    .noResultsFound // Mensaje si no se encuentran resultados.
                : AppStrings
                    .enterSearchTerm, // Mensaje si no se ha realizado ninguna búsqueda.
            style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
          ),
        );
      },
    );
  }
}

// Widget que representa cada elemento de usuario en los resultados de búsqueda.
class UserItem extends StatelessWidget {
  final UserData userData;
  final VoidCallback onClick;
  final UserProvider userProvider;
  final Map<String, Color?> colorScheme;

  const UserItem({
    required this.userData,
    required this.onClick,
    required this.userProvider,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme[AppStrings.primaryColorLight],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundImage: NetworkImage(userData.profileImageUrl),
          radius: 24,
        ),
        title: Text(
          userData.name,
          style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
        ),
        subtitle: Text(
          userData.nickname,
          style: TextStyle(
            color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.7),
          ),
        ),
        trailing: Text(
          "\$${userData.price.toStringAsFixed(2)}", // Muestra el precio del servicio del usuario.
          style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
        ),
        onTap: onClick, // Acción al hacer clic en el elemento de la lista.
      ),
    );
  }
}
