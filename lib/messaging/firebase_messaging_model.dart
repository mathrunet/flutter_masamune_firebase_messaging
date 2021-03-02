part of masamune.firebase.messaging;

final firebaseMessagingProvider =
    ModelProvider.family<FirebaseMessagingModel, String>(
  (_, serverKey) => FirebaseMessagingModel(serverKey: serverKey),
);

class FirebaseMessagingModel extends MapModel<dynamic> {
  FirebaseMessagingModel({required this.serverKey}) : super();

  @protected
  FirebaseMessaging get messaging {
    return FirebaseMessaging.instance;
  }

  final String serverKey;

  late final NavigatorState navigator;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  Future<FirebaseMessagingModel> listen(BuildContext context,
      {List<String> subscribe = const []}) async {
    if (Config.isWeb) {
      throw Exception("This platform is not supported.");
    }
    navigator = Navigator.of(context);
    await _initialize();
    subscribe.forEach((topic) {
      _subscribe(topic);
    });
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
    assert(topic.isNotEmpty, "You have not specified a topic.");
    _subscribe(topic);
    return this;
  }

  /// The topic you want to unsubscribe.
  ///
  /// [topic]: The topic you want to unsubscribe to.
  FirebaseMessagingModel unsubscribe(String topic) {
    assert(topic.isNotEmpty, "You have not specified a topic.");
    _unsubscribe(topic);
    return this;
  }

  @override
  void dispose() {
    super.dispose();
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
}
