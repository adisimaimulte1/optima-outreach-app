import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  RewardedAd? _rewardedAd;
  bool _isAdReady = false;

  void loadAd({required Function onAdLoaded}) {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-7393750397776697/9485750962',
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdReady = true;
          onAdLoaded();
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  void showAd({
    required VoidCallback onEarnedReward,
    required VoidCallback onAdClosed,
  }) {
    if (_rewardedAd != null && _isAdReady) {
      _rewardedAd!.show(
        onUserEarnedReward: (_, reward) {
          onEarnedReward();
        },
      );

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          _rewardedAd = null;
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Ad failed to show: $error');
          _rewardedAd = null;
          onAdClosed();
        },
      );
    }
  }
}
