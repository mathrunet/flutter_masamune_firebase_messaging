part of masamune.firebase.messaging;

final firebaseMessagingProvider = ModelProvider(
  (_) => FirebaseMessagingModel(),
);

class FirebaseMessagingModel extends MapModel<dynamic> {
  FirebaseMessagingModel() : super();

  @protected
  FirebaseMessaging get messaging {
    return FirebaseMessaging.instance;
  }

  late final String serverKey;

  final List<void Function(FirebaseMessagingModel messaging)> _callback = [];

  late final NavigatorState navigator;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  Future<FirebaseMessagingModel> initialize(BuildContext context,
      {required String serverKey,
      List<void Function(FirebaseMessagingModel messaging)> callback = const [],
      List<String> subscribe = const []}) async {
    if (Config.isWeb) {
      throw Exception("This platform is not supported.");
    }
    navigator = Navigator.of(context);
    serverKey = serverKey;
    if (callback.isNotEmpty) {
      _callback.addAll(callback);
    }
    await _initialize();
    subscribe.forEach((topic) {
      _subscribe(topic);
    });
    return this;
  }

  FirebaseMessagingModel listen(
    void Function(FirebaseMessagingModel messaging) callback,
  ) {
    if (Config.isWeb) {
      throw Exception("This platform is not supported.");
    }
    if (!isInitialized) {
      debugPrint(
          "It has not been initialized. Please initialize it by executing [initialize()].");
      return this;
    }
    if (!_callback.contains(callback)) {
      _callback.add(callback);
    }
    return this;
  }

  FirebaseMessagingModel unlisten(
    void Function(FirebaseMessagingModel messaging) callback,
  ) {
    if (Config.isWeb) {
      throw Exception("This platform is not supported.");
    }
    if (!isInitialized) {
      debugPrint(
          "It has not been initialized. Please initialize it by executing [initialize()].");
      return this;
    }
    _callback.remove(callback);
    return this;
  }

  /// Send a message to a specific topic.
  ///
  /// [title]: Notification Title.
  /// [text]: Notification Text.
  /// [topic]: Destination topic.
  /// [data]: Data to be included in the notification.
  Future<FirebaseMessagingModel> send({
    required String title,
    required String text,
    required String topic,
    Map<String, dynamic> data = const {},
  }) async {
    if (Config.isWeb) {
      throw Exception("This platform is not supported.");
    }
    if (!isInitialized) {
      debugPrint(
          "It has not been initialized. Please initialize it by executing [initialize()].");
      return this;
    }
    assert(title.isNotEmpty && text.isNotEmpty,
        "There is no information in the message.");
    assert(topic.isNotEmpty, "You have not specified a topic.");
    assert(serverKey.isNotEmpty, "The server key is not set.");
    try {
      data["click_action"] = "FLUTTER_NOTIFICATION_CLICK";
      await post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Authorization": "key=$serverKey",
        },
        body: jsonEncode(
          <String, dynamic>{
            "notification": <String, dynamic>{"title": title, "body": text},
            "priority": "high",
            "data": data,
            "to": "/topics/$topic"
          },
        ),
      );
    } catch (e) {
      rethrow;
    }
    return this;
  }

  /// Subscribe to a new topic.
  ///
  /// [topic]: The topic you want to subscribe to.
  FirebaseMessagingModel subscribe(String topic) {
    if (!isInitialized) {
      debugPrint(
          "It has not been initialized. Please initialize it by executing [initialize()].");
      return this;
    }
    assert(topic.isNotEmpty, "You have not specified a topic.");
    _subscribe(topic);
    return this;
  }

  /// The topic you want to unsubscribe.
  ///
  /// [topic]: The topic you want to unsubscribe to.
  FirebaseMessagingModel unsubscribe(String topic) {
    if (!isInitialized) {
      debugPrint(
          "It has not been initialized. Please initialize it by executing [initialize()].");
      return this;
    }
    assert(topic.isNotEmpty, "You have not specified a topic.");
    _unsubscribe(topic);
    return this;
  }

  @override
  void dispose() {
    super.dispose();
    _callback.clear();
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    FirebaseMessaging.onBackgroundMessage((message) async {});
  }

  Future<void> _initialize() async {
    await FirebaseCore.initialize();
    _onMessageSubscription = FirebaseMessaging.onMessage.listen(_done);
    _onMessageOpenedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_done);
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessageHandler);
    await messaging.setForegroundNotificationPresentationOptions(
        sound: true, badge: true, alert: true);
    _isInitialized = true;
  }

  @override
  bool get notifyOnChangeValue => true;
  @override
  bool get notifyOnChangeMap => false;

  Future<void> _done(RemoteMessage message) async {
    final data = message.data;
    if (data.isNotEmpty) {
      data.forEach((key, value) => this[key] = value);
      if (data.containsKey("data")) {
        (data["data"] as Map).forEach((key, value) => this[key] = value);
      }
      if (data.containsKey("aps")) {
        (data["aps"] as Map).forEach((key, value) {
          this[key] = value;
          if (key == "alert") {
            (value as Map).forEach((k, v) => this[k] = v);
          }
        });
      }
      if (data.containsKey("notification")) {
        (data["notification"] as Map)
            .forEach((key, value) => this[key] = value);
      }
    }
    _callback.forEach((element) => element.call(this));
    notifyListeners();
  }

  Future<void> _onBackgroundMessageHandler(RemoteMessage message) async {
    _done(message);
  }

  void _subscribe(String topic) {
    if (Config.isIOS) {
      topic = "/topics/" + topic;
    }
    messaging.subscribeToTopic(topic);
  }

  void _unsubscribe(String topic) {
    if (Config.isIOS) {
      topic = "/topics/" + topic;
    }
    messaging.unsubscribeFromTopic(topic);
  }

  /// True if the billing system has been initialized.
  bool get isInitialized => _isInitialized;
  bool _isInitialized = false;
}
