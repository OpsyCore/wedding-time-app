import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCjvNPZt6CIpPGoI8F0hJOl_WhqguxzzYo',
    authDomain: 'wedding-time-8240d.firebaseapp.com',
    projectId: 'wedding-time-8240d',
    storageBucket: 'wedding-time-8240d.firebasestorage.app',
    messagingSenderId: '351828238865',
    appId: '1:351828238865:web:baed40fb3ca08f82d847b0',
    measurementId: 'G-VPJ1P5ZV6K',
  );
}