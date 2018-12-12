import 'dart:async';

import 'package:flutter/services.dart';

class DeviceApps {
  static const MethodChannel _channel =
      const MethodChannel('g123k/device_apps');

  static Future<List<Application>> getInstalledApplications(
      {bool includeSystemApps: false}) async {
    return _channel.invokeMethod(
        'getInstalledApps', {'system_apps': includeSystemApps}).then((apps) {
      if (apps != null && apps is List) {
        List<Application> list = new List();
        for (var app in apps) {
          if (app is Map) {
            list.add(Application._fromMap(app));
          }
        }

        return list;
      }
    }).catchError((err) {
      print(err);
      return new List(0);
    });
  }

  static Future<Application> getApp(String packageName) async {
    if (packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }

    return _channel
        .invokeMethod('getApp', {'package_name': packageName}).then((app) {
      if (app != null && app is Map) {
        return Application._fromMap(app);
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
    if(packageName.isEmpty) {
      throw Exception('The package name can not be empty');
    }
    return await _channel.invokeMethod('openApp',{'package_name': packageName});
  }

}

class Application {
  final String appName;
  final String packageName;
  final String versionName;
  final bool systemApp;

  Application._fromMap(Map map)
      : appName = map['app_name'],
        packageName = map['package_name'],
        versionName = map['version_name'],
        systemApp = map['system_app'];

  @override
  String toString() {
    return 'App name: $appName, Package name: $packageName, Version name: $versionName';
  }
}
