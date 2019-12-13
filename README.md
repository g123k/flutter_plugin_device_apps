# Flutter Device apps plugin

[![Pub](https://img.shields.io/pub/v/device_apps.svg)](https://pub.dartlang.org/packages/device_apps)

A plugin to get the list of installed applications (iOS is not supported yet).

## Getting Started

First, you have to import the package in your dart files with:
```dart
import 'package:device_apps/device_apps.dart';
```

## List of installed applications

To get the list of the apps installed on the device:

```dart
List<Application> apps = await DeviceApps.getInstalledApplications();
```

You can filter system apps if necessary.
Note: The list of apps is not ordered!

### Get apps with launch intent
You can now get only those apps with launch intent by using the following option. Also add `includeSystemApps` option to get all the apps that have launch intent.

```dart
// Returns a list of only those apps that have launch intent
List<Application> apps = await DeviceApps.getInstalledApplications(onlyAppsWithLaunchIntent: true, includeSystemApps: true)
```


## Get an application

To get a specific app by package name:

```dart
Application app = await DeviceApps.getApp('com.frandroid.app');
```

## Check if an application is installed

To check if an app is installed (via its package name):

```dart
bool isInstalled = await DeviceApps.isAppInstalled('com.frandroid.app');
```

## Open an application

To open an application
```dart
DeviceApps.openApp('com.frandroid.app');
```

## Displaying app icon

When calling the `getInstalledApplications()` or `getApp()` methods, you can ask for the icon.
To display the image, just call:

```dart
Image.memory(app.icon);
```




