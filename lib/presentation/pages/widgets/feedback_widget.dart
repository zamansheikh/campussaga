import 'package:flutter/material.dart';
import 'package:campus_saga/domain/entities/feedback.dart';
import 'package:intl/intl.dart';

class FeedbackWidget extends StatefulWidget {
  final AuthorityFeedback? feedback;
  final Function(String) onAddFeedback;
  final String buttonName;
  final VoidCallback onDismiss;

  const FeedbackWidget({
    Key? key,
    this.feedback,
    required this.onAddFeedback,
    required this.buttonName,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _FeedbackWidgetState createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isDismissed = false;

  void _showFeedbackModal(BuildContext context) {
    _isDismissed = false; // Reset flag when showing modal

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
                        "Feedback",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (widget.feedback != null)
                        ListTile(
                          title: Text(
                            widget.feedback!.message,
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          subtitle: Text(
                            "By: ${widget.feedback!.authorityId.substring(0, 5)}(Authority)",
                          ),
                          trailing: Text(
                            DateFormat('yyyy-MM-dd – HH:mm')
                                .format(widget.feedback!.timestamp),
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        const Text("No feedback yet."),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _feedbackController,
                        decoration: const InputDecoration(
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
          ),
        );
      },
    ).whenComplete(() {
      if (!_isDismissed) {
        _isDismissed = true;
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showFeedbackModal(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.feedback,
              ),
              const SizedBox(width: 4.0),
              Text(
                widget.buttonName,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
