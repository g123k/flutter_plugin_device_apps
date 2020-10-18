package fr.g123k.deviceapps;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Base64;

import androidx.annotation.NonNull;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.FlutterNativeView;

import static fr.g123k.deviceapps.utils.Base64Utils.encodeToBase64;
import static fr.g123k.deviceapps.utils.DrawableUtils.getBitmapFromDrawable;

/**
 * DeviceAppsPlugin
 */
public class DeviceAppsPlugin implements
        FlutterPlugin,
        MethodCallHandler,ActivityAware {

    private final int SYSTEM_APP_MASK = ApplicationInfo.FLAG_SYSTEM | ApplicationInfo.FLAG_UPDATED_SYSTEM_APP;

    private final AsyncWork asyncWork;

    public DeviceAppsPlugin() {
        this.asyncWork = new AsyncWork();
    }
                
    public static void registerWith(final Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(),"g123k/device_apps");
        channel.setMethodCallHandler(new DeviceAppsPlugin(channel, registrar.activeContext()));
    }
                
                


  @Override
  public void onDetachedFromActivityForConfigChanges() {
    // TODO: the Activity your plugin was attached to was
    // destroyed to change configuration.
    // This call will be followed by onReattachedToActivityForConfigChanges().
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding activityPluginBinding) {
    // TODO: your plugin is now attached to a new Activity
    // after a configuration change.
  }           
                

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        
    }

    private Context context;

    @Override
    @SuppressWarnings("ConstantConditions")
    public void onMethodCall(MethodCall call, @NonNull final Result result) {
        switch (call.method) {
            case "getInstalledApps":
                boolean systemApps = call.hasArgument("system_apps") && (Boolean) (call.argument("system_apps"));
                boolean includeAppIcons = call.hasArgument("include_app_icons") && (Boolean) (call.argument("include_app_icons"));
                boolean onlyAppsWithLaunchIntent = call.hasArgument("only_apps_with_launch_intent") && (Boolean) (call.argument("only_apps_with_launch_intent"));
                fetchInstalledApps(systemApps, includeAppIcons, onlyAppsWithLaunchIntent, new InstalledAppsCallback() {
                    @Override
                    public void onInstalledAppsListAvailable(final List<Map<String, Object>> apps) {
                        new Handler(Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                result.success(apps);
                            }
                        });
                    }
                });
                break;
            case "getApp":
                if (!call.hasArgument("package_name") || TextUtils.isEmpty(call.argument("package_name").toString())) {
                    result.error("ERROR", "Empty or null package name", null);
                } else {
                    String packageName = call.argument("package_name").toString();
                    boolean includeAppIcon = call.hasArgument("include_app_icon") && (Boolean) (call.argument("include_app_icon"));
                    result.success(getApp(packageName, includeAppIcon));
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
            case "openApp":
                if (!call.hasArgument("package_name") || TextUtils.isEmpty(call.argument("package_name").toString())) {
                    result.error("ERROR", "Empty or null package name", null);
                } else {
                    String packageName = call.argument("package_name").toString();
                    result.success(openApp(packageName));
                }
                break;
            default:
                result.notImplemented();
        }
    }

    private void fetchInstalledApps(final boolean includeSystemApps, final boolean includeAppIcons, final boolean onlyAppsWithLaunchIntent, final InstalledAppsCallback callback) {
        asyncWork.run(new Runnable() {

            @Override
            public void run() {
                List<Map<String, Object>> installedApps = getInstalledApps(includeSystemApps, includeAppIcons, onlyAppsWithLaunchIntent);

                if (callback != null) {
                    callback.onInstalledAppsListAvailable(installedApps);
                }
            }

        });
    }

    private List<Map<String, Object>> getInstalledApps(boolean includeSystemApps, boolean includeAppIcons, boolean onlyAppsWithLaunchIntent) {
        PackageManager packageManager = context.getPackageManager();
        List<PackageInfo> apps = packageManager.getInstalledPackages(0);
        List<Map<String, Object>> installedApps = new ArrayList<>(apps.size());

        for (PackageInfo pInfo : apps) {
            if (!includeSystemApps && isSystemApp(pInfo)) {
                continue;
            }
            if (onlyAppsWithLaunchIntent && packageManager.getLaunchIntentForPackage(pInfo.packageName) == null) {
                continue;
            }

            Map<String, Object> map = getAppData(packageManager, pInfo, includeAppIcons);
            installedApps.add(map);
        }

        return installedApps;
    }

    private boolean openApp(@NonNull String packageName) {
        Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(packageName);

        // Null pointer check in case package name was not found
        if (launchIntent != null) {
            context.startActivity(launchIntent);
            return true;
        }

        return false;
    }

    private boolean isSystemApp(PackageInfo pInfo) {
        return (pInfo.applicationInfo.flags & SYSTEM_APP_MASK) != 0;
    }

    private boolean isAppInstalled(@NonNull String packageName) {
        try {
            context.getPackageManager().getPackageInfo(packageName, 0);
            return true;
        } catch (PackageManager.NameNotFoundException ignored) {
            return false;
        }
    }

    private Map<String, Object> getApp(String packageName, boolean includeAppIcon) {
        try {
            PackageManager packageManager = context.getPackageManager();
            return getAppData(packageManager, packageManager.getPackageInfo(packageName, 0), includeAppIcon);
        } catch (PackageManager.NameNotFoundException ignored) {
            return null;
        }
    }

    private Map<String, Object> getAppData(PackageManager packageManager, PackageInfo pInfo, boolean includeAppIcon) {
        Map<String, Object> map = new HashMap<>();
        map.put("app_name", pInfo.applicationInfo.loadLabel(packageManager).toString());
        map.put("apk_file_path", pInfo.applicationInfo.sourceDir);
        map.put("package_name", pInfo.packageName);
        map.put("version_code", pInfo.versionCode);
        map.put("version_name", pInfo.versionName);
        map.put("data_dir", pInfo.applicationInfo.dataDir);
        map.put("system_app", isSystemApp(pInfo));
        map.put("install_time", pInfo.firstInstallTime);
        map.put("update_time", pInfo.lastUpdateTime);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            map.put("category", pInfo.applicationInfo.category);
        }

        if (includeAppIcon) {
            try {
                Drawable icon = packageManager.getApplicationIcon(pInfo.packageName);
                String encodedImage = encodeToBase64(getBitmapFromDrawable(icon), Bitmap.CompressFormat.PNG, 100);
                map.put("app_icon", encodedImage);
            } catch (PackageManager.NameNotFoundException ignored) {
            }
        }

        return map;
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        asyncWork.stop();
        context = null;
    }
}
