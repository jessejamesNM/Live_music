import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:live_music/presentation/resources/strings.dart';
import 'package:provider/provider.dart';
import 'package:live_music/presentation/resources/colors.dart';
import '../../../../../data/provider_logics/nav_buttom_bar_components/messages/messages_provider.dart';
import '../../../../../data/provider_logics/user/user_provider.dart';
import '../../../../../data/provider_logics/user/review_provider.dart';
import '../../../../../data/model/reviews/review.dart';

class ReviewsContentWS extends StatefulWidget {
  final String otherUserId;

  const ReviewsContentWS({required this.otherUserId, Key? key})
    : super(key: key);

  @override
  _ReviewsContentWSState createState() => _ReviewsContentWSState();
}

class _ReviewsContentWSState extends State<ReviewsContentWS> {
  late UserProvider userProvider;
  late ReviewProvider reviewProvider;
  late MessagesProvider messagesProvider;

  String currentUserId = '';
  bool isDropdownVisible = false;
  String reviewText = '';
  int stars = 0;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    messagesProvider = Provider.of<MessagesProvider>(context, listen: false);
    currentUserId = userProvider.currentUserId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      reviewProvider.getAverageStars(widget.otherUserId);
      messagesProvider.checkIfMessagesExist(currentUserId, widget.otherUserId);
      reviewProvider.checkIfMyReviewExists(currentUserId, widget.otherUserId);
      if (widget.otherUserId.isNotEmpty) {
        reviewProvider.getReviewsFromRoom(widget.otherUserId).then((reviews) {
          reviewProvider.updateReviews(reviews);
        });
      }
      reviewProvider.listenForReviewChanges(widget.otherUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorPalette.getPalette(context);

    return Container(
      color: colorScheme[AppStrings.primaryColor],
      height: MediaQuery.of(context).size.height, // Añadido height
      child: Consumer<ReviewProvider>(
        builder: (context, reviewProvider, child) {
          final reviews = reviewProvider.reviews;
          final hasMessages = messagesProvider.hasMessages.value;
          final averageScore = reviewProvider.averageStars;

          return Column(
            children: [
              // Sección superior fija
              Column(
                children: [
                  const SizedBox(height: 10),
                  Divider(
                    color: colorScheme[AppStrings.selectedButtonColor],
                    thickness: 0.63,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${AppStrings.averageScore} $averageScore',
                        style: TextStyle(
                          fontFamily: AppStrings.customFontFamilyBold,
                          color: colorScheme[AppStrings.secondaryColor],
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.star,
                        color: colorScheme[AppStrings.essentialColor],
                        size: 25,
                      ),
                    ],
                  ),
                  Divider(
                    color: colorScheme[AppStrings.selectedButtonColor],
                    thickness: 0.63,
                  ),
                  const SizedBox(height: 4),
                  if (hasMessages && !reviewProvider.myReviewExist) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isDropdownVisible = !isDropdownVisible;
                          reviewText = '';
                          stars = 0;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            AppStrings.writeIconPath,
                            height: 35,
                            width: 35,
                            color: colorScheme[AppStrings.secondaryColor],
                          ),
                          const SizedBox(width: 5),
                          Text(
                            AppStrings.writeReview,
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: AppStrings.customFontFamily,
                              color: colorScheme[AppStrings.grayColor],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                  ],
                  if (isDropdownVisible)
                    _buildReviewInput(colorScheme, reviews),
                  Divider(
                    color: colorScheme[AppStrings.selectedButtonColor],
                    thickness: 0.83,
                  ),
                ],
              ),

              // Lista de reseñas con Expanded
              Expanded(
                child:
                    reviews.isEmpty
                        ? Center(
                          child: Text(
                            AppStrings.noReviewsYet,
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme[AppStrings.secondaryColor],
                            ),
                          ),
                        )
                        : SingleChildScrollView(
                          child: Column(
                            children:
                                reviews
                                    .map(
                                      (review) =>
                                          _buildReviewCard(review, colorScheme),
                                    )
                                    .toList(),
                          ),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(Review review, Map<String, Color> colorScheme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: colorScheme[AppStrings.primarySecondColor],
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(review.senderProfileImageUrl),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.senderName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme[AppStrings.secondaryColor],
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          color:
                              index < review.stars
                                  ? colorScheme[AppStrings.essentialColor]
                                  : colorScheme[AppStrings.secondaryColor],
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (review.senderId == currentUserId)
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: colorScheme[AppStrings.essentialColor],
                        ),
                        onPressed: () {
                          setState(() {
                            isDropdownVisible = true;
                            reviewText = review.text;
                            stars = review.stars;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: colorScheme[AppStrings.essentialColor],
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text(AppStrings.deleteReviewTitle),
                                  content: Text(AppStrings.confirmDeleteReview),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(AppStrings.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        reviewProvider.deleteReview(
                                          review.id,
                                          review.senderId,
                                        );
                                        Navigator.pop(context);
                                      },
                                      child: Text(AppStrings.delete),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                review.text,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme[AppStrings.secondaryColor],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewInput(
    Map<String, Color> colorScheme,
    List<Review> reviews,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme[AppStrings.primarySecondColor],
        border: Border.all(
          color: colorScheme[AppStrings.selectedButtonColor] ?? Colors.grey,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: colorScheme[AppStrings.secondaryColor],
                ),
                onPressed: () {
                  setState(() {
                    isDropdownVisible = false;
                  });
                },
              ),
            ],
          ),
          Text(
            reviewProvider.myReviewExist
                ? AppStrings.modifyReview
                : AppStrings.writeReviewHere,
            style: TextStyle(
              fontSize: 18,
              fontFamily: AppStrings.customFontFamily,
              color: colorScheme[AppStrings.secondaryColor],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: reviewText),
            onChanged: (text) {
              setState(() {
                reviewText = text;
              });
            },
            style: TextStyle(color: colorScheme[AppStrings.secondaryColor]),
            decoration: InputDecoration(
              hintText: AppStrings.reviewTextHint,
              hintStyle: TextStyle(
                color: colorScheme[AppStrings.secondaryColor]?.withOpacity(0.6),
              ),
              contentPadding: const EdgeInsets.all(8),
            ),
            maxLines: null,
          ),
          const SizedBox(height: 2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  AppStrings.rating,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme[AppStrings.secondaryColor],
                  ),
                ),
                for (int i = 1; i <= 5; i++)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      i <= stars ? Icons.star : Icons.star_border,
                      color:
                          i <= stars
                              ? colorScheme[AppStrings.essentialColor]
                              : colorScheme[AppStrings.secondaryColor],
                    ),
                    onPressed: () {
                      setState(() {
                        stars = i;
                      });
                    },
                  ),
                const SizedBox(width: 2),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: colorScheme[AppStrings.essentialColor],
                  ),
                  onPressed: () async {
                    final userProv = Provider.of<UserProvider>(
                      context,
                      listen: false,
                    );

                    if (reviewProvider.myReviewExist) {
                      final review = reviews.firstWhere(
                        (r) => r.senderId == currentUserId,
                      );
                      reviewProvider.updateReview(
                        review.id,
                        reviewText,
                        stars,
                        widget.otherUserId,
                        (success, message) {
                          if (success) {
                            setState(() => isDropdownVisible = false);
                            userProv.addStars(widget.otherUserId, stars);
                          } else {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));
                          }
                        },
                      );
                    } else {
                      reviewProvider.sendReview(
                        stars,
                        reviewText,
                        currentUserId,
                        widget.otherUserId,
                      );
                      setState(() => isDropdownVisible = false);
                      userProv.addStars(widget.otherUserId, stars);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
