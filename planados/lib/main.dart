import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const VoyagePlannerApp(),
    ),
  );
}

Future<FirebaseApp> _initializeFirebase() async {
  if (kIsWeb) {
    // Web configuration
    return await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBYMkZtWFsApRit1WFaVv2IrFCDSXaCaXA",
        appId: "1:1013458299991:android:d2caf9860bd2ec68458712",
        messagingSenderId: "1013458299991",
        projectId: "planados-c1951",
        databaseURL:
            "https://planados-c1951-default-rtdb.asia-southeast1.firebasedatabase.app",
      ),
    );
  } else {
    // Mobile platforms - try auto-init first, fall back to manual if needed
    try {
      return await Firebase.initializeApp();
    } catch (e) {
      // If auto-init fails, use manual configuration
      return await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBYMkZtWFsApRit1WFaVv2IrFCDSXaCaXA",
          appId: "1:1013458299991:android:d2caf9860bd2ec68458712",
          messagingSenderId: "1013458299991",
          projectId: "planados-c1951",
          storageBucket: "planados-c1951.firebasestorage.app",
          databaseURL:
              "https://planados-c1951-default-rtdb.asia-southeast1.firebasedatabase.app",
        ),
      );
    }
  }
}

class VoyagePlannerApp extends StatelessWidget {
  const VoyagePlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Planados',
          theme: themeProvider.getThemeData(),
          debugShowCheckedModeBanner: false,
          home: FutureBuilder(
            future: _initializeFirebase(),
            builder: (context, snapshot) {
              // Check for errors
              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Firebase Initialization Error',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Please add google-services.json to android/app/',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Once complete, show login screen
              if (snapshot.connectionState == ConnectionState.done) {
                return const LoginScreen();
              }

              // Otherwise, show loading indicator
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flight_takeoff,
                        size: 80,
                        color: themeProvider.getThemeData().primaryColor,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Planados',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Loading...'),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
