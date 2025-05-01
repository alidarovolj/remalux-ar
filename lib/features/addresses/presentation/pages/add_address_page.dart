import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_text_field.dart';
import 'package:remalux_ar/core/widgets/custom_app_bar.dart';
import 'package:remalux_ar/features/addresses/domain/providers/addresses_provider.dart';
import 'package:remalux_ar/core/widgets/custom_snack_bar.dart';
import 'package:easy_localization/easy_localization.dart';

class AddAddressPage extends ConsumerStatefulWidget {
  const AddAddressPage({super.key});

  @override
  ConsumerState<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends ConsumerState<AddAddressPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _entranceController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  YandexMapController? _mapController;
  Timer? _debounce;
  bool _isSaving = false;
  Point? _selectedPoint;
  List<MapObject> mapObjects = [];
  final _mapKey = UniqueKey();
  bool _isMapReady = false;

  @override
  void dispose() {
    _addressController.dispose();
    _entranceController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _debounce?.cancel();
    if (_mapController != null) {
      _mapController!.dispose();
      _mapController = null;
    }
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  void _onMapCreated(YandexMapController controller) {
    if (!mounted) return;
    setState(() {
      _mapController = controller;
      _isMapReady = true;
    });
    Future.delayed(const Duration(milliseconds: 100), _moveToAlmaty);
  }

  Future<void> _moveToAlmaty() async {
    if (_mapController == null || !mounted) return;

    try {
      await _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: Point(
              latitude: 43.238949,
              longitude: 76.889709,
            ),
            zoom: 12,
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error moving camera: $e');
      }
    }
  }

  void _onAddressChanged(String value) {
    // Пустая реализация
  }

  void _onAddressSelected(SearchItem result) async {
    _addressController.text = result.name;
    setState(() {
      _selectedPoint = result.geometry.first.point;
    });

    if (_selectedPoint != null && _mapController != null && mounted) {
      try {
        await _mapController!.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _selectedPoint!,
              zoom: 17,
            ),
          ),
        );

        setState(() {
          mapObjects = [
            PlacemarkMapObject(
              mapId: const MapObjectId('selected_address'),
              point: _selectedPoint!,
              icon: PlacemarkIcon.single(
                PlacemarkIconStyle(
                  image: BitmapDescriptor.fromAssetImage(
                      'lib/core/assets/images/point.png'),
                  scale: 0.8,
                  anchor: const Offset(0.5, 1.0),
                ),
              ),
              opacity: 1.0,
            ),
          ];
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error setting address: $e');
        }
      }
    }
  }

  Future<void> _saveAddress() async {
    if (_selectedPoint == null) {
      CustomSnackBar.show(
        context,
        message: 'addresses.add.error.select_address'.tr(),
        type: SnackBarType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(addressesProvider.notifier).addAddress(
            address: _addressController.text,
            latitude: _selectedPoint!.latitude,
            longitude: _selectedPoint!.longitude,
            entrance: _entranceController.text.isNotEmpty
                ? _entranceController.text
                : null,
            floor:
                _floorController.text.isNotEmpty ? _floorController.text : null,
            apartment: _apartmentController.text.isNotEmpty
                ? _apartmentController.text
                : null,
          );

      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.show(
          context,
          message: 'addresses.add.success'.tr(),
          type: SnackBarType.success,
        );
        ref.read(addressesProvider.notifier).refreshAddresses();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'addresses.add.error.save_failed'.tr(),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _openAddressSearch() async {
    final TextEditingController searchController = TextEditingController();
    List<SearchItem> searchResults = [];
    bool isSearching = false;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'addresses.add.search_address'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'addresses.add.search_address'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  if (value.isEmpty) {
                    setState(() {
                      searchResults = [];
                      isSearching = false;
                    });
                    return;
                  }

                  if (_debounce?.isActive ?? false) _debounce?.cancel();
                  _debounce =
                      Timer(const Duration(milliseconds: 500), () async {
                    setState(() => isSearching = true);

                    try {
                      final searchResult = await YandexSearch.searchByText(
                        searchText: value,
                        geometry: Geometry.fromBoundingBox(
                          const BoundingBox(
                            southWest: Point(
                                latitude: 43.138949, longitude: 76.789709),
                            northEast: Point(
                                latitude: 43.338949, longitude: 76.989709),
                          ),
                        ),
                        searchOptions: const SearchOptions(
                          searchType: SearchType.geo,
                          geometry: true,
                        ),
                      );

                      final results = await searchResult.$2;
                      setState(() {
                        searchResults = results.items ?? [];
                        isSearching = false;
                      });
                    } catch (e) {
                      setState(() {
                        isSearching = false;
                      });
                      if (kDebugMode) {
                        print('Error searching: $e');
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(searchResults[index].name),
                      subtitle: Text(
                        searchResults[index]
                                .toponymMetadata
                                ?.address
                                .formattedAddress ??
                            searchResults[index]
                                .businessMetadata
                                ?.address
                                .formattedAddress ??
                            '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        _onAddressSelected(searchResults[index]);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'addresses.add.title'.tr(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  bottom: -30,
                  child: RepaintBoundary(
                    child: _buildYandexMap(),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.gps_fixed,
                      color: AppColors.primary,
                    ),
                    onPressed: _moveToAlmaty,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  readOnly: true,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'addresses.add.search_address'.tr(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _openAddressSearch,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _entranceController,
                        label: 'addresses.add.entrance'.tr(),
                        keyboardType: TextInputType.number,
                        hintText: 'addresses.add.entrance_hint'.tr(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _floorController,
                        label: 'addresses.add.floor'.tr(),
                        keyboardType: TextInputType.number,
                        hintText: 'addresses.add.floor_hint'.tr(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _apartmentController,
                  label: 'addresses.add.apartment'.tr(),
                  keyboardType: TextInputType.number,
                  hintText: 'addresses.add.apartment_hint'.tr(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'addresses.add.save'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYandexMap() {
    return YandexMap(
      key: _mapKey,
      onMapCreated: _onMapCreated,
      mapObjects: mapObjects,
      onMapTap: (Point point) async {
        await _mapController?.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: point,
              zoom: 17,
            ),
          ),
        );

        setState(() {
          _selectedPoint = point;
          mapObjects = [
            PlacemarkMapObject(
              mapId: const MapObjectId('selected_address'),
              point: point,
              icon: PlacemarkIcon.single(
                PlacemarkIconStyle(
                  image: BitmapDescriptor.fromAssetImage(
                      'lib/core/assets/images/point.png'),
                  scale: 0.8,
                  anchor: const Offset(0.5, 1.0),
                ),
              ),
              opacity: 1.0,
            ),
          ];
        });

        try {
          final searchResult = await YandexSearch.searchByPoint(
            point: point,
            searchOptions: const SearchOptions(
              searchType: SearchType.geo,
              geometry: true,
            ),
          );
          final results = await searchResult.$2;
          if (results.items != null && results.items!.isNotEmpty) {
            final address = results.items!.first;
            setState(() {
              _addressController.text = address.name;
            });
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error searching by point: $e');
          }
        }
      },
    );
  }
}
