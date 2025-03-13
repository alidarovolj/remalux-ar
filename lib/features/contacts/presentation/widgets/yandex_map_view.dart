import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class YandexMapView extends StatefulWidget {
  final double latitude;
  final double longitude;

  const YandexMapView({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<YandexMapView> createState() => _YandexMapViewState();
}

class _YandexMapViewState extends State<YandexMapView> {
  YandexMapController? _mapController;
  final List<MapObject> _mapObjects = [];
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YandexMap(
      key: ValueKey('yandex_map_${widget.longitude}_${widget.latitude}'),
      onMapCreated: (controller) {
        if (!_disposed) {
          _mapController = controller;
          _addPlacemark();
        }
      },
      mapObjects: _mapObjects,
      zoomGesturesEnabled: true,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      logoAlignment: const MapAlignment(
        horizontal: HorizontalAlignment.right,
        vertical: VerticalAlignment.bottom,
      ),
    );
  }

  void _addPlacemark() async {
    if (_disposed || _mapController == null) return;

    final placemark = PlacemarkMapObject(
      mapId: MapObjectId('placemark_${widget.longitude}_${widget.latitude}'),
      point: Point(
        longitude: widget.latitude,
        latitude: widget.longitude,
      ),
      opacity: 1,
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage('assets/images/map_pin.png'),
          scale: 0.8,
        ),
      ),
    );

    await _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(
            longitude: widget.latitude,
            latitude: widget.longitude,
          ),
          zoom: 16,
        ),
      ),
    );

    if (!_disposed) {
      setState(() {
        _mapObjects.add(placemark);
      });
    }
  }
}
