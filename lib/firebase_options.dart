// GENERATED FILE -- do not edit by hand

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('DefaultFirebaseOptions have not been configured for web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyABIb2mYq5UDkJE2LKJg1zYKdaef0_p998',
    appId: '1:226538204228:ios:74a8c5b57e98dc6da3e011',
    messagingSenderId: '226538204228',
    projectId: 'ai-campus-helpdesk',
    storageBucket: 'ai-campus-helpdesk.firebasestorage.app',
  );

  // Provide minimal Android options (fill with real values if you add android support)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyABIb2mYq5UDkJE2LKJg1zYKdaef0_p998',
    appId: '1:226538204228:android:REPLACE_WITH_ANDROID_APP_ID',
    messagingSenderId: '226538204228',
    projectId: 'ai-campus-helpdesk',
    storageBucket: 'ai-campus-helpdesk.firebasestorage.app',
  );
}
