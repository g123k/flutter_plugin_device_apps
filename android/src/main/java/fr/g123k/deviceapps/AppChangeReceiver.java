package fr.g123k.deviceapps;

import android.Manifest;
import android.annotation.TargetApi;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import java.util.Date;

import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;

import static io.flutter.plugin.common.PluginRegistry.Registrar;

class AppChangeReceiver implements StreamHandler {
    private final Registrar registrar;
    private BroadcastReceiver receiver;
    private EventSink sink;

    AppChangeReceiver(Registrar registrar) {
        this.registrar = registrar;
    }

    @TargetApi(Build.VERSION_CODES.KITKAT)
    @Override
    public void onListen(Object arguments, EventSink events) {
        receiver = createAppChangeReceiver(events);
        registrar.context().registerReceiver(receiver, new IntentFilter(Intent.ACTION_PACKAGE_ADDED));
        sink = events;
    }

    @Override
    public void onCancel(Object o) {
        registrar.context().unregisterReceiver(receiver);
        receiver = null;
    }

    private BroadcastReceiver createAppChangeReceiver(final EventSink events) {
        return new BroadcastReceiver() {
            @TargetApi(Build.VERSION_CODES.KITKAT)
            @Override
            public void onReceive(Context context, Intent intent) {
                try {
                    events.success("Some data");
                } catch (Exception e) {
                    Log.d("AppChangeReceiver", e.toString());
                }
            }
        };
    }
}