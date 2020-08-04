part of masamune.firebase.messaging;

/// Class for handling FirebaseMessaging.
///
/// First, do [listen] and specify the topic you want to subscribe with subscribe.
///
/// In addition, register the callback method in onMessage etc.
/// The callback will be executed when the message is received.
class FirestoreMessaging extends TaskDocument<DataField>
    implements ITask, IDataDocument<DataField> {
  /// Create a Completer that matches the class.
  ///
  /// Do not use from external class
  @override
  @protected
  Completer createCompleter() => Completer<FirestoreMessaging>();

  /// Process to create a new instance.
  ///
  /// Do not use from outside the class.
  ///
  /// [path]: Destination path.
  /// [isTemporary]: True if the data is temporary.
  @override
  @protected
  T createInstance<T extends IClonable>(String path, bool isTemporary) =>
      FirestoreMessaging._(
          path: path,
          isTemporary: isTemporary,
          group: this.group,
          order: this.order) as T;
  Firebase get _app {
    if (this.__app == null) this.__app = Firebase(this.protocol);
    return this.__app;
  }

  Firebase __app;
  FirebaseMessaging get _messaging {
    if (this.__messaging == null) this.__messaging = FirebaseMessaging();
    return this.__messaging;
  }

  FirebaseMessaging __messaging;

  /// Class for handling FirebaseMessaging.
  ///
  /// First, do [listen] and specify the topic you want to subscribe with subscribe.
  ///
  /// In addition, register the callback method in onMessage etc.
  /// The callback will be executed when the message is received.
  factory FirestoreMessaging() {
    if (Config.isWeb) {
      Log.warning("This platform is not supported.");
      return null;
    }
    FirestoreMessaging document = PathMap.get<FirestoreMessaging>(_systemPath);
    if (document != null) return document;
    Log.warning(
        "No data was found from the pathmap. Please execute [listen()] first.");
    return null;
  }

  /// Class for handling FirebaseMessaging.
  ///
  /// First, do [listen] and specify the topic you want to subscribe with subscribe.
  ///
  /// In addition, register the callback method in onMessage etc.
  /// The callback will be executed when the message is received.
  ///
  /// [subscribe]: Timeout time.
  static Future<FirestoreMessaging> listen(
      {List<String> subscribe = const []}) {
    if (Config.isWeb) {
      Log.error("This platform is not supported.");
      return Future.delayed(Duration.zero);
    }
    FirestoreMessaging document = PathMap.get<FirestoreMessaging>(_systemPath);
    if (document != null) return document.future;
    document = FirestoreMessaging._(path: _systemPath);
    document._initialize();
    subscribe?.forEach((topic) {
      document.subscribe(topic);
    });
    return document.future;
  }

  FirestoreMessaging._(
      {String path,
      Iterable<DataField> children,
      bool isTemporary = false,
      int group = 0,
      int order = 10})
      : super(
            path: path,
            children: children,
            isTemporary: isTemporary,
            group: group,
            order: order);
  static const String _systemPath = "system://firebasemessaging";
  void _initialize() async {
    try {
      if (this._app == null) this.__app = await Firebase.initialize();
      if (this._messaging == null) this.__messaging = FirebaseMessaging();
      this._messaging.configure(
          onMessage: this._done,
          onLaunch: this._done,
          onResume: this._done,
          onBackgroundMessage:
              Config.isIOS ? null : _onBackgroundMessageHandler);
      this._messaging.requestNotificationPermissions(
          const IosNotificationSettings(sound: true, badge: true, alert: true));
      this
          ._messaging
          .onIosSettingsRegistered
          .listen((IosNotificationSettings settings) {
        Log.msg("Settings registered: $settings");
      });
      if (_dataCache != null)
        this._done(_dataCache);
      else
        this.done();
    } catch (e) {
      this.error(e.toString());
    }
  }

  Future _done(Map<String, dynamic> data) async {
    if (data != null) {
      this.init();
      Map<String, dynamic> tmp = MapPool.get();
      data?.forEach((key, value) => tmp[key] = value);
      if (data.containsKey("data")) {
        (data["data"] as Map)?.forEach((key, value) => tmp[key] = value);
      }
      if (data.containsKey("aps")) {
        (data["aps"] as Map)?.forEach((key, value) {
          tmp[key] = value;
          if (key == "alert") {
            (value as Map)?.forEach((k, v) => tmp[k] = v);
          }
        });
      }
      if (data.containsKey("notification")) {
        (data["notification"] as Map)
            ?.forEach((key, value) => tmp[key] = value);
      }
      this._setInternal(tmp);
    }
    this.done();
  }

  void _setInternal(Map<String, dynamic> data) {
    if (data == null) return;
    data.forEach((key, value) {
      if (isEmpty(key) || value == null) return;
      for (MapEntry<String, FirestoreMetaFilter> tmp
          in FirestoreMeta.filter.entries) {
        value = tmp.value(key + tmp.key, value, data);
      }
      this[key] = value;
    });
    List<String> list = List.from(this.data.keys);
    for (String tmp in list) {
      if (!data.containsKey(tmp)) this.remove(tmp);
    }
    list.release();
    Log.ast("Updated data: %s (%s)", [this.path, this.runtimeType]);
  }

  /// Subscribe to a new topic.
  ///
  /// [topic]: The topic you want to subscribe to.
  FirestoreMessaging subscribe(String topic) {
    if (isEmpty(topic)) return this;
    if (Config.isIOS) topic = "/topics/" + topic;
    this._messaging.subscribeToTopic(topic);
    return this;
  }

  /// The topic you want to unsubscribe.
  ///
  /// [topic]: The topic you want to unsubscribe to.
  FirestoreMessaging unsubscribe(String topic) {
    if (isEmpty(topic)) return this;
    if (Config.isIOS) topic = "/topics/" + topic;
    this._messaging.unsubscribeFromTopic(topic);
    return this;
  }

  /// Get the protocol of the path.
  @override
  String get protocol => "firestore";

  /// Get the data.
  ///
  /// Do not use from external class.
  ///
  /// When using from an external class, use getInt or getString.
  ///
  /// [key]: Key for retrieving data.
  @protected
  dynamic operator [](String key) {
    if (!this.data.containsKey(key)) return null;
    return this.data[key]?.data;
  }

  /// Set the data
  ///
  /// [key]: Key for storing data [value]: Data to store.
  void operator []=(String key, dynamic value) {
    if (value == null) {
      return;
    }
    if (this.isLock) {
      Log.warning("Data modification is prohibited.");
      return;
    }
    if (value is DataField) {
      this.set([value]);
    } else {
      if (PathFilter.setTemporary(Paths.child(this.path, key), value)) return;
      if (this.data.containsKey(key) && this.data[key] is IUnit<dynamic>) {
        this.data[key].data = value;
      } else {
        Path path = this.rawPath.clone();
        path.path = Paths.child(this.rawPath.path, key);
        this.set([DataField(path.path, value)]);
      }
    }
  }

  /// Gets value as Bool.
  ///
  /// [key]: Key for retrieving data.
  /// [defaultValue]: Initial value if there is no value.
  @override
  bool getBool(String key, [bool defaultValue = false]) {
    if (isEmpty(key) || !this.data.containsKey(key)) return defaultValue;
    DataField data = this.data[key];
    if (data == null) return defaultValue;
    return this.data[key].getBool(defaultValue);
  }

  /// Gets value as Double.
  ///
  /// [key]: Key for retrieving data.
  /// [defaultValue]: Initial value if there is no value.
  @override
  double getDouble(String key, [double defaultValue = 0]) {
    if (isEmpty(key) || !this.data.containsKey(key)) return defaultValue;
    DataField data = this.data[key];
    if (data == null) return defaultValue;
    return this.data[key].getDouble(defaultValue);
  }

  /// Gets value as Int.
  ///
  /// [key]: Key for retrieving data.
  /// [defaultValue]: Initial value if there is no value.
  @override
  int getInt(String key, [int defaultValue = 0]) {
    if (isEmpty(key) || !this.data.containsKey(key)) return defaultValue;
    DataField data = this.data[key];
    if (data == null) return defaultValue;
    return this.data[key].getInt(defaultValue);
  }

  /// Gets value as List<T>.
  ///
  /// [key]: Key for retrieving data.
  /// [defaultValue]: Initial value if there is no value.
  @override
  List<T> getList<T extends Object>(String key,
      [List<T> defaultValue = const []]) {
    if (isEmpty(key) || !this.data.containsKey(key)) return defaultValue;
    DataField data = this.data[key];
    if (data == null) return defaultValue;
    return this.data[key].getList<T>(defaultValue);
  }

  /// Gets value as Map<K,V>.
  ///
  /// [key]: Key for retrieving data.
  /// [defaultValue]: Initial value if there is no value.
  @override
  Map<K, V> getMap<K extends Object, V extends Object>(String key,
      [Map<K, V> defaultValue = const {}]) {
    if (isEmpty(key) || !this.data.containsKey(key)) return defaultValue;
    DataField data = this.data[key];
    if (data == null) return defaultValue;
    return this.data[key].getMap<K, V>(defaultValue);
  }

  /// Gets value as String.
  ///
  /// [key]: Key for retrieving data.
  /// [defaultValue]: Initial value if there is no value.
  @override
  String getString(String key, [String defaultValue = Const.empty]) {
    if (isEmpty(key) || !this.data.containsKey(key)) return defaultValue;
    DataField data = this.data[key];
    if (data == null) return defaultValue;
    return this.data[key].getString(defaultValue);
  }

  /// Get the UID of the document.
  ///
  /// If there is no value in the field, id will be output.
  String get uid => this.getString(Const.uid, this.id);

  /// Get time.
  ///
  /// UpdatedTime is output if the field has no value.
  int get time => this.getInt(Const.time, this.updatedTime);

  /// Delete the data.
  ///
  /// Used when deleting data when there is a remote or when data needs to be saved.
  @override
  Future delete() {
    throw UnimplementedError();
  }

  /// Save the data.
  ///
  /// Run if you have a remote or need to save data.
  @override
  Future<T> save<T extends IDataDocument<IDataField>>() {
    throw UnimplementedError();
  }

  static Future<dynamic> _onBackgroundMessageHandler(
      Map<String, dynamic> data) async {
    FirestoreMessaging document = PathMap.get<FirestoreMessaging>(_systemPath);
    if (document != null)
      document._done(data);
    else
      _dataCache = data;
  }

  static Map<String, dynamic> _dataCache;

  /// Update document data.
  @override
  Future<T> reload<T extends IDataDocument<IDataField>>() =>
      Future.delayed(Duration.zero);
}