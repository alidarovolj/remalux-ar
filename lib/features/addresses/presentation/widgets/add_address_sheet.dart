import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:remalux_ar/core/styles/constants.dart';
import 'package:remalux_ar/core/widgets/custom_text_field.dart';
import 'package:remalux_ar/features/addresses/domain/providers/addresses_provider.dart';
import 'package:remalux_ar/core/widgets/custom_snack_bar.dart';

class AddAddressSheet extends ConsumerStatefulWidget {
  const AddAddressSheet({super.key});

  @override
  ConsumerState<AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<AddAddressSheet> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _entranceController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();

  YandexMapController? _mapController;
  Timer? _debounce;
  List<SearchItem> _searchResults = [];
  bool _isSearching = false;
  bool _isSaving = false;
  Point? _selectedPoint;
  List<MapObject> mapObjects = [];
  final _mapKey = UniqueKey();

  @override
  void dispose() {
    _addressController.dispose();
    _entranceController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(YandexMapController controller) {
    setState(() {
      _mapController = controller;
    });
    _moveToAlmaty();
  }

  Future<void> _moveToAlmaty() async {
    if (_mapController == null) return;

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
  }

  void _onAddressChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchAddress(value);
    });
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final resultWithSession = YandexSearch.searchByText(
      searchText: query,
      geometry: Geometry.fromBoundingBox(
        const BoundingBox(
          southWest: Point(latitude: 43.138949, longitude: 76.789709),
          northEast: Point(latitude: 43.338949, longitude: 76.989709),
        ),
      ),
      searchOptions: const SearchOptions(
        searchType: SearchType.geo,
        geometry: true,
      ),
    );

    final results = await resultWithSession.result;
    setState(() {
      _searchResults = results.items ?? [];
      _isSearching = false;
    });
  }

  void _onAddressSelected(SearchItem result) async {
    _addressController.text = result.name;
    setState(() {
      _searchResults = [];
      _selectedPoint = result.geometry.first.point;
    });

    if (_selectedPoint != null) {
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
    }
  }

  Future<void> _saveAddress() async {
    if (_selectedPoint == null) {
      CustomSnackBar.show(
        context,
        message: 'Пожалуйста, выберите адрес на карте',
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
          message: 'Адрес успешно добавлен',
          type: SnackBarType.success,
        );
        ref.read(addressesProvider.notifier).refreshAddresses();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Не удалось сохранить адрес',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Добавить новый адрес',
              textAlign: TextAlign.center,
              style: GoogleFonts.ysabeau(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CustomTextField(
                controller: _addressController,
                onChanged: _onAddressChanged,
                label: 'Введите адрес',
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) {},
              onVerticalDragUpdate: (_) {},
              onVerticalDragEnd: (_) {},
              child: Stack(
                children: [
                  RepaintBoundary(
                    child: YandexMap(
                      key: _mapKey,
                      onMapCreated: _onMapCreated,
                      mapObjects: mapObjects,
                      onMapTap: (Point point) async {
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

                        final resultWithSession = YandexSearch.searchByPoint(
                          point: point,
                          searchOptions: const SearchOptions(
                            searchType: SearchType.geo,
                            geometry: true,
                          ),
                        );

                        final results = await resultWithSession.result;
                        if (results.items?.isNotEmpty == true) {
                          setState(() {
                            _addressController.text = results.items!.first.name;
                          });
                        }
                      },
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              IconButton(
                                onPressed: () {
                                  _mapController?.moveCamera(
                                    CameraUpdate.zoomIn(),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                color: AppColors.textPrimary,
                              ),
                              Container(
                                height: 1,
                                color: Colors.grey[300],
                              ),
                              IconButton(
                                onPressed: () {
                                  _mapController?.moveCamera(
                                    CameraUpdate.zoomOut(),
                                  );
                                },
                                icon: const Icon(Icons.remove),
                                color: AppColors.textPrimary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_searchResults.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 16,
                      right: 16,
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              title: Text(result.name),
                              subtitle: Text(
                                result.toponymMetadata?.address
                                        .formattedAddress ??
                                    result.businessMetadata?.address
                                        .formattedAddress ??
                                    '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _onAddressSelected(result),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _entranceController,
                        label: 'Подъезд',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _floorController,
                        label: 'Этаж',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _apartmentController,
                        label: 'Квартира',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Сохранить',
                            style: TextStyle(
                              fontSize: 15,
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
}
