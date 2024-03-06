import 'dart:async';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:pavli_text/start.dart' as start;
import 'package:pavli_text/testing.dart';
import 'package:pavli_text/utils/utils.dart';
import 'package:pavli_text/auth/verify_email_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pavli_text/auth/auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'firebase_options.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

//
//_________________________________MAIN FUNC____________________________________
//
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final savedThemeMode = await AdaptiveTheme.getThemeMode();

  // ignore: prefer_const_constructors
  runApp(MyApp(
    savedThemeMode: savedThemeMode,
  ));
}

class MyApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  final AdaptiveThemeMode? savedThemeMode;

  const MyApp({super.key, required this.savedThemeMode});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _messageStreamController = BehaviorSubject<RemoteMessage>();

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await Firebase.initializeApp();
    log("Handling a background message: ${message.messageId}");
    log('Message data: ${message.data}');
    log('Message notification: ${message.notification?.title}');
    log('Message notification: ${message.notification?.body}');
  }

  void notificationSetup() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted premission");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("Provisional premision");
    } else {
      print("No premision");
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Handling a foreground message: ${message.messageId}');
      log('Message data: ${message.data}');
      log('Message notification: ${message.notification?.title}');
      log('Message notification: ${message.notification?.body}');

      _messageStreamController.sink.add(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("message opened app");
      Navigator.of(context).pushNamed("/test-page");
    });
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  @override
  void initState() {
    notificationSetup();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      //light: ThemeData(),
      light: ThemeData.light(useMaterial3: false),
      dark: ThemeData.dark(useMaterial3: false),
      initial: widget.savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        scaffoldMessengerKey: messengerKey,
        title: 'PavliText',
        theme: theme,
        darkTheme: darkTheme,
        initialRoute: "/",
        routes: {
          "/": ((context) => const MyMainPage(title: "PavliText")),
          "/contacts-page": (context) => const start.StartPage(),
          "/test-page": (context) => const Testing()
        },
        /*home: MyMainPage(title: 'App'),*/
      ),
    );
  }
}

class MyMainPage extends StatefulWidget {
  const MyMainPage({super.key, required this.title});

  final String title;

  @override
  State<MyMainPage> createState() => _MyMainPageState();
}

class _MyMainPageState extends State<MyMainPage> {
  //
  // if user is signed up the app goes to __email verification widget__
  //
  // else it takes him to widget responsibile for __authentication__
  //
  final bool logedIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // __email verification widget__
            return const VerifyEmailPage();
          } else {
            // __authentication__
            return const AuthPage();
          }
        },
      ),
    );
  }
}
