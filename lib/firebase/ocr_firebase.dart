import 'package:firebase_core/firebase_core.dart';

FirebaseApp? ocrFirebaseApp;

Future<FirebaseApp> initializeOcrFirebase() async {
  if (ocrFirebaseApp != null) {
    return ocrFirebaseApp!;
  }

  ocrFirebaseApp = await Firebase.initializeApp(
    name: 'skano_storage',
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDuVFlTaveWGgdlY9y-QD08lPoA29J3Y4I',
      appId: '1:850558318388:android:7c12e3632deb3c80b35761',
      messagingSenderId: '850558318388',
      projectId: 'skano-storage',
      storageBucket: 'skano-storage.firebasestorage.app',
    ),
  );

  return ocrFirebaseApp!;
}