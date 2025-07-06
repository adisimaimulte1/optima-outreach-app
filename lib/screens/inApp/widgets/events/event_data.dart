import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:optima/screens/inApp/widgets/aichat/chat_message.dart';

class EventData {
  String eventName;
  String organizationType;
  String customOrg;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? locationAddress;
  LatLng? locationLatLng;
  List<String> eventManagers;
  List<Map<String, dynamic>> eventMembers;
  List<String> eventGoals;
  List<String> audienceTags;
  bool isPublic;
  bool isPaid;
  double? eventPrice;
  String? eventCurrency;
  bool jamieEnabled;

  String status;
  String? id;
  String createdBy;

  List<AiChatMessage> aiChatMessages = [];
  List<String>? tags;
  String? chatImage;


  EventData({
    required this.eventName,
    required this.organizationType,
    required this.customOrg,
    required this.selectedDate,
    required this.selectedTime,
    required this.locationAddress,
    required this.locationLatLng,
    required this.eventManagers,
    required this.eventMembers,
    required this.eventGoals,
    required this.audienceTags,
    required this.isPublic,
    required this.isPaid,
    required this.eventPrice,
    required this.eventCurrency,
    required this.jamieEnabled,
    required this.status,
    required this.createdBy,
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
      'eventGoals': eventGoals,
      'audienceTags': audienceTags,
      'isPublic': isPublic,
      'isPaid': isPaid,
      'eventPrice': eventPrice,
      'eventCurrency': eventCurrency,
      'jamieEnabled': jamieEnabled,
      'status': status,
      'eventManagers': eventManagers,
      'createdBy': createdBy,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory EventData.fromMap(
      Map<String, dynamic> map, {
        required List<QueryDocumentSnapshot<Map<String, dynamic>>> memberDocs,
        required List<QueryDocumentSnapshot<Map<String, dynamic>>> aiChatDocs,
      }) {
    final timeParts = (map['selectedTime'] as String?)?.split(':') ?? ['0', '0'];

    final List<Map<String, dynamic>> members = memberDocs.map((doc) {
      final data = doc.data();
      return {
        'email': data['email'],
        'status': data['status'],
        'invitedAt': data['invitedAt'],
      };
    }).toList();

    final List<AiChatMessage> aiMessages = aiChatDocs
        .map((doc) => AiChatMessage.fromFirestore(doc.data(), doc.id))
        .toList()
        .reversed
        .toList();



    final event = EventData(
      eventName: map['eventName'],
      organizationType: map['organizationType'],
      customOrg: map['customOrg'],
      selectedDate: map['selectedDate'] != null
          ? DateTime.tryParse(map['selectedDate']) ?? DateTime.now()
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
      eventManagers: List<String>.from(map['eventManagers'] ?? []),
      eventMembers: members,
      eventGoals: List<String>.from(map['eventGoals'] ?? []),
      audienceTags: List<String>.from(map['audienceTags'] ?? []),
      isPublic: map['isPublic'] ?? true,
      isPaid: map['isPaid'] ?? false,
      eventPrice: (map['eventPrice'] as num?)?.toDouble(),
      eventCurrency: map['eventCurrency'],
      jamieEnabled: map['jamieEnabled'] ?? false,
      status: map['status'] ?? "UPCOMING",
      createdBy: map['createdBy'] ?? "",
    );

    event.aiChatMessages = aiMessages;
    return event;
  }

  EventData copyWith({
    String? eventName,
    String? organizationType,
    String? customOrg,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    String? locationAddress,
    LatLng? locationLatLng,
    List<String>? eventManagers,
    List<Map<String, dynamic>>? eventMembers,
    List<String>? eventGoals,
    List<String>? audienceTags,
    bool? isPublic,
    bool? isPaid,
    double? eventPrice,
    String? eventCurrency,
    bool? jamieEnabled,
    String? status,
    String? id,
    String? createdBy,
    List<AiChatMessage>? aiChatMessages,
  }) {
    return EventData(
      eventName: eventName ?? this.eventName,
      organizationType: organizationType ?? this.organizationType,
      customOrg: customOrg ?? this.customOrg,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      locationAddress: locationAddress ?? this.locationAddress,
      locationLatLng: locationLatLng ?? this.locationLatLng,
      eventManagers: eventManagers ?? this.eventManagers,
      eventMembers: eventMembers ?? this.eventMembers,
      eventGoals: eventGoals ?? this.eventGoals,
      audienceTags: audienceTags ?? this.audienceTags,
      isPublic: isPublic ?? this.isPublic,
      isPaid: isPaid ?? this.isPaid,
      eventPrice: eventPrice ?? this.eventPrice,
      eventCurrency: eventCurrency ?? this.eventCurrency,
      jamieEnabled: jamieEnabled ?? this.jamieEnabled,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
    )..id = id ?? this.id
      ..aiChatMessages = aiChatMessages ?? this.aiChatMessages;
  }

  bool hasPermission(String email) {
    return email == createdBy;
  }
}
