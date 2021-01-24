import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Plugin to list applications installed on an Android device
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
  //

  static Future<List<Application>> getInstalledApplications(
      {bool includeSystemApps: false,
      bool includeAppIcons: false,
      bool onlyAppsWithLaunchIntent: false}) async {
    try {
      final List data =
          await _channel.invokeMethod('getInstalledApps', <String, bool>{
        'system_apps': includeSystemApps,
        'include_app_icons': includeAppIcons,
        'only_apps_with_launch_intent': onlyAppsWithLaunchIntent
      });
      return data;
    } catch (e) {
      throw Exception(e);
    }
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
        return Application._(app);
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

  // This return List<Map<String, dynamic>> you have a util class in this package called App which converts this List<Map> to List<App> you just need to do
  // App.fromList(List list);
  // that's it.
  // here we are not doing this because if you want to parse this into a diffrent isolate you can do that.
  // this is the benefit of not doing it here.
  static Future<List> getAppByApkFile(List<String> list) async {
    final List data = await _channel.invokeMethod(
        'getAppByApkFiles', <String, List<String>>{'paths': list});
    return data;
  }
}

/// An application installed on the device
/// Depending on the Android version, some attributes may not be available
class Application {
  /// Displayable name of the application
  final String appName;

  /// Full path to the base APK for this application
  final String apkFilePath;

  /// Name of the package
  final String packageName;

  /// Public name of the application (eg: 1.0.0)
  /// The version name of this package, as specified by the <manifest> tag's
  /// `versionName` attribute
  final String versionName;

  /// Unique version id for the application
  final int versionCode;

  /// Full path to the default directory assigned to the package for its
  /// persistent data
  final String dataDir;

  /// Whether the application is installed in the device's system image
  /// An application downloaded by the user won't be a system app
  final bool systemApp;

  /// The time at which the app was first installed
  final int installTimeMillis;

  /// The time at which the app was last updated
  final int updateTimeMillis;

  /// The category of this application
  /// The information may come from the application itself or the system
  final ApplicationCategory category;

  factory Application._(Map<Object, Object> map) {
    if (map == null || map.length == 0) {
      throw Exception('The map can not be null!');
    }

    if (map.containsKey('app_icon')) {
      return ApplicationWithIcon._fromMap(map);
    } else {
      return Application._fromMap(map);
    }
  }

  Application._fromMap(Map<Object, Object> map)
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

  /// Mapping of Android categories
  /// [https://developer.android.com/reference/kotlin/android/content/pm/ApplicationInfo]
  /// [category] is null on Android < 26
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
    return 'Application{'
        'appName: $appName, '
        'apkFilePath: $apkFilePath, '
        'packageName: $packageName, '
        'versionName: $versionName, '
        'versionCode: $versionCode, '
        'dataDir: $dataDir, '
        'systemApp: $systemApp, '
        'installTimeMillis: $installTimeMillis, '
        'updateTimeMillis: $updateTimeMillis, '
        'category: $category}';
  }
}

/// A category provided by the system (Only supported with Android 26+)
/// [https://developer.android.com/reference/kotlin/android/content/pm/ApplicationInfo]
enum ApplicationCategory {
  /// Category for apps which primarily work with audio or music, such as
  /// music players.
  audio,

  /// Category for apps which are primarily games.
  game,

  /// Category for apps which primarily work with images or photos, such as
  /// camera or gallery apps.
  image,

  /// Category for apps which are primarily maps apps, such as navigation apps.
  maps,

  /// Category for apps which are primarily news apps, such as newspapers,
  /// magazines, or sports apps.
  news,

  /// Category for apps which are primarily productivity apps, such as cloud
  /// storage or workplace apps.
  productivity,

  /// Category for apps which are primarily social apps, such as messaging,
  /// communication, email, or social network apps.
  social,

  /// Category for apps which primarily work with video or movies, such as
  /// streaming video apps.
  video,

  /// Value when category is undefined.
  undefined
}

/// If the [includeAppIcons] attribute is provided, this class will be used.
/// To display an image simply use the [Image.memory] widget.
/// Example:
///
/// ```
/// Image.memory(app.icon)
/// ```
class ApplicationWithIcon extends Application {
  final String _icon;

  ApplicationWithIcon._fromMap(Map<Object, Object> map)
      : assert(map['app_icon'] != null),
        _icon = map['app_icon'],
        super._fromMap(map);

  /// Icon of the application to use in conjunction with [Image.memory]
  Uint8List get icon => base64.decode(_icon);
}
