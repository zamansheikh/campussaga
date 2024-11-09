import 'package:flutter/material.dart';
import 'package:campus_saga/domain/entities/feedback.dart';
import 'package:intl/intl.dart';

class FeedbackWidget extends StatefulWidget {
  final AuthorityFeedback? feedback;
  final Function(String) onAddFeedback;
  final String buttonName;

  const FeedbackWidget({
    Key? key,
    this.feedback,
    required this.onAddFeedback,
    required this.buttonName,
  }) : super(key: key);

  @override
  _FeedbackWidgetState createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget> {
  final TextEditingController _feedbackController = TextEditingController();

  void _showFeedbackModal(BuildContext context) {
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
                      "Feedback",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (widget.feedback != null)
                      ListTile(
                        title: Text(widget.feedback!.message,
                            style:
                                TextStyle(fontSize: 20, color: Colors.black)),
                        subtitle: Text(
                          "By: ${widget.feedback!.authorityId.substring(0, 5)}(Authority)",
                        ),
                        trailing: Text(
                          DateFormat('yyyy-MM-dd – HH:mm')
                              .format(widget.feedback!.timestamp),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      )
                    else
                      const Text("No feedback yet."),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _feedbackController,
                      decoration: InputDecoration(
                        labelText: "Write feedback...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          final newFeedback = _feedbackController.text;
                          if (newFeedback.isNotEmpty) {
                            widget.onAddFeedback(newFeedback);
                            _feedbackController.clear();
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text("Post Feedback"),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => _showFeedbackModal(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.feedback, color: Colors.blue[700]),
              const SizedBox(width: 4.0),
              Text(
                widget.buttonName,
                style: TextStyle(color: Colors.blue[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
