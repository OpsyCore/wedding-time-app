// File generated against android/app/google-services.json (project
// wedding-time-8240d). Web options kept from the previous config; Android
// options use the `wedding.time.app` client (mobilesdk_app_id
// 1:351828238865:android:acf438b940068f73d847b0).
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart' show TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCjvNPZt6CIpPGoI8F0hJOl_WhqguxzzYo',
    appId: '1:351828238865:web:baed40fb3ca08f82d847b0',
    messagingSenderId: '351828238865',
    projectId: 'wedding-time-8240d',
    authDomain: 'wedding-time-8240d.firebaseapp.com',
    storageBucket: 'wedding-time-8240d.firebasestorage.app',
    measurementId: 'G-VPJ1P5ZV6K',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD844Ur_j1c4zecyfvtAaylKqbdevLlMP0',
    appId: '1:351828238865:android:acf438b940068f73d847b0',
    messagingSenderId: '351828238865',
    projectId: 'wedding-time-8240d',
    storageBucket: 'wedding-time-8240d.firebasestorage.app',
  );
}
