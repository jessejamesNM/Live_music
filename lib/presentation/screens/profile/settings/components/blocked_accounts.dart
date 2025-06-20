// Fecha de creación: 2025-04-26
// Autor: KingdomOfJames
// Descripción: Esta pantalla muestra las cuentas bloqueadas del usuario y permite desbloquear a los usuarios bloqueados.
// Características:
// 1. Muestra una lista de las cuentas bloqueadas por el usuario.
// 2. Permite al usuario desbloquear una cuenta con un cuadro de diálogo de confirmación.
// 3. Utiliza Firebase Firestore para cargar y actualizar la lista de usuarios bloqueados.
// 4. Incluye navegación con un botón de retroceso y barra de navegación inferior.
// Recomendaciones:
// 1. Asegúrate de manejar correctamente los errores de Firebase (por ejemplo, problemas de red).
// 2. Considera optimizar las consultas a Firestore si el número de usuarios bloqueados es grande.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';
import '../../../../../data/model/messages/user_data.dart';
import '../../../../../data/provider_logics/user/user_provider.dart';
import '../../../../widgets/profile/settings/blockedUserItem.dart';
import 'package:provider/provider.dart';
import '../../../buttom_navigation_bar.dart';

class BlockedAccounts extends StatefulWidget {
  final UserProvider userProvider;
  final GoRouter goRouter;

  const BlockedAccounts({
    Key? key,
    required this.userProvider,
    required this.goRouter,
  }) : super(key: key);

  @override
  State<BlockedAccounts> createState() => _BlockedAccountsState();
}

class _BlockedAccountsState extends State<BlockedAccounts> {
  // Lista para almacenar los ID de los usuarios bloqueados
  List<String> blockedUsers = [];

  // Lista para almacenar los datos de los usuarios bloqueados (nombre y foto de perfil)
  List<UserData> userDataList = [];

  // Flag para mostrar el diálogo de desbloqueo
  bool showUnblockDialog = false;

  // Almacena el usuario que se va a desbloquear
  UserData? userToUnblock;

  @override
  void initState() {
    super.initState();

    // Cargar usuarios bloqueados después de que la interfaz se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = context.read<UserProvider>().currentUserId;
      _loadBlockedUsers(currentUserId); // Cargar usuarios bloqueados
    });
  }

  // Función para cargar los usuarios bloqueados desde Firestore
  Future<void> _loadBlockedUsers(String userId) async {
    final db = FirebaseFirestore.instance;

    // Obtener el documento del usuario actual
    final userDoc =
        await db.collection(AppStrings.usersCollection).doc(userId).get();

    // Obtener la lista de IDs de usuarios bloqueados
    final blocked = List<String>.from(
      userDoc.data()?[AppStrings.blockedUsersField] ?? [],
    );

    // Obtener los datos de los usuarios bloqueados
    final userList = await Future.wait(
      blocked.map((userId) async {
        final doc =
            await db.collection(AppStrings.usersCollection).doc(userId).get();
        return UserData(
          userId: userId,
          name:
              doc.data()?[AppStrings.nameField] ?? AppStrings.nameNotAvailable,
          profileImageUrl: doc.data()?[AppStrings.profileImageUrlField] ?? '',
        );
      }),
    );

    // Actualizar el estado con los usuarios bloqueados y sus datos
    setState(() {
      blockedUsers = blocked;
      userDataList = userList;
    });
  }

  // Función para desbloquear a un usuario
  Future<void> unblockUser(String currentUserId, String userIdToUnblock) async {
    final db = FirebaseFirestore.instance;

    // Eliminar al usuario de la lista de bloqueados del usuario actual
    await db.collection(AppStrings.usersCollection).doc(currentUserId).update({
      AppStrings.blockedUsersField: FieldValue.arrayRemove([userIdToUnblock]),
    });

    // Eliminar al usuario actual de la lista de usuarios que lo bloquearon
    await db.collection(AppStrings.usersCollection).doc(userIdToUnblock).update(
      {
        AppStrings.usersWhoBlockedMeField: FieldValue.arrayRemove([
          currentUserId,
        ]),
      },
    );

    // Actualizar el estado para reflejar el desbloqueo
    setState(() {
      blockedUsers.remove(userIdToUnblock);
      userDataList.removeWhere((user) => user.userId == userIdToUnblock);
      showUnblockDialog = false;
      userToUnblock = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<UserProvider>().currentUserId;
    final colorScheme = ColorPalette.getPalette(context);
    final userType = widget.userProvider.userType;
    final isArtist = userType == AppStrings.artist;

    return Scaffold(
      bottomNavigationBar: BottomNavigationBarWidget(
        isArtist: isArtist,
        goRouter: widget.goRouter,
      ),
      body: Container(
        color: colorScheme[AppStrings.primaryColor],
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                        onPressed: () {
                          widget.goRouter.pop(); // Navegar hacia atrás
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            AppStrings.blockedAccountsTitle,
                            style: TextStyle(
                              color: colorScheme[AppStrings.secondaryColor],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      userDataList.isEmpty
                          ? Center(
                            child: Text(
                              AppStrings.noBlockedAccounts,
                              style: TextStyle(
                                color: colorScheme[AppStrings.secondaryColor],
                                fontSize: 18,
                              ),
                            ),
                          )
                          : ListView.builder(
                            itemCount: userDataList.length,
                            itemBuilder: (context, index) {
                              final user = userDataList[index];
                              return BlockedUserItem(
                                userData: user,
                                onUnblockClick: () {
                                  setState(() {
                                    userToUnblock = user;
                                    showUnblockDialog = true;
                                  });
                                },
                              );
                            },
                          ),
                ),
              ],
            ),
            // Diálogo para confirmar el desbloqueo de un usuario
            if (showUnblockDialog && userToUnblock != null)
              AlertDialog(
                backgroundColor: colorScheme[AppStrings.primaryColorLight],
                title: Text(
                  AppStrings.unblockUserTitle,
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
                content: Text(
                  '${AppStrings.unblockUserMessage} ${userToUnblock!.name}?',
                  style: TextStyle(
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        () => setState(() {
                          showUnblockDialog = false;
                          userToUnblock = null;
                        }),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme[AppStrings.essentialColor],
                    ),
                    child: Text(AppStrings.cancel),
                  ),
                  TextButton(
                    onPressed:
                        () => unblockUser(currentUserId, userToUnblock!.userId),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme[AppStrings.essentialColor],
                    ),
                    child: Text(AppStrings.accept),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
