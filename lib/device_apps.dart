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
}

class Application {
  final String appName;
  final String apkFilePath;
  final String packageName;
  final String versionName;
  final int versionCode;
  final String dataDir;
  final bool systemApp;
  final int installTimeMilis;
  final int updateTimeMilis;

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
        installTimeMilis = map['install_time'],
        updateTimeMilis = map['update_time'];

  @override
  String toString() {
    return 'App name: $appName, Package name: $packageName, Version name: $versionName, Version code: $versionCode';
  }
}

class ApplicationWithIcon extends Application {
  final String _icon;

  ApplicationWithIcon._fromMap(Map map)
      : assert(map['app_icon'] != null),
        _icon = map['app_icon'],
        super._fromMap(map);

  get icon => base64.decode(_icon);
}
