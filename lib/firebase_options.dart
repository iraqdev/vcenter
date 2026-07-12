import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// إعدادات Firebase الصحيحة لكل منصة (مهم لاستقبال FCM في الخلفية).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured for this app.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyATgTQGo7EANQIl3cs0JE9DoDQK5bJLQFo',
    appId: '1:414036126974:android:27bce71baee801596109af',
    messagingSenderId: '414036126974',
    projectId: 'v-center-5f74b',
    storageBucket: 'v-center-5f74b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCXPm9uDXkmXTuN1tIwh1Vgc2War5wU4b0',
    appId: '1:414036126974:ios:0901f66035f8cc516109af',
    messagingSenderId: '414036126974',
    projectId: 'v-center-5f74b',
    storageBucket: 'v-center-5f74b.firebasestorage.app',
    iosBundleId: 'com.dnzteam.vcenter',
  );
}
