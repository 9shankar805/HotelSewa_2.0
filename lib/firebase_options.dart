// Generated from google-services.json (Android) and GoogleService-Info.plist (iOS)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  /// Values sourced from android/app/google-services.json (package: com.hotelsewa.app)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYQXmv8LAdj_CqkD89FGWtyFjc-XD1dk4',
    appId: '1:664870792174:android:caa1dd7cb7429b3b493cff',
    messagingSenderId: '664870792174',
    projectId: 'hotelsewa-66c35',
    storageBucket: 'hotelsewa-66c35.firebasestorage.app',
    androidClientId: '664870792174-1pl1vsco8ug3c5t9tt8n9g1263bttq4h.apps.googleusercontent.com',
  );

  /// Values sourced from ios/Runner/GoogleService-Info.plist (bundle: com.hotelsewa.app)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCf8Dfwu84GEs2s5qaSjVrxiFUJweUbFno',
    appId: '1:664870792174:ios:e49ac23a764a24df493cff',
    messagingSenderId: '664870792174',
    projectId: 'hotelsewa-66c35',
    storageBucket: 'hotelsewa-66c35.firebasestorage.app',
    iosClientId: '664870792174-jvd5i82d0hi2ba1b3j1ifvs61s6s8pqi.apps.googleusercontent.com',
    iosBundleId: 'com.hotelsewa.app',
  );

  /// Web config — update with values from Firebase console if web support is needed
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBYQXmv8LAdj_CqkD89FGWtyFjc-XD1dk4',
    appId: '1:664870792174:web:caa1dd7cb7429b3b493cff',
    messagingSenderId: '664870792174',
    projectId: 'hotelsewa-66c35',
    storageBucket: 'hotelsewa-66c35.firebasestorage.app',
  );
}
