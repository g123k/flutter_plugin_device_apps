package fr.g123k.deviceapps.listener;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;

import androidx.annotation.NonNull;

import java.util.HashSet;
import java.util.Set;

import io.flutter.plugin.common.EventChannel;

public class DeviceAppsChangedListener {

    private final DeviceAppsChangedListenerInterface callback;
    private EventChannel.EventSink eventSink;

    private BroadcastReceiver appsBroadcastReceiver;

    public DeviceAppsChangedListener(DeviceAppsChangedListenerInterface callback) {
        this.callback = callback;
        this.eventSink = null;
    }

    public void register(@NonNull Context context, EventChannel.EventSink events) {
        unregister(context);

        if (appsBroadcastReceiver == null) {
            createBroadcastReceiver();
        }

        IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(Intent.ACTION_PACKAGE_ADDED);
        intentFilter.addAction(Intent.ACTION_PACKAGE_REPLACED);
        intentFilter.addAction(Intent.ACTION_PACKAGE_CHANGED);
        intentFilter.addAction(Intent.ACTION_PACKAGE_REMOVED);
        intentFilter.addDataScheme("package");

        eventSink = events;

        context.registerReceiver(appsBroadcastReceiver, intentFilter);
    }

    private void createBroadcastReceiver() {
        appsBroadcastReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String packageName = intent.getDataString().replace("package:", "");

                boolean replacing = intent.getExtras().getBoolean(Intent.EXTRA_REPLACING, false);

                switch (intent.getAction()) {
                    case Intent.ACTION_PACKAGE_ADDED:
                        if (!replacing) {
                            onPackageInstalled(packageName);
                        }
                        break;
                    case Intent.ACTION_PACKAGE_REPLACED:
                        onPackageUpdated(packageName);
                        break;
                    case Intent.ACTION_PACKAGE_CHANGED:
                        String[] components = intent.getExtras().getStringArray(Intent.EXTRA_CHANGED_COMPONENT_NAME_LIST);
                        if (components.length == 1 && components[0].equalsIgnoreCase(packageName)) {
                            onPackageChanged(packageName);
                        }
                        break;
                    case Intent.ACTION_PACKAGE_REMOVED:
                        if (!replacing) {
                            onPackageUninstalled(packageName);
                        }
                        break;
                }
            }
        };
    }

    void onPackageInstalled(String packageName) {
        callback.onPackageInstalled(packageName, eventSink);
    }

    void onPackageUpdated(String packageName) {
        callback.onPackageUpdated(packageName, eventSink);
    }

    void onPackageUninstalled(String packageName) {
        callback.onPackageUninstalled(packageName, eventSink);
    }

    void onPackageChanged(String packageName) {
        callback.onPackageChanged(packageName, eventSink);
    }

    public void unregister(@NonNull Context context) {
        if (appsBroadcastReceiver != null) {
            context.unregisterReceiver(appsBroadcastReceiver);
            appsBroadcastReceiver = null;
        }
        
        if (eventSink != null) {
            eventSink.endOfStream();
            eventSink = null;
        }
    }

}
