package fr.g123k.deviceapps

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.text.TextUtils
import fr.g123k.deviceapps.utils.Base64Utils.encodeToBase64
import fr.g123k.deviceapps.utils.DrawableUtils.getBitmapFromDrawable
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.util.*


/**
 * DeviceAppsPlugin
 */
class DeviceAppsPlugin : FlutterPlugin, MethodCallHandler {
    private val asyncWork =  AsyncWork()
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        context = binding.applicationContext
        MethodChannel(binding.binaryMessenger, "g123k/device_apps").setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInstalledApps" -> {
                val systemApps = call.hasArgument("system_apps") && (call.argument<Boolean?>("system_apps")
                        ?: false)
                val includeAppIcons = call.hasArgument("include_app_icons") && (call.argument<Boolean?>("include_app_icons")
                        ?: false)
                val onlyAppsWithLaunchIntent = call.hasArgument("only_apps_with_launch_intent") && (call.argument<Boolean?>("only_apps_with_launch_intent")
                        ?: false)
                fetchInstalledApps(systemApps, includeAppIcons, onlyAppsWithLaunchIntent) { apps -> Handler(Looper.getMainLooper()).post { result.success(apps) } }
            }
            "getApp" -> if (!call.hasArgument("package_name") || TextUtils.isEmpty(call.argument<String?>("package_name")?: "")) {
                result.error("ERROR", "Empty or null package name", null)
            } else {
                val packageName = call.argument<String>("package_name") ?: ""
                val includeAppIcon = call.hasArgument("include_app_icon") && (call.argument<Boolean?>("include_app_icon")
                        ?: false)
                result.success(getApp(packageName, includeAppIcon))
            }
            "isAppInstalled" -> if (!call.hasArgument("package_name") || TextUtils.isEmpty(call.argument<String?>("package_name") ?: "")) {
                result.error("ERROR", "Empty or null package name", null)
            } else {
                val packageName = call.argument<String>("package_name") ?: ""
                result.success(isAppInstalled(packageName))
            }
            "openApp" -> if (!call.hasArgument("package_name") || TextUtils.isEmpty(call.argument<String?>("package_name") ?: "")) {
                result.error("ERROR", "Empty or null package name", null)
            } else {
                val packageName = call.argument<String?>("package_name") ?: ""
                result.success(openApp(packageName))
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        asyncWork.stop()
        context = null
    }

    private fun fetchInstalledApps(includeSystemApps: Boolean,
                                   includeAppIcons: Boolean,
                                   onlyAppsWithLaunchIntent: Boolean,
                                   callback: InstalledAppsCallback?) {
        asyncWork.run(Runnable {
            val installedApps = getInstalledApps(includeSystemApps, includeAppIcons, onlyAppsWithLaunchIntent)
            callback?.onInstalledAppsListAvailable(installedApps)
        })
    }

    private fun getInstalledApps(includeSystemApps: Boolean, includeAppIcons: Boolean, onlyAppsWithLaunchIntent: Boolean): List<Map<String, Any>> {
        val packageManager = context?.packageManager ?: return emptyList()
        val apps = packageManager.getInstalledPackages(0)
        val installedApps: MutableList<Map<String, Any>> = ArrayList(apps.size)
        for (pInfo in apps) {
            if (!includeSystemApps && isSystemApp(pInfo)) {
                continue
            }
            if (onlyAppsWithLaunchIntent && packageManager.getLaunchIntentForPackage(pInfo.packageName) == null) {
                continue
            }
            val map = getAppData(packageManager, pInfo, includeAppIcons)
            installedApps.add(map)
        }
        return installedApps
    }

    private fun openApp(packageName: String): Boolean {
        val launchIntent = context?.packageManager?.getLaunchIntentForPackage(packageName) ?: return false
        context?.startActivity(launchIntent)
        return true
    }

    private fun isSystemApp(pInfo: PackageInfo) : Boolean = pInfo.applicationInfo.flags and (ApplicationInfo.FLAG_SYSTEM or ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0

    private fun isAppInstalled(packageName: String) :Boolean {
        return try {
            val packageInfo = context?.packageManager?.getPackageInfo(packageName, 0)
            packageInfo != null
        } catch (ignored: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun getApp(packageName: String, includeAppIcon: Boolean): Map<String, Any>? {
        return try {
            val packageManager = context?.packageManager ?: return null
            getAppData(packageManager, packageManager.getPackageInfo(packageName, 0), includeAppIcon)
        } catch (ignored: PackageManager.NameNotFoundException) {
            null
        }
    }

    private fun getAppData(packageManager: PackageManager, pInfo: PackageInfo, includeAppIcon: Boolean): Map<String, Any> {
        val map: MutableMap<String, Any> = HashMap()
        map["app_name"] = pInfo.applicationInfo.loadLabel(packageManager).toString()
        map["apk_file_path"] = pInfo.applicationInfo.sourceDir
        map["package_name"] = pInfo.packageName
        map["version_code"] = pInfo.longVersionCode
        map["version_name"] = pInfo.versionName
        map["data_dir"] = pInfo.applicationInfo.dataDir
        map["system_app"] = isSystemApp(pInfo)
        map["install_time"] = pInfo.firstInstallTime
        map["update_time"] = pInfo.lastUpdateTime
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            map["category"] = pInfo.applicationInfo.category
        }
        if (includeAppIcon) {
            try {
                val icon = packageManager.getApplicationIcon(pInfo.packageName)
                val encodedImage = encodeToBase64(getBitmapFromDrawable(icon), Bitmap.CompressFormat.PNG, 100)
                map["app_icon"] = encodedImage
            } catch (ignored: PackageManager.NameNotFoundException) {
            }
        }
        return map
    }
}