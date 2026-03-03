import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_saga/core/injection_container.dart';
import 'package:campus_saga/core/theme/app_theme.dart';
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
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final User user;
  const PostCard({Key? key, required this.post, required this.user})
    : super(key: key);

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
              sl<IssueBloc>().add(AddAFeedbackEvent(post));
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
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(50),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withAlpha(25),
                    child: const Icon(
                      Iconsax.user,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anonymous',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          timeago.format(post.timestamp),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: _getIssueStatus()),
                  const SizedBox(width: 6),
                  PredictionWidget(post: post),
                ],
              ),

              // ── Truth bar ────────────────────────────────────────
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _calculatePercentage(post.trueVotes, post.falseVotes),
                  backgroundColor: Colors.red.withAlpha(40),
                  minHeight: 4,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                ),
              ),

              // ── Title ────────────────────────────────────────────
              const SizedBox(height: 12),
              Text(
                post.postTitle,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),

              // ── Description ──────────────────────────────────────
              const SizedBox(height: 6),
              Text(
                post.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20.0),

              // ── Images ───────────────────────────────────────────
              if (post.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: post.imageUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () =>
                              _showFullImage(context, post.imageUrls[index]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: post.imageUrls[index],
                              width: 220,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 220,
                                color: const Color(0xFFF0F2FF),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 220,
                                color: const Color(0xFFF0F2FF),
                                child: const Icon(
                                  Iconsax.image,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              // ── Agree bar ─────────────────────────────────────────
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _calculatePercentage(post.agree, post.disagree),
                  minHeight: 4,
                  backgroundColor: Colors.grey.withAlpha(50),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              // Comments and Feedback
              Wrap(
                children: [
                  SizedBox(width: 10),
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
                                  post = post.toggleDisagreeVote(
                                    widget.user.id,
                                  );
                                });
                                sl<IssueBloc>().add(AddAgreeVoteEvent(post));
                                Navigator.pop(context);
                              },
                              onTapConfirm: () {
                                Navigator.pop(context);
                                setState(() {
                                  post = post.toggleAgreeVote(widget.user.id);
                                });
                                sl<IssueBloc>().add(AddAgreeVoteEvent(post));
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
                        post = post.copyWith(
                          comments: [...post.comments, NewComment],
                        );
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
                            Future.delayed(
                              const Duration(milliseconds: 500),
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
                                      post = post.toggleDisagreeVote(
                                        widget.user.id,
                                      );
                                    });
                                    sl<IssueBloc>().add(
                                      AddAgreeVoteEvent(post),
                                    );
                                  },
                                  onTapConfirm: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      post = post.toggleAgreeVote(
                                        widget.user.id,
                                      );
                                    });
                                    sl<IssueBloc>().add(UpdatePostEvent(post));
                                  },
                                  panaraDialogType: PanaraDialogType.warning,
                                  barrierDismissible: false,
                                );
                              },
                            );
                          }
                        },
                        feedback: post.feedback,
                        onAddFeedback: (value) {
                          //show a toast
                          fToast(
                            context,
                            message: "You are not an Authority 😒",
                          );
                        },
                        buttonName: "View Feedback",
                      ),
                      replacement: FeedbackWidget(
                        onDismiss: () {},
                        feedback: post.feedback,
                        onAddFeedback: (_) {
                          //show a toast
                          fToast(
                            context,
                            message: "You are not an Authority 😒",
                          );
                        },
                        buttonName: "Not reviewed yet",
                      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) =>
                const Icon(Iconsax.image, size: 48),
          ),
        ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon) = switch (status) {
      'Solved' => (
        const Color(0xFF4CAF50).withAlpha(25),
        const Color(0xFF2E7D32),
        Iconsax.tick_circle,
      ),
      'Unsolved' => (
        Colors.red.withAlpha(25),
        Colors.red.shade700,
        Iconsax.close_circle,
      ),
      _ => (Colors.orange.withAlpha(25), Colors.orange.shade800, Iconsax.clock),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
