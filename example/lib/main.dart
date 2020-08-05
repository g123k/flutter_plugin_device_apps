import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: ListAppsPages()));

class ListAppsPages extends StatefulWidget {
  @override
  _ListAppsPagesState createState() => _ListAppsPagesState();
}

class _ListAppsPagesState extends State<ListAppsPages> {
  bool _showSystemApps = false;
  bool _onlyLaunchableApps = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Installed applications'),
        actions: <Widget>[
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<String>>[
                PopupMenuItem<String>(
                    value: 'system_apps', child: Text('Toggle system apps')),
                PopupMenuItem<String>(
                  value: 'launchable_apps',
                  child: Text('Toggle launchable apps only'),
                )
              ];
            },
            onSelected: (String key) {
              if (key == 'system_apps') {
                setState(() {
                  _showSystemApps = !_showSystemApps;
                });
              }
              if (key == 'launchable_apps') {
                setState(() {
                  _onlyLaunchableApps = !_onlyLaunchableApps;
                });
              }
            },
          )
        ],
      ),
      body: _ListAppsPagesContent(
          includeSystemApps: _showSystemApps,
          onlyAppsWithLaunchIntent: _onlyLaunchableApps,
          key: GlobalKey()),
    );
  }
}

class _ListAppsPagesContent extends StatelessWidget {
  final bool includeSystemApps;
  final bool onlyAppsWithLaunchIntent;

  const _ListAppsPagesContent(
      {Key key,
      this.includeSystemApps: false,
      this.onlyAppsWithLaunchIntent: false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Application>>(
        future: DeviceApps.getInstalledApplications(
            includeAppIcons: true,
            includeSystemApps: includeSystemApps,
            onlyAppsWithLaunchIntent: onlyAppsWithLaunchIntent),
        builder: (BuildContext context, AsyncSnapshot<List<Application>> data) {
          if (data.data == null) {
            return const Center(child: CircularProgressIndicator());
          } else {
            List<Application> apps = data.data;
            print(apps);
            return Scrollbar(
              child: ListView.builder(
                  itemBuilder: (BuildContext context, int position) {
                    Application app = apps[position];
                    return Column(
                      children: <Widget>[
                        ListTile(
                          leading: app is ApplicationWithIcon
                              ? CircleAvatar(
                                  backgroundImage: MemoryImage(app.icon),
                                  backgroundColor: Colors.white,
                                )
                              : null,
                          onTap: () => DeviceApps.openApp(app.packageName),
                          title: Text('${app.appName} (${app.packageName})'),
                          subtitle: Text('Version: ${app.versionName}\n'
                              'System app: ${app.systemApp}\n'
                              'APK file path: ${app.apkFilePath}\n'
                              'Data dir: ${app.dataDir}\n'
                              'Installed: ${DateTime.fromMillisecondsSinceEpoch(app.installTimeMillis).toString()}\n'
                              'Updated: ${DateTime.fromMillisecondsSinceEpoch(app.updateTimeMillis).toString()}'),
                        ),
                        Divider(
                          height: 1.0,
                        )
                      ],
                    );
                  },
                  itemCount: apps.length),
            );
          }
        });
  }
}
