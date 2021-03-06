# Device Apps plugin for Flutter

[![Pub](https://img.shields.io/pub/v/device_apps.svg)](https://pub.dartlang.org/packages/device_apps)

A plugin to list installed applications on an Android device (⚠️ iOS is not supported). You can also listen to app changes (eg: installations, updates…)

## Change with Android 11

Starting with Android 11, Android applications targeting API level 30, willing to list "external" applications have to declare a new "normal" permission in their `AndroidManifest.xml` file called [`QUERY_ALL_PACKAGES`](https://developer.android.com/reference/kotlin/android/Manifest.permission#query_all_packages). A few notes about this: 

- A normal permission doesn't require the user consent
- Don't worry, this plugin automatically adds the permission for you

However, publishing applications on the Google Play with this kind of feature **may change** in the future. [Quoting from the documentation](https://developer.android.com/reference/kotlin/android/Manifest.permission#query_all_packages):

> In an upcoming policy update, look for Google Play to provide guidelines for apps that need the QUERY_ALL_PACKAGES permission.

**👍 Right now, there is no limitation, but be aware that this may change in the future.**

## Getting Started

First, you have to import the package in your dart file with:
```dart
import 'package:device_apps/device_apps.dart';
```

## List of installed applications

To list applications installed on the device:

```dart
List<Application> apps = await DeviceApps.getInstalledApplications();
```

You can filter system apps if necessary.

**Note**: The list of apps is not ordered! You have to do it yourself.

### Get apps with a launch Intent
A launch Intent means you can launch the application.

To list only the apps with launch intents, simply use the `onlyAppsWithLaunchIntent: true` attribute.

```dart
// Returns a list of only those apps that have launch intent
List<Application> apps = await DeviceApps.getInstalledApplications(onlyAppsWithLaunchIntent: true, includeSystemApps: true)
```


## Get an application

To get a specific application info, please provide its package name:

```dart
Application app = await DeviceApps.getApp('com.frandroid.app');
```

## Check if an application is installed

To check if an app is installed (via its package name):

```dart
bool isInstalled = await DeviceApps.isAppInstalled('com.frandroid.app');
```

## Open an application

To open an application (with a launch Intent)
```dart
DeviceApps.openApp('com.frandroid.app');
```

## Open an application settings screen

To open an application settings screen
```dart
DeviceApps.openAppSettings('com.frandroid.app');
```

## Include application icon

When calling `getInstalledApplications()` or `getApp()` methods, you can also ask for the icon.
To display the image, just call:

```dart
Image.memory(app.icon);
```

## Listen to app changes

To listen to applications events on the device (installation, uninstallation, update, enabled or disabled):

```dart
Stream<ApplicationEvent> apps = await DeviceApps.listenToAppsChanges();
```

If you only need events for a single app, just use the `Stream` API, like so:

```dart
DeviceApps.listenToAppsChanges().where((ApplicationEvent event) => event.packageName == 'com.frandroid.app')
```