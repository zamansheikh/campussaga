import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/core/utils/utils.dart';
import 'package:campus_saga/domain/entities/promotion.dart';
import 'package:campus_saga/presentation/bloc/ads/ads_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_bloc.dart';
import 'package:campus_saga/presentation/bloc/auth/auth_state.dart';
import 'package:campus_saga/presentation/pages/profile/profile_page.dart';
import 'package:campus_saga/presentation/pages/promotion/promotion_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class PromotionPage extends StatefulWidget {
  const PromotionPage({super.key});

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  // Example list of promotions - normally this data would come from a backend or database
  List<Promotion> promotions = [];
  var userState = null;
  @override
  void initState() {
    fetchUser();
    _fetchAds();
    super.initState();
  }

  void fetchUser() {
    final state = sl<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      setState(() {
        userState = state.user;
      });
    }
  }

  void _fetchAds() {
    final state = sl<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      setState(() {
        userState = state.user;
      });
      final String universityId =
          state.user.universityId.split('@').last.trim();
      print("Fetching posts for university: $universityId");
      sl<AdsBloc>().add(FetchAdsEvent());
    }
  }

  String getUserId() {
    try {
      return userState.user.id;
    } catch (e) {
      return '';
    }
  }

  void toggleTrueVote(Promotion promotion) {
    int index = promotions.indexOf(promotion);
    setState(() {
      promotions[index] =
          promotion.toggleTrueVote(getUserId()); // Example userId
    });
    sl<AdsBloc>().add(UpdateAdsEvent(promotions[index]));
  }

  void toggleFalseVote(Promotion promotion) {
    int index = promotions.indexOf(promotion);
    setState(() {
      promotions[index] =
          promotion.toggleFalseVote(getUserId()); // Example userId
    });
    sl<AdsBloc>().add(UpdateAdsEvent(promotions[index]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        title: const Text(
          "Promotions",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications page
            },
          ),
        ],
      ),
      body: BlocConsumer<AdsBloc, AdsState>(
        listener: (context, state) {
          if (state is AdsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  ElevatedButton(
                    onPressed: _fetchAds,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is AdsLoaded && state.promotions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No posts yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    "Be the first to create a post!",
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(
                    width: 200,
                    child: CustomButton(
                        color: Colors.grey,
                        text: 'Refresh/Reload',
                        onPressed: () async {
                          _fetchAds();
                        }),
                  ),
                ],
              ),
            );
          }

          if (state is AdsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdsLoaded) {
            promotions = state.promotions;

            return RefreshIndicator(
              onRefresh: () async => _fetchAds(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: promotions.length,
                itemBuilder: (context, index) {
                  final promotion = promotions[index];
                  final timeLeft = promotion.expiryDate != null
                      ? promotion.expiryDate!
                          .difference(DateTime.now())
                          .inHours
                          .toString()
                      : null;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PromotionDetailPage(promotion: promotion),
                        ),
                      );
                    },
                    child: PromotionCardNew(
                      club: promotion.clubName,
                      title: promotion.promotionTitle,
                      imageUrl: promotion.imageUrls.isNotEmpty
                          ? promotion.imageUrls.first
                          : 'https://placehold.co/600x400',
                      date: DateFormat.yMMMd().format(promotion.timestamp),
                      timeLeft: timeLeft,
                      onTrueVote: () => toggleTrueVote(promotion),
                      onFalseVote: () => toggleFalseVote(promotion),
                      likes: promotion.likes,
                      dislikes: promotion.dislikes,
                      hasUserVotedTrue: promotion.hasUserVotedTrue(getUserId()),
                      hasUserVotedFalse:
                          promotion.hasUserVotedFalse(getUserId()),
                      eventLink: promotion.eventLink,
                    ),
                  );
                },
              ),
            );
          }

          return const Center(child: Text("Something went wrong"));
        },
      ),
    );
  }
}

class PromotionCardNew extends StatelessWidget {
  final String club;
  final String title;
  final String imageUrl;
  final String date;
  final String? timeLeft;
  final VoidCallback onTrueVote;
  final VoidCallback onFalseVote;
  final int likes;
  final int dislikes;
  final bool hasUserVotedTrue;
  final bool hasUserVotedFalse;
  final String? eventLink;

  const PromotionCardNew({
    Key? key,
    required this.club,
    required this.title,
    required this.imageUrl,
    required this.date,
    this.timeLeft,
    required this.onTrueVote,
    required this.onFalseVote,
    required this.likes,
    required this.dislikes,
    required this.hasUserVotedTrue,
    required this.hasUserVotedFalse,
    this.eventLink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (timeLeft != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Only $timeLeft hours left',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.thumb_up,
                            color: hasUserVotedTrue ? Colors.blue : Colors.grey,
                          ),
                          onPressed: onTrueVote,
                        ),
                        Text('$likes'),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            Icons.thumb_down,
                            color: hasUserVotedFalse ? Colors.red : Colors.grey,
                          ),
                          onPressed: onFalseVote,
                        ),
                        Text('$dislikes'),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Open the event link
                        eventLink != null
                            ? launchURL(eventLink!)
                            : print('No event link provided');
                      },
                      child: const Text('Learn More'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
