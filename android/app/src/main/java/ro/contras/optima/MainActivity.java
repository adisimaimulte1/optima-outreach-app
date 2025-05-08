package ro.contras.optima;

import android.os.Build;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import com.google.android.gms.ads.rewarded.ServerSideVerificationOptions;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "optima.admob/reward";
    private RewardedAd rewardedAd;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Immersive UI stuff you already had
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            getWindow().setDecorFitsSystemWindows(false);
        } else {
            getWindow().getDecorView().setSystemUiVisibility(
                    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION |
                            View.SYSTEM_UI_FLAG_LAYOUT_STABLE |
                            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            );
        }

        getWindow().setNavigationBarColor(android.graphics.Color.TRANSPARENT);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("loadAdWithUID")) {
                        String uid = call.argument("uid");
                        if (uid == null) {
                            result.error("NO_UID", "UID not provided", null);
                            return;
                        }
                        loadAdWithUid(uid, result);
                    }
                });
    }

    private void loadAdWithUid(String uid, MethodChannel.Result result) {
        AdRequest adRequest = new AdRequest.Builder().build();

        RewardedAd.load(
                this,
                "ca-app-pub-7393750397776697/9485750962", // Replace this with your real ad unit ID
                adRequest,
                new RewardedAdLoadCallback() {
                    @Override
                    public void onAdLoaded(@NonNull RewardedAd ad) {
                        ServerSideVerificationOptions ssvOptions = new ServerSideVerificationOptions.Builder()
                                .setCustomData("uid=" + uid)
                                .build();
                        ad.setServerSideVerificationOptions(ssvOptions);

                        ad.show(MainActivity.this, rewardItem -> {
                            // AdMob will trigger SSV to your server
                        });

                        result.success(true);
                    }

                    @Override
                    public void onAdFailedToLoad(@NonNull com.google.android.gms.ads.LoadAdError adError) {
                        result.error("LOAD_FAILED", adError.getMessage(), null);
                    }
                }
        );
    }
}
