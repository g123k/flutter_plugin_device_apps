import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class DeviceApps {
  static const MethodChannel _channel =
      const MethodChannel('g123k/device_apps');

  static Future<List<Application>> getInstalledApplications(
      {bool includeSystemApps: false,
      bool includeAppIcons: false,
      bool onlyAppsWithLaunchIntent: false}) async {
    return _channel.invokeMethod('getInstalledApps', {
      'system_apps': includeSystemApps,
      'include_app_icons': includeAppIcons,
      'only_apps_with_launch_intent': onlyAppsWithLaunchIntent
    }).then((apps) {
      if (apps != null && apps is List) {
        List<Application> list = new List();
        for (var app in apps) {
          if (app is Map) {
            try {
              list.add(Application(app));
            } catch (e) {
              if (e is AssertionError) {
                print('[DeviceApps] Unable to add the following app: $app');
              } else {
                print('[DeviceApps] $e');
              }
            }
          }
        }

        return list;
      } else {
        return List<Application>(0);
      }
    }).catchError((err) {
      print(err);
      return List<Application>(0);
    });
  }

  static Future<Application> getApp(String packageName,
      [bool includeAppIcon = false]) async {
    if (packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }

    return _channel.invokeMethod('getApp', {
      'package_name': packageName,
      'include_app_icon': includeAppIcon
    }).then((app) {
      if (app != null && app is Map) {
        return Application(app);
      } else {
        return null;
      }
    }).catchError((err) {
      print(err);
      return null;
    });
  }

  static Future<bool> isAppInstalled(String packageName) async {
    if (packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }

    bool isAppInstalled = await _channel
        .invokeMethod('isAppInstalled', {'package_name': packageName});
    return isAppInstalled;
  }

  static Future<bool> openApp(String packageName) async {
    if (packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }
    return await _channel
        .invokeMethod('openApp', {'package_name': packageName});
  }

  static Future<bool> openAppInfoScreen(String packageName) async {
    if (packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }
    return await _channel
        .invokeMethod('openAppInfoScreen', {'package_name': packageName});
  }

  static Future<bool> uninstallApp(String packageName) async {
    if (packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }
    return await _channel
        .invokeMethod('uninstallApp', {'package_name': packageName});
  }
}

class Application {
  final String appName;
  final String apkFilePath;
  final String packageName;
  final String versionName;
  final int versionCode;
  final String dataDir;
  final bool systemApp;
  final int installTimeMillis;
  final int updateTimeMillis;
  final ApplicationCategory category;

  factory Application(Map map) {
    if (map == null || map.length == 0) {
      throw Exception('The map can not be null!');
    }

    if (map.containsKey('app_icon')) {
      return ApplicationWithIcon._fromMap(map);
    } else {
      return Application._fromMap(map);
    }
  }

  Application._fromMap(Map map)
      : assert(map['app_name'] != null),
        assert(map['apk_file_path'] != null),
        assert(map['package_name'] != null),
        assert(map['version_name'] != null),
        assert(map['version_code'] != null),
        assert(map['data_dir'] != null),
        assert(map['system_app'] != null),
        assert(map['install_time'] != null),
        assert(map['update_time'] != null),
        appName = map['app_name'],
        apkFilePath = map['apk_file_path'],
        packageName = map['package_name'],
        versionName = map['version_name'],
        versionCode = map['version_code'],
        dataDir = map['data_dir'],
        systemApp = map['system_app'],
        installTimeMillis = map['install_time'],
        updateTimeMillis = map['update_time'],
        category = _parseCategory(map['category']);

  /// [https://developer.android.com/reference/kotlin/android/content/pm/ApplicationInfo]
  static ApplicationCategory _parseCategory(Object category) {
    if (category == null || (category is num && category < 0)) {
      return ApplicationCategory.undefined;
    } else if (category == 0) {
      return ApplicationCategory.game;
    } else if (category == 1) {
      return ApplicationCategory.audio;
    } else if (category == 2) {
      return ApplicationCategory.video;
    } else if (category == 3) {
      return ApplicationCategory.image;
    } else if (category == 4) {
      return ApplicationCategory.social;
    } else if (category == 5) {
      return ApplicationCategory.news;
    } else if (category == 6) {
      return ApplicationCategory.maps;
    } else if (category == 7) {
      return ApplicationCategory.game;
    }
  }

  @override
  String toString() {
    return 'Application{appName: $appName, apkFilePath: $apkFilePath, packageName: $packageName, versionName: $versionName, versionCode: $versionCode, dataDir: $dataDir, systemApp: $systemApp, installTimeMillis: $installTimeMillis, updateTimeMillis: $updateTimeMillis, category: $category}';
  }
}

enum ApplicationCategory {
  audio,
  game,
  image,
  maps,
  news,
  productivity,
  social,
  video,
  undefined
}

class ApplicationWithIcon extends Application {
  final String _icon;

  ApplicationWithIcon._fromMap(Map map)
      : assert(map['app_icon'] != null),
        _icon = map['app_icon'],
        super._fromMap(map);

  get icon => base64.decode(_icon);
}

/// A App change receiver that creates a stream of app changes
///
///
/// Usage:
///
/// ```dart
/// var receiver = AppChangeReceiver();
/// receiver.onAppChangeReceived.listen((AppChange appChange) => ...);
/// ```
class AppChangeReceiver {
  static AppChangeReceiver _instance;
  final EventChannel _channel;
  Stream<AppChange> _onAppChangeReceived;

  factory AppChangeReceiver() {
    if (_instance == null) {
      final EventChannel eventChannel = const EventChannel(
          "g123k/device_apps/changeAppEvent", const JSONMethodCodec());
      _instance = new AppChangeReceiver._private(eventChannel);
    }
    return _instance;
  }

  AppChangeReceiver._private(this._channel);

  /// Create a stream that collect received Apps
  Stream<AppChange> get onAppChangeReceived {
    if (_onAppChangeReceived == null) {
      _onAppChangeReceived =
          _channel.receiveBroadcastStream().map((dynamic event) {
            if (event != null && event is Map) {
              return AppChange(event);
            }
          });
    }
    return _onAppChangeReceived;
  }
}

class AppChange {
  final String packageName;
  final AppChangeAction action;

  factory AppChange(Map map) {
    if (map == null || map.length == 0) {
      throw Exception('The map can not be null!');
    }
    return AppChange._fromMap(map);
  }

  AppChange._fromMap(Map map)
      : assert(map['package_name'] != null),
        packageName = map['package_name'],
        action = _parseAction(map['action']);

  static AppChangeAction _parseAction(dynamic action) {
    if (action == "android.intent.action.PACKAGE_ADDED")
      return AppChangeAction.PACKAGE_ADDED;
    else if (action == "android.intent.action.PACKAGE_REMOVED")
      return AppChangeAction.PACKAGE_REMOVED;
    else if (action == "android.intent.action.PACKAGE_REPLACED")
      return AppChangeAction.PACKAGE_REPLACED;
    else
      return AppChangeAction.UNKNOWN;
  }
}

enum AppChangeAction {
  PACKAGE_ADDED,
  PACKAGE_REMOVED,
  PACKAGE_REPLACED,
  UNKNOWN
}