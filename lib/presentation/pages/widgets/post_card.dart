import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/core/utils/utils.dart';
import 'package:campus_saga/core/utils/validators.dart';
import 'package:campus_saga/domain/entities/comment.dart';
import 'package:campus_saga/domain/entities/feedback.dart';
import 'package:campus_saga/domain/entities/post.dart';
import 'package:campus_saga/domain/entities/user.dart';
import 'package:campus_saga/presentation/bloc/issue/issue_bloc.dart';
import 'package:campus_saga/presentation/pages/widgets/comments_widget.dart';
import 'package:campus_saga/presentation/pages/widgets/custom_confirm_dialog.dart';
import 'package:campus_saga/presentation/pages/widgets/feedback_widget.dart';
import 'package:campus_saga/presentation/pages/widgets/full_post_details.dart';
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
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FullPostDetails(post: post, user: widget.user),
          ),
        );
        if (Validators.isBelogsTo(widget.user, post) &&
            Validators.isValidStudent(widget.user, post) &&
            !Validators.isValidAuthority(post, widget.user)) {
          CustomConfirmDialog.show(
            context,
            title: "Fact Check",
            message: "Is this really happening?",
            confirmButtonText: "Yes",
            cancelButtonText: "No",
            dismissButtonText: "I don't know",
            onTapDismiss: () => Navigator.pop(context),
            onTapCancel: () {
              Navigator.pop(context);
              setState(() {
                post = post.toggleFalseVote(widget.user.id);
              });
              sl<IssueBloc>().add(UpdatePostEvent(post));
            },
            onTapConfirm: () {
              Navigator.pop(context);
              setState(() {
                post = post.toggleTrueVote(widget.user.id);
              });
              sl<IssueBloc>().add(UpdatePostEvent(post));
            },
            panaraDialogType: PanaraDialogType.warning,
            barrierDismissible: false, // optional parameter (default is true)
          );
        }
      },
      onLongPress: () {
        if (Validators.isValidAdmin(widget.user, post) ||
            (Validators.isBelogsTo(widget.user, post) &&
                Validators.isValidAmbassador(widget.user, post))) {
          CustomConfirmDialog.show(
            context,
            title: "Post Deletion",
            message: "Are you sure you want to delete this post?",
            confirmButtonText: "Yes",
            cancelButtonText: "No",
            dismissButtonText: "Dismiss Dialog",
            onTapDismiss: () {
              Navigator.pop(context);
              FocusScope.of(context).unfocus();
            },
            onTapCancel: () {
              Navigator.pop(context);
              FocusScope.of(context).unfocus();
            },
            onTapConfirm: () {
              Navigator.pop(context);
              FocusScope.of(context).unfocus();
              sl<IssueBloc>().add(DeletePostEvent(post));
            },
            panaraDialogType: PanaraDialogType.warning,
            barrierDismissible: false, // optional parameter (default is true)
          );
        }
      },
      child: Card(
        elevation: 2.0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with username and timestamp
              Row(
                children: [
                  CircleAvatar(
                    child: const Icon(
                      Icons.person,
                    ),
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
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getIssueStatus(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PredictionWidget(post: post),
                ],
              ),
              const SizedBox(height: 8.0),
              LinearProgressIndicator(
                value: _calculatePercentage(post.trueVotes, post.falseVotes),
                backgroundColor: Colors.grey[400],
                minHeight: 1,
                valueColor: const AlwaysStoppedAnimation(Colors.green),
              ),
              const SizedBox(height: 15.0),
              // Post Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  post.postTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 15.0),

              // Post Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  post.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 20.0),

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
              const SizedBox(height: 15.0),
              LinearProgressIndicator(
                value: _calculatePercentage(post.agree, post.disagree),
                minHeight: 1,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(Colors.green),
              ),
              const SizedBox(height: 20.0),
              // Comments and Feedback
              Wrap(
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  CommentsWidget(
                    onDismiss: () {
                      if (Validators.isBelogsTo(widget.user, post) &&
                          Validators.isValidStudent(widget.user, post) &&
                          !Validators.isValidAuthority(post, widget.user)) {
                        if (post.feedback == null) {
                          Future.delayed(const Duration(milliseconds: 500), () {
                            CustomConfirmDialog.show(
                              context,
                              title: "Fact Check",
                              message: "Is issue still available?",
                              confirmButtonText: "Yes",
                              cancelButtonText: "No",
                              dismissButtonText: "I don't know",
                              onTapDismiss: () => Navigator.pop(context),
                              onTapCancel: () {
                                setState(() {
                                  post =
                                      post.toggleDisagreeVote(widget.user.id);
                                });
                                sl<IssueBloc>().add(UpdatePostEvent(post));
                                Navigator.pop(context);
                              },
                              onTapConfirm: () {
                                Navigator.pop(context);
                                setState(() {
                                  post = post.toggleAgreeVote(widget.user.id);
                                });
                                sl<IssueBloc>().add(UpdatePostEvent(post));
                              },
                              panaraDialogType: PanaraDialogType.warning,
                              barrierDismissible: false,
                            );
                          });
                        }
                      }
                    },
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
                  const SizedBox(width: 20.0),
                  if (Validators.isBelogsTo(widget.user, post) &&
                      Validators.isValidAuthority(post, widget.user))
                    Visibility(
                      child: FeedbackWidget(
                        onDismiss: () {},
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
                        onDismiss: () {},
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
                        onDismiss: () {
                          if (Validators.isBelogsTo(widget.user, post) &&
                              Validators.isValidStudent(widget.user, post) &&
                              !Validators.isValidAuthority(post, widget.user)) {
                            Future.delayed(const Duration(milliseconds: 500),
                                () {
                              CustomConfirmDialog.show(
                                context,
                                title: "Fact Check",
                                message: "Is this really solved?",
                                confirmButtonText: "Yes",
                                cancelButtonText: "No",
                                dismissButtonText: "I don't know",
                                onTapDismiss: () => Navigator.pop(context),
                                onTapCancel: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    post =
                                        post.toggleDisagreeVote(widget.user.id);
                                  });
                                  sl<IssueBloc>().add(UpdatePostEvent(post));
                                },
                                onTapConfirm: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    post = post.toggleAgreeVote(widget.user.id);
                                  });
                                  sl<IssueBloc>().add(UpdatePostEvent(post));
                                },
                                panaraDialogType: PanaraDialogType.warning,
                                barrierDismissible: false,
                              );
                            });
                          }
                        },
                        feedback: post.feedback,
                        onAddFeedback: (value) {
                          //show a toast
                          fToast(context,
                              message: "You are not an Authority 😒");
                        },
                        buttonName: "View Feedback",
                      ),
                      replacement: FeedbackWidget(
                          onDismiss: () {},
                          feedback: post.feedback,
                          onAddFeedback: (_) {
                            //show a toast
                            fToast(context,
                                message: "You are not an Authority 😒");
                          },
                          buttonName: "Not reviewed yet"),
                      visible: post.feedback != null,
                    ),
                ],
              ),
              const SizedBox(height: 8.0),
            ],
          ),
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
