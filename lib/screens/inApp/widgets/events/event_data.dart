import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class EventData {
  String eventName;
  String organizationType;
  String customOrg;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? locationAddress;
  LatLng? locationLatLng;
  List<String> eventMembers;
  List<String> eventGoals;
  List<String> audienceTags;
  bool isPublic;
  bool isPaid;
  double? eventPrice;
  String? eventCurrency;
  bool jamieEnabled;

  String status;
  String? id;

  EventData({
    required this.eventName,
    required this.organizationType,
    required this.customOrg,
    required this.selectedDate,
    required this.selectedTime,
    required this.locationAddress,
    required this.locationLatLng,
    required this.eventMembers,
    required this.eventGoals,
    required this.audienceTags,
    required this.isPublic,
    required this.isPaid,
    required this.eventPrice,
    required this.eventCurrency,
    required this.jamieEnabled,

    required this.status,
  });


  Map<String, dynamic> toMap() {
    return {
      'eventName': eventName,
      'organizationType': organizationType,
      'customOrg': customOrg,
      'selectedDate': selectedDate?.toIso8601String(),
      'selectedTime': '${selectedTime?.hour}:${selectedTime?.minute}',
      'locationAddress': locationAddress,
      'locationLatLng': {
        'lat': locationLatLng?.latitude,
        'lng': locationLatLng?.longitude,
      },
      'eventMembers': eventMembers,
      'eventGoals': eventGoals,
      'audienceTags': audienceTags,
      'isPublic': isPublic,
      'isPaid': isPaid,
      'eventPrice': eventPrice,
      'eventCurrency': eventCurrency,
      'jamieEnabled': jamieEnabled,
      'status': status,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory EventData.fromMap(Map<String, dynamic> map) {
    final timeParts = (map['selectedTime'] as String?)?.split(':') ?? ['0', '0'];
    return EventData(
      eventName: map['eventName'],
      organizationType: map['organizationType'],
      customOrg: map['customOrg'],
      selectedDate: map['selectedDate'] != null
          ? DateTime.parse(map['selectedDate'])
          : null,
      selectedTime: TimeOfDay(
        hour: int.tryParse(timeParts[0]) ?? 0,
        minute: int.tryParse(timeParts[1]) ?? 0,
      ),
      locationAddress: map['locationAddress'],
      locationLatLng: map['locationLatLng'] != null
          ? LatLng(
        map['locationLatLng']['lat'],
        map['locationLatLng']['lng'],
      )
          : null,
      eventMembers: List<String>.from(map['eventMembers'] ?? []),
      eventGoals: List<String>.from(map['eventGoals'] ?? []),
      audienceTags: List<String>.from(map['audienceTags'] ?? []),
      isPublic: map['isPublic'] ?? true,
      isPaid: map['isPaid'] ?? false,
      eventPrice: (map['eventPrice'] as num?)?.toDouble(),
      eventCurrency: map['eventCurrency'],
      jamieEnabled: map['jamieEnabled'] ?? false,
      status: map['status'] ?? "UPCOMING",
    );
  }
}
