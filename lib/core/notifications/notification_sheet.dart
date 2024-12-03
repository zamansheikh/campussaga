import 'package:campus_saga/core/notifications/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

void showNotificationsSheet(BuildContext context) {
  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Replace with your actual notifications list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: 10, // Replace with actual notifications count
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () async {
                          await FirebaseMessaging.instance.subscribeToTopic('news');
                          final notificationService =
                              NotificationService.instance;
                          await notificationService
                              .showNotificationWithImageFromAssets(
                            id: 1,
                            title: "Exciting News!",
                            body:
                                "Check out this amazing picture! Stay tuned for more updates.",
                            imageAsset: "assets/temp/jenny.jpg",
                            payload: 'Check out this amazing picture!',
                          );
                        },
                        child: ListTile(
                          leading: Icon(Icons.notification_important),
                          title: Text('Notification Title $index'),
                          subtitle: Text('Notification Body $index'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
