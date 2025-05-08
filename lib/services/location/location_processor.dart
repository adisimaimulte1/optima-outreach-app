import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LocationProcessor {

  /// Public method to get location, reverse geocode, and update Firestore.
  static Future<void> updateUserCountryCode() async {
    try {
      // Check location permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        await handlePermissionDenied();
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Get placemarks for reverse geocoding
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final countryCode = placemarks.first.isoCountryCode?.toUpperCase() ?? 'UNKNOWN';


      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'countryCode': countryCode,
        });
        debugPrint("✅ Country code $countryCode saved to Firestore.");
      }
    } catch (e) {
      debugPrint("❌ Failed to determine country code: $e");
    }
  }

  /// Called when location permission is denied.
  static Future<void> handlePermissionDenied() async {
    debugPrint("❌ Location permission denied");
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'countryCode': 'UNKNOWN',
      });
    }
  }
}
