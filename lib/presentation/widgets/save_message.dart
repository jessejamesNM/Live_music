import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:live_music/data/provider_logics/nav_buttom_bar_components/favorites/favorites_provider.dart';
import 'package:live_music/data/sources/local/internal_data_base.dart';
import 'package:live_music/presentation/resources/colors.dart';
import 'package:live_music/presentation/resources/strings.dart';

class SaveMessage extends StatefulWidget {
  final LikedUsersList list;
  final VoidCallback onModifyClick;
  final bool isVisible;
  final VoidCallback onDismiss;
  final FavoritesProvider favoritesProvider;
  final String userIdToRemove;
  final VoidCallback onLikeClick;
  final VoidCallback onUnlikeClick;
  final String currentUserId;

  const SaveMessage({
    required this.list,
    required this.onModifyClick,
    required this.isVisible,
    required this.onDismiss,
    required this.favoritesProvider,
    required this.userIdToRemove,
    required this.onLikeClick,
    required this.onUnlikeClick,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  _SaveMessageState createState() => _SaveMessageState();
}

class _SaveMessageState extends State<SaveMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleVisibility();
      });
    }
  }

  @override
  void didUpdateWidget(covariant SaveMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleVisibility();
        });
      } else {
        _hideDialog();
      }
    }
  }

  Future<void> _handleVisibility() async {
    final currentUserId = widget.currentUserId;
    final snap =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();

    final data = snap.data();
    final likedUsers =
        data != null && data.containsKey('likedUsers')
            ? List<String>.from(data['likedUsers'] ?? [])
            : <String>[];

    if (likedUsers.contains(widget.userIdToRemove)) {
      _showCenteredDialog(widget.list.name);
      widget.onDismiss();
      return;
    }

    widget.onLikeClick();
    _showDialog();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _hideDialog();
    });
  }

  void _showCenteredDialog(String listName) {
    final colorScheme = ColorPalette.getPalette(context);
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Center(
            child: Material(
              color: Colors.black.withOpacity(0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: colorScheme[AppStrings.primaryColor],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  '${AppStrings.userAlreadyInListMessage} "$listName", ${AppStrings.cannotAddToNewListMessage}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
              ),
            ),
          ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }

  void _showDialog() {
    setState(() {
      _isDialogVisible = true;
    });
    _controller.forward();
  }

  void _hideDialog() {
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isDialogVisible = false;
        });
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDialogVisible) return const SizedBox.shrink();
    final colorScheme = ColorPalette.getPalette(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      elevation: 0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme[AppStrings.primaryColorLight],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.list.imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${AppStrings.savedIn} ${widget.list.name}",
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme[AppStrings.secondaryColor],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        widget.onUnlikeClick();
                        widget.onModifyClick();
                        _hideDialog();
                      },
                      child: Text(
                        AppStrings.modify,
                        style: TextStyle(
                          color: colorScheme[AppStrings.essentialColor],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
