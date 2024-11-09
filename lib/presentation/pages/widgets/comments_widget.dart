import 'package:flutter/material.dart';
import 'package:campus_saga/domain/entities/comment.dart';
import 'package:intl/intl.dart';

class CommentsWidget extends StatefulWidget {
  final List<Comment> comments;
  final Function(String) onAddComment;

  const CommentsWidget({
    Key? key,
    required this.comments,
    required this.onAddComment,
  }) : super(key: key);

  @override
  _CommentsWidgetState createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  final TextEditingController _commentController = TextEditingController();

  void _showCommentsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
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
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (widget.comments.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.comments.length,
                        itemBuilder: (context, index) {
                          final comment = widget.comments[index];
                          return ListTile(
                            title: Text(comment.text,
                                style: TextStyle(
                                    fontSize: 20, color: Colors.black)),
                            subtitle:
                                Text("By: ${comment.userId.substring(0, 5)}"),
                            trailing: Text(
                              DateFormat('yyyy-MM-dd – HH:mm')
                                  .format(comment.timestamp),
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          );
                        },
                      )
                    else
                      const Text("No comments yet."),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[700],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () => _showCommentsModal(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.comment, color: Colors.blue[700]),
          const SizedBox(width: 4.0),
          Text(
            "View Comments",
            style: TextStyle(color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }
}
