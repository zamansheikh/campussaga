import 'package:flutter/material.dart';
import 'package:campus_saga/domain/entities/comment.dart';
import 'package:intl/intl.dart';

class CommentsWidget extends StatefulWidget {
  final List<Comment> comments;
  final Function(String) onAddComment;
  final VoidCallback onDismiss; // Callback for when the sheet is dismissed

  const CommentsWidget({
    Key? key,
    required this.comments,
    required this.onAddComment,
    required this.onDismiss, // Required callback for dismissal
  }) : super(key: key);

  @override
  _CommentsWidgetState createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  final TextEditingController _commentController = TextEditingController();
  bool _isDismissed = false;

  void _showCommentsModal(BuildContext context) {
    _isDismissed = false; // Reset when showing modal

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (!_isDismissed) {
              _isDismissed = true;
              widget.onDismiss();
            }
          },
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Comments",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (widget.comments.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.comments.length,
                          itemBuilder: (context, index) {
                            final comment = widget.comments[index];
                            return ListTile(
                              title: Text(
                                comment.text,
                                style: const TextStyle(
                                    fontSize: 20, color: Colors.black),
                              ),
                              subtitle:
                                  Text("By: ${comment.userId.substring(0, 5)}"),
                              trailing: Text(
                                DateFormat('yyyy-MM-dd – HH:mm')
                                    .format(comment.timestamp),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            );
                          },
                        )
                      else
                        const Text("No comments yet."),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          labelText: "Write a comment...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            final newComment = _commentController.text;
                            if (newComment.isNotEmpty) {
                              widget.onAddComment(newComment);
                              _commentController.clear();
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text("Post Comment"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (!_isDismissed) {
        _isDismissed = true; // Prevent onDismiss from firing again
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCommentsModal(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.comment,
            color: Colors.blue[700],
            size: 18,
          ),
          const SizedBox(width: 4.0),
          Text(
            "Comments",
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
