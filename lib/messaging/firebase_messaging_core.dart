part of masamune.firebase.messaging;

class FirebaseMessagingCore {
  FirebaseMessagingCore._();

  static FirebaseMessagingModel get _messaging {
    return readProvider(firebaseMessagingProvider);
  }

  static Future<FirebaseMessagingModel> initialize(BuildContext context,
          {required String serverKey,
          List<void Function(FirebaseMessagingModel messaging)> callback =
              const [],
          List<String> subscribe = const []}) =>
      _messaging.initialize(
        context,
        serverKey: serverKey,
        callback: callback,
        subscribe: subscribe,
      );

  static FirebaseMessagingModel listen(
    void Function(FirebaseMessagingModel messaging) callback,
  ) =>
      _messaging.listen(callback);

  static FirebaseMessagingModel unlisten(
    void Function(FirebaseMessagingModel messaging) callback,
  ) =>
      _messaging.unlisten(callback);

  /// Send a message to a specific topic.
  ///
  /// [title]: Notification Title.
  /// [text]: Notification Text.
  /// [topic]: Destination topic.
  /// [data]: Data to be included in the notification.
  static Future<FirebaseMessagingModel> send({
    required String title,
    required String text,
    required String topic,
    Map<String, dynamic> data = const {},
  }) =>
      _messaging.send(
        title: title,
        text: text,
        topic: topic,
        data: data,
      );

  /// Subscribe to a new topic.
  ///
  /// [topic]: The topic you want to subscribe to.
  static FirebaseMessagingModel subscribe(String topic) =>
      _messaging.subscribe(topic);

  /// The topic you want to unsubscribe.
  ///
  /// [topic]: The topic you want to unsubscribe to.
  static FirebaseMessagingModel unsubscribe(String topic) =>
      _messaging.unsubscribe(topic);
}
