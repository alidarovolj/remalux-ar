import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:remalux_ar/features/contacts/data/models/contact_model.dart';

class ContactMap extends StatefulWidget {
  final List<Contact> contacts;

  const ContactMap({
    super.key,
    required this.contacts,
  });

  @override
  State<ContactMap> createState() => _ContactMapState();
}

class _ContactMapState extends State<ContactMap> {
  YandexMapController? _mapController;
  final List<PlacemarkMapObject> _mapObjects = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    if (widget.contacts.isNotEmpty) {
      final firstContact = widget.contacts.first;
      if (firstContact.innerItems.isNotEmpty) {
        final firstItem = firstContact.innerItems.first;
        _mapController?.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: Point(
                latitude: double.parse(firstItem.latitude),
                longitude: double.parse(firstItem.longitude),
              ),
              zoom: 15,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return YandexMap(
      onMapCreated: (YandexMapController controller) {
        _mapController = controller;
        _initializeMap();
      },
      mapObjects: _mapObjects,
      onMapTap: (Point point) {
        // Handle map tap if needed
      },
      onCameraPositionChanged: (position, reason, finished) {
        // Handle camera position change if needed
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
