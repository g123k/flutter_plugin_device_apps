import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Plugin to list the applications installed on an Android device
/// iOS is not supported
class DeviceApps {
  static const MethodChannel _channel = MethodChannel('g123k/device_apps');

  /// List installed applications on the device
  /// [includeSystemApps] will also include system apps (or pre-installed) like
  /// Phone, Settings...
  /// [includeAppIcons] will also include the icon for each app (be aware that
  /// this feature is memory-heaving, since it will load all icons).
  /// To get the icon you have to cast the object to [ApplicationWithIcon]
  /// [onlyAppsWithLaunchIntent] will only list applications when an entrypoint.
  /// It is similar to what a launcher will display
  static Future<List<Application>> getInstalledApplications(
      {bool includeSystemApps: false,
      bool includeAppIcons: false,
      bool onlyAppsWithLaunchIntent: false}) async {
    return _channel.invokeMethod('getInstalledApps', <String, bool>{
      'system_apps': includeSystemApps,
      'include_app_icons': includeAppIcons,
      'only_apps_with_launch_intent': onlyAppsWithLaunchIntent
    }).then((Object apps) {
      if (apps != null && apps is List) {
        List<Application> list = List<Application>();
        for (Object app in apps) {
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
        return List<Application>.empty();
      }
    }).catchError((Object err) {
      print(err);
      return List<Application>.empty();
    });
  }

  /// Provide all information for a given app by its [packageName]
  /// [includeAppIcon] will also include the icon for the app.
  /// To get it, you have to cast the object to [ApplicationWithIcon].
  static Future<Application> getApp(String packageName,
      [bool includeAppIcon = false]) async {
    if (packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }

    return _channel.invokeMethod('getApp', <String, Object>{
      'package_name': packageName,
      'include_app_icon': includeAppIcon
    }).then((Object app) {
      if (app != null && app is Map) {
        return Application(app);
      } else {
        return null;
      }
    }).catchError((Object err) {
      print(err);
      return null;
    });
  }

  /// Returns whether a given [packageName] is installed on the device
  /// You will then receive in return a boolean
  static Future<bool> isAppInstalled(String packageName) {
    if (packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }

    return _channel.invokeMethod(
        'isAppInstalled', <String, String>{'package_name': packageName});
  }

  /// Launch an app based on its [packageName]
  /// You will then receive in return if the app was opened
  /// (will be false if the app is not installed, or if no "launcher" intent is
  /// provided by this app)
  static Future<bool> openApp(String packageName) async {
    if (packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }
    return await _channel
        .invokeMethod('openApp', <String, String>{'package_name': packageName});
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
  // Only available with
  final ApplicationCategory category;

  factory Application(Map<String, Object> map) {
    if (map == null || map.length == 0) {
      throw Exception('The map can not be null!');
    }

    if (map.containsKey('app_icon')) {
      return ApplicationWithIcon._fromMap(map);
    } else {
      return Application._fromMap(map);
    }
  }

  Application._fromMap(Map<String, Object> map)
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
      return ApplicationCategory.productivity;
    } else {
      return ApplicationCategory.undefined;
    }
  }

  @override
  String toString() {
    return 'Application{appName: $appName, apkFilePath: $apkFilePath, packageName: $packageName, versionName: $versionName, versionCode: $versionCode, dataDir: $dataDir, systemApp: $systemApp, installTimeMillis: $installTimeMillis, updateTimeMillis: $updateTimeMillis, category: $category}';
  }
}

// Only supported with Android 26+
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

  ApplicationWithIcon._fromMap(Map<String, Object> map)
      : assert(map['app_icon'] != null),
        _icon = map['app_icon'],
        super._fromMap(map);

  Uint8List get icon => base64.decode(_icon);
}
