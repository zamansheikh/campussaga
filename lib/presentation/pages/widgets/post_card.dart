import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/core/utils/utils.dart';
import 'package:campus_saga/domain/entities/comment.dart';
import 'package:campus_saga/domain/entities/feedback.dart';
import 'package:campus_saga/domain/entities/post.dart';
import 'package:campus_saga/domain/entities/user.dart';
import 'package:campus_saga/presentation/bloc/issue/issue_bloc.dart';
import 'package:campus_saga/presentation/pages/widgets/comments_widget.dart';
import 'package:campus_saga/presentation/pages/widgets/feedback_widget.dart';
import 'package:campus_saga/presentation/pages/widgets/prediction_widget.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final User user;
  const PostCard({
    Key? key,
    required this.post,
    required this.user,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // Method to calculate issue status based on timestamp and feedback
  String _getIssueStatus() {
    DateTime referenceTime =
        widget.post.feedback?.timestamp ?? widget.post.timestamp;
    final timeDifference = DateTime.now().difference(referenceTime);

    if (timeDifference.inDays > 2) {
      // If more than 2 days have passed, mark as resolved or not resolved
      return (widget.post.trueVotes > widget.post.falseVotes)
          ? "Solved"
          : "Unsolved";
    } else {
      // If less than 2 days, show as inconclusive
      return "Pending";
    }
  }

  _calculatePercentage(int trueVotes, int falseVotes) {
    final totalVotes = trueVotes + falseVotes;
    if (totalVotes == 0) {
      return 0.0;
    }
    return trueVotes / totalVotes;
  }

  @override
  Widget build(BuildContext context) {
    var post = this.widget.post;
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with username and timestamp
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Anonymous",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      timeago.format(post.timestamp),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Spacer(),
                Wrap(
                  direction: Axis.vertical,
                  children: [
                    _VoteButton(
                      icon: Icons.thumb_up,
                      color: Colors.green,
                      count: post.trueVotes,
                      label: "Vote this",
                      onPressed: () {}, // Implement agree voting
                    ),
                    _VoteButton(
                      icon: Icons.thumb_down,
                      color: Colors.red,
                      count: post.falseVotes,
                      label: "Report this",
                      onPressed: () {}, // Implement disagree voting
                    ),
                  ],
                ),
              ],
            ),
            LinearProgressIndicator(
              value: _calculatePercentage(post.trueVotes, post.falseVotes),
              backgroundColor: Colors.grey[400],
              minHeight: 1,
              valueColor: const AlwaysStoppedAnimation(Colors.green),
            ),
            const SizedBox(height: 4.0),
            // Post Title
            Text(
              post.postTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8.0),

            // Post Description
            Text(
              post.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8.0),

            // Post Images
            if (post.imageUrls.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () =>
                            _showFullImage(context, post.imageUrls[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: CachedNetworkImage(
                            imageUrl: post.imageUrls[index],
                            width: 250,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.error),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12.0),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CommentsWidget(
                  comments: post.comments,
                  onAddComment: (CommentText) {
                    final NewComment = Comment(
                      text: CommentText,
                      postId: post.id,
                      id: Uuid().v4(),
                      userId: widget.user.id,
                      timestamp: DateTime.now(),
                    );
                    setState(() {
                      post = post
                          .copyWith(comments: [...post.comments, NewComment]);
                    });
                    sl<IssueBloc>().add(AddACommentEvent(post));
                  },
                ),
                //PredictionWidget(),
                PredictionWidget(post: post),
              ],
            ),

            if (widget.user.userType == UserType.university)
              Visibility(
                child: FeedbackWidget(
                  onAddFeedback: (value) {
                    final feedback = AuthorityFeedback(
                      id: Uuid().v4(),
                      authorityId: widget.user.id,
                      postId: post.id,
                      message: value,
                      timestamp: DateTime.now(),
                    );
                    setState(() {
                      post = post.copyWith(feedback: feedback);
                    });
                    sl<IssueBloc>().add(AddAFeedbackEvent(post));
                  },
                  buttonName: "Add Feedback",
                  feedback: post.feedback,
                ),
                replacement: FeedbackWidget(
                  feedback: post.feedback,
                  onAddFeedback: (value) {
                    final feedback = AuthorityFeedback(
                      id: Uuid().v4(),
                      authorityId: widget.user.id,
                      postId: post.id,
                      message: value,
                      timestamp: DateTime.now(),
                    );
                    setState(() {
                      post = post.copyWith(feedback: feedback);
                    });
                    sl<IssueBloc>().add(AddAFeedbackEvent(post));
                  },
                  buttonName: "Already Responded",
                ),
                visible: post.feedback == null,
              )
            else
              Visibility(
                child: FeedbackWidget(
                  feedback: post.feedback,
                  onAddFeedback: (value) {
                    //show a toast
                    fToast(context, message: "You are not an Authority 😒");
                  },
                  buttonName: "View Feedback",
                ),
                replacement: FeedbackWidget(
                    feedback: post.feedback,
                    onAddFeedback: (_) {
                      //show a toast
                      fToast(context, message: "You are not an Authority 😒");
                    },
                    buttonName: "Authority is not responded yet"),
                visible: post.feedback != null,
              ),

            const SizedBox(height: 12.0),

            // Issue Resolution Section
            const Text("Is this issue resolved?"),
            LinearProgressIndicator(
              value: _calculatePercentage(post.agree, post.disagree),
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(Colors.green),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[100],
                    foregroundColor: Colors.green[800],
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text("Yes"),
                ),

                // New button showing issue status
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_getIssueStatus()),
                ),

                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    foregroundColor: Colors.red[800],
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text("No"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;
  final VoidCallback? onPressed;

  const _VoteButton({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4.0),
            Text("$label: $count"),
          ],
        ),
      ),
    );
  }
}
