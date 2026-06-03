// File generated manually from google-services.json
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYQXmv8LAdj_CqkD89FGWtyFjc-XD1dk4',
    appId: '1:664870792174:android:caa1dd7cb7429b3b493cff',
    messagingSenderId: '664870792174',
    projectId: 'hotelsewa-66c35',
    storageBucket: 'hotelsewa-66c35.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBYQXmv8LAdj_CqkD89FGWtyFjc-XD1dk4',
    appId: '1:664870792174:ios:caa1dd7cb7429b3b493cff',
    messagingSenderId: '664870792174',
    projectId: 'hotelsewa-66c35',
    storageBucket: 'hotelsewa-66c35.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBYQXmv8LAdj_CqkD89FGWtyFjc-XD1dk4',
    appId: '1:664870792174:web:caa1dd7cb7429b3b493cff',
    messagingSenderId: '664870792174',
    projectId: 'hotelsewa-66c35',
    storageBucket: 'hotelsewa-66c35.firebasestorage.app',
  );
}
