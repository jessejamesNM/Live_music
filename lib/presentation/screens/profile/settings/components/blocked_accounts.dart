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

import 'package:firebase_auth/firebase_auth.dart';
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
  List<String> blockedUsers = [];
  List<UserData> userDataList = [];
  bool showUnblockDialog = false;
  UserData? userToUnblock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        _loadBlockedUsers(currentUserId);
      }
    });
  }

  Future<void> _loadBlockedUsers(String userId) async {
    final db = FirebaseFirestore.instance;
    final userDoc = await db.collection(AppStrings.usersCollection).doc(userId).get();
    final blocked = List<String>.from(userDoc.data()?[AppStrings.blockedUsersField] ?? []);
    final userList = await Future.wait(blocked.map((userId) async {
      final doc = await db.collection(AppStrings.usersCollection).doc(userId).get();
      return UserData(
        userId: userId,
        name: doc.data()?[AppStrings.nameField] ?? AppStrings.nameNotAvailable,
        profileImageUrl: doc.data()?[AppStrings.profileImageUrlField] ?? '',
      );
    }));
    setState(() {
      blockedUsers = blocked;
      userDataList = userList;
    });
  }

  Future<void> unblockUser(String currentUserId, String userIdToUnblock) async {
    final db = FirebaseFirestore.instance;
    await db.collection(AppStrings.usersCollection).doc(currentUserId).update({
      AppStrings.blockedUsersField: FieldValue.arrayRemove([userIdToUnblock]),
    });
    await db.collection(AppStrings.usersCollection).doc(userIdToUnblock).update({
      AppStrings.usersWhoBlockedMeField: FieldValue.arrayRemove([currentUserId]),
    });
    setState(() {
      blockedUsers.remove(userIdToUnblock);
      userDataList.removeWhere((user) => user.userId == userIdToUnblock);
      showUnblockDialog = false;
      userToUnblock = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final colorScheme = ColorPalette.getPalette(context);
    final userType = widget.userProvider.userType;

    return Scaffold(
      bottomNavigationBar: BottomNavigationBarWidget(
        userType: userType,
        goRouter: widget.goRouter,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final widthFactor = constraints.maxWidth / 400;
          final heightFactor = constraints.maxHeight / 800;
          final scale = widthFactor < heightFactor ? widthFactor : heightFactor;

          return Container(
            color: colorScheme[AppStrings.primaryColor],
            child: Stack(
              children: [
                Column(
                  children: [
                    SizedBox(height: 30 * scale),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: colorScheme[AppStrings.secondaryColor],
                              size: 30 * scale,
                            ),
                            onPressed: () {
                              widget.goRouter.pop();
                            },
                          ),
                          Expanded(
                            child: Center(
                              child: FittedBox(
                                child: Text(
                                  AppStrings.blockedAccountsTitle,
                                  style: TextStyle(
                                    color: colorScheme[AppStrings.secondaryColor],
                                    fontSize: 20 * scale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 48 * scale),
                        ],
                      ),
                    ),
                    Expanded(
                      child: userDataList.isEmpty
                          ? Center(
                              child: FittedBox(
                                child: Text(
                                  AppStrings.noBlockedAccounts,
                                  style: TextStyle(
                                    color: colorScheme[AppStrings.secondaryColor],
                                    fontSize: 18 * scale,
                                  ),
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
                                  scaleFactor: scale,
                                );
                              },
                            ),
                    ),
                  ],
                ),
                if (showUnblockDialog && userToUnblock != null)
                  AlertDialog(
                    backgroundColor: colorScheme[AppStrings.primaryColorLight],
                    title: FittedBox(
                      child: Text(
                        AppStrings.unblockUserTitle,
                        style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
                      ),
                    ),
                    content: FittedBox(
                      child: Text(
                        '${AppStrings.unblockUserMessage} ${userToUnblock!.name}?',
                        style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => setState(() {
                          showUnblockDialog = false;
                          userToUnblock = null;
                        }),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme[AppStrings.essentialColor],
                        ),
                        child: FittedBox(child: Text(AppStrings.cancel)),
                      ),
                      TextButton(
                        onPressed: () {
                          if (currentUserId != null) {
                            unblockUser(currentUserId, userToUnblock!.userId);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme[AppStrings.essentialColor],
                        ),
                        child: FittedBox(child: Text(AppStrings.accept)),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
