// Copyright 2021 mathru. All rights reserved.

/// Masamune firebase messaging framework library.
///
/// To use, import `package:masamune_firebase_messaging/masamune_firebase_messaging.dart`.
///
/// [mathru.net]: https://mathru.net
/// [YouTube]: https://www.youtube.com/c/mathrunetchannel
library masamune.firebase.messaging;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:masamune/masamune.dart';
import 'package:masamune_firebase/masamune_firebase.dart';
import "package:katana_firebase/katana_firebase.dart";
export 'package:masamune/masamune.dart';
export 'package:masamune_mobile/masamune_mobile.dart';
export 'package:masamune_firebase/masamune_firebase.dart';

part 'messaging/firebase_messaging_model.dart';
part 'messaging/firebase_messaging_core.dart';
