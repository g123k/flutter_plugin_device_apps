import 'dart:convert';
import 'dart:typed_data';

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

class App {
  final String appName;
  final String apkFilePath;
  final String packageName;
  final String versionName;
  final int versionCode;
  final String dataDir;
  final bool systemApp;
  final int installTimeMillis;
  final int updateTimeMillis;
  final Uint8List appIcon;
  final ApplicationCategory category;

  App({
    this.appIcon,
    this.appName,
    this.apkFilePath,
    this.packageName,
    this.versionName,
    this.versionCode,
    this.dataDir,
    this.systemApp,
    this.installTimeMillis,
    this.updateTimeMillis,
    this.category,
  });

  static List<App> fromList(List<Map<String, dynamic>> list) {
    return List<App>.generate(list.length, (int i) {
      final Map<dynamic, dynamic> map = list[i];
      assert(map['app_name'] != null);
      assert(map['apk_file_path'] != null);
      assert(map['package_name'] != null);
      assert(map['version_name'] != null);
      assert(map['version_code'] != null);
      assert(map['system_app'] != null);
      assert(map['install_time'] != null);
      assert(map['update_time'] != null);
      if (map['app_icon'] != null) {
        return App(
            appName: map['app_name'],
            apkFilePath: map['apk_file_path'],
            packageName: map['package_name'],
            versionName: map['version_name'],
            versionCode: map['version_code'],
            dataDir: map['data_dir'],
            systemApp: map['system_app'],
            installTimeMillis: map['install_time'],
            updateTimeMillis: map['update_time'],
            appIcon: base64Decode(map['app_icon']),
            category: _parseCategory(map['category']));
      } else {
        return App(
            appName: map['app_name'],
            apkFilePath: map['apk_file_path'],
            packageName: map['package_name'],
            versionName: map['version_name'],
            versionCode: map['version_code'],
            dataDir: map['data_dir'],
            systemApp: map['system_app'],
            installTimeMillis: map['install_time'],
            updateTimeMillis: map['update_time'],
            category: _parseCategory(map['category'])
            // appIcon: base64Decode(map['app_icon']),
            );
      }
    });
  }

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
