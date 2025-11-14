import 'package:camp_nest/feature/presentation/screens/notification_detail.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  void firebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print(token);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final Title = message.notification?.title ?? "N/A";
      final Body = message.notification?.body ?? "N/A";

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(Title),
              content: Text(
                Body,
                maxLines: 1,
                style: TextStyle(overflow: TextOverflow.ellipsis),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                NotificationDetail(title: Title, body: Body),
                      ),
                    );
                  },
                  child: Text('Next'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
              ],
            ),
      );
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final Title = message.notification?.title ?? "N/A";
      final Body = message.notification?.body ?? "N/A";

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationDetail(title: Title, body: Body),
        ),
      );
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final Title = message.notification?.title ?? "N/A";
        final Body = message.notification?.body ?? "N/A";

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationDetail(title: Title, body: Body),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    firebaseMessaging();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Push Notifications'),
      ),
      body: const Center(child: Text('Notification Screen')),
    );
  }
}
