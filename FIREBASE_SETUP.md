 From any directory, run this command:
dart pub global activate flutterfire_cli

Then, at the root of your Flutter project directory, run this command:
flutterfire configure --project=bookly-57cbb

This automatically registers your per-platform apps with Firebase and adds a lib/firebase_options.dart configuration file to your Flutter project. 

 To initialize Firebase, call Firebase.initializeApp from the firebase_core package with the configuration from your new firebase_options.dart file:
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';


// ...


await Firebase.initializeApp(

    options: DefaultFirebaseOptions.currentPlatform,

);