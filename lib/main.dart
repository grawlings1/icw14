import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

Future<void> _messageHandler(RemoteMessage message) async {
  print(message.notification?.body);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Messaging',
      routes: {
        '/detail': (context) => DetailPage(),
      },
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _token = "";
  List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.getToken().then((value) {
      setState(() {
        _token = value;
      });
      print(_token);
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String type = message.data['type'] ?? 'regular';
      if (type == 'important') {
        HapticFeedback.vibrate();
      }
      setState(() {
        _history.add({
          'title': message.notification?.title ?? "",
          'body': message.notification?.body ?? ""
        });
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(type == 'important'
              ? "Important Notification"
              : message.notification?.title ?? ""),
          content: Text(message.notification?.body ?? ""),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            )
          ],
        ),
      );
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      String? link = message.data['link'];
      if (link != null) {
        Navigator.pushNamed(context, '/detail', arguments: link);
      }
    });
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationHistoryPage(history: _history),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Messaging'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("ICW14", style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openHistory,
              child: Text("View Notification History"),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationHistoryPage extends StatelessWidget {
  final List<Map<String, String>> history;
  NotificationHistoryPage({required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification History"),
      ),
      body: history.isEmpty
          ? Center(child: Text("No notifications received."))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(history[index]['title']!),
                  subtitle: Text(history[index]['body']!),
                );
              },
            ),
    );
  }
}

class DetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String link = ModalRoute.of(context)!.settings.arguments as String;
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail'),
      ),
      body: Center(child: Text("Deep Link: $link")),
    );
  }
}
