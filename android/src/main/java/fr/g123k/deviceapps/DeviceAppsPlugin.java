package fr.g123k.deviceapps;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.text.TextUtils;
import android.util.Log;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * DeviceAppsPlugin
 */
public class DeviceAppsPlugin implements MethodCallHandler {

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "g123k/device_apps");
        channel.setMethodCallHandler(new DeviceAppsPlugin(registrar.activeContext()));
    }

    private final int SYSTEM_APP_MASK = ApplicationInfo.FLAG_SYSTEM | ApplicationInfo.FLAG_UPDATED_SYSTEM_APP;

    private final Context context;

    private DeviceAppsPlugin(Context context) {
        this.context = context;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "getInstalledApps":
                Boolean systemApps = call.hasArgument("system_apps") && (Boolean) (call.argument("system_apps"));
                result.success(getInstalledApps(systemApps));
                break;
            case "getApp":
                if (!call.hasArgument("package_name") || TextUtils.isEmpty(call.argument("package_name").toString())) {
                    result.error("ERROR", "Empty or null package name", null);
                } else {
                    String packageName = call.argument("package_name").toString();
                    result.success(getApp(packageName));
                }
                break;
            case "isAppInstalled":
                if (!call.hasArgument("package_name") || TextUtils.isEmpty(call.argument("package_name").toString())) {
                    result.error("ERROR", "Empty or null package name", null);
                } else {
                    String packageName = call.argument("package_name").toString();
                    result.success(isAppInstalled(packageName));
                }
                break;
            default:
                result.notImplemented();
        }
    }

    private List<Map<String, Object>> getInstalledApps(boolean includeSystemApps) {
        PackageManager packageManager = context.getPackageManager();
        List<PackageInfo> apps = packageManager.getInstalledPackages(0);
        List<Map<String, Object>> installedApps = new ArrayList<>(apps.size());

        for (PackageInfo pInfo : apps) {
            if (!includeSystemApps && isSystemApp(pInfo)) {
                continue;
            }

            Map<String, Object> map = getAppData(packageManager, pInfo);
            installedApps.add(map);
        }

        return installedApps;
    }

    private boolean isSystemApp(PackageInfo pInfo) {
        return (pInfo.applicationInfo.flags & SYSTEM_APP_MASK) != 0;
    }

    private boolean isAppInstalled(String packageName) {
        try {
            context.getPackageManager().getPackageInfo(packageName, 0);
            return true;
        } catch (PackageManager.NameNotFoundException ignored) {
            return false;
        }
    }

    private Map<String, Object> getApp(String packageName) {
        try {
            PackageManager packageManager = context.getPackageManager();
            return getAppData(packageManager, packageManager.getPackageInfo(packageName, 0));
        } catch (PackageManager.NameNotFoundException ignored) {
            return null;
        }
    }

    private Map<String, Object> getAppData(PackageManager packageManager, PackageInfo pInfo) {
        Map<String, Object> map = new HashMap<>();
        map.put("app_name", pInfo.applicationInfo.loadLabel(packageManager).toString());
        map.put("package_name", pInfo.packageName);
        map.put("version_code", pInfo.versionCode);
        map.put("version_name", pInfo.versionName);
        map.put("system_app", isSystemApp(pInfo));
        return map;
    }

}
