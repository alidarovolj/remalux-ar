import 'package:flutter/foundation.dart';

class VisitCardType {
  final String id;
  final String name;
  final double rating;
  final String specialization;
  final int experience;
  final String location;
  final String price;
  final String avatar;
  final VoidCallback onDetails;
  final VoidCallback onReschedule;

  VisitCardType({
    required this.id,
    required this.name,
    required this.rating,
    required this.specialization,
    required this.experience,
    required this.location,
    required this.price,
    required this.avatar,
    required this.onDetails,
    required this.onReschedule,
  });
}
