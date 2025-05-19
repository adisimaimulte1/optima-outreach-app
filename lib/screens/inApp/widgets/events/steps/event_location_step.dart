import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/beforeApp/widgets/buttons/bouncy_button.dart';

class EventLocationStep extends StatefulWidget {
  final Function(String address, double lat, double lng) onLocationPicked;

  final String? initialAddress;
  final LatLng? initialLatLng;
  final LatLng? initialCenter;

  const EventLocationStep({
    super.key,
    required this.onLocationPicked,
    this.initialAddress,
    this.initialLatLng,
    this.initialCenter,
  });

  @override
  State<EventLocationStep> createState() => _EventLocationStepState();
}

class _EventLocationStepState extends State<EventLocationStep> {
  final MapController _mapController = MapController();
  LatLng? _selectedLatLng;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _selectedLatLng = widget.initialLatLng;
    _selectedAddress = widget.initialAddress;
  }

  @override
  void didUpdateWidget(covariant EventLocationStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialLatLng != oldWidget.initialLatLng ||
        widget.initialAddress != oldWidget.initialAddress) {
      setState(() {
        _selectedLatLng = widget.initialLatLng;
        _selectedAddress = widget.initialAddress;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildTitle("Where will it happen?"),
            const SizedBox(height: 16),
            _buildMapWithCenterPin(),
            const SizedBox(height: 16),
            _buildLocationDisplay(),
            const SizedBox(height: 16),
            _buildConfirmButton(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 2,
          width: 220,
          color: Colors.white24,
        ),
      ],
    );
  }

  Widget _buildMapWithCenterPin() {
    if (widget.initialCenter == null) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // ✅ force full rebuild with UniqueKey
            KeyedSubtree(
              key: ValueKey(widget.initialCenter), // changes when location changes
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _selectedLatLng ?? widget.initialCenter!,
                  zoom: 13,
                  interactiveFlags: InteractiveFlag.all,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.optima',
                  ),
                ],
              ),
            ),
            Center(
              child: IgnorePointer(
                child: Icon(
                  Icons.place,
                  size: 50,
                  color: inAppForegroundColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDisplay() {
    final bool hasSelection = _selectedLatLng != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: hasSelection ? textHighlightedColor : textColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSelection ? textHighlightedColor : textDimColor,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.place,
            color: hasSelection ? inAppForegroundColor : Colors.white54,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ScrollableAddressFade(
              text: hasSelection
                  ? (_selectedAddress ?? "Loading address...")
                  : "No location selected",
              textColor: hasSelection ? inAppForegroundColor : textColor,
              backgroundColor: hasSelection ? textHighlightedColor : textColor.withOpacity(0.06),
              enableFade: hasSelection,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return BouncyButton(
      onPressed: () async {
        final center = _mapController.center;

        setState(() {
          _selectedLatLng = center;
          _selectedAddress = null;
        });

        await _updateAddressFromLatLng(center);

        if (_selectedAddress != null) {
          widget.onLocationPicked(
            _selectedAddress!,
            center.latitude,
            center.longitude,
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: textHighlightedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: textHighlightedColor,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Confirm Location",
              style: TextStyle(
                color: inAppForegroundColor,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  Future<void> _updateAddressFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _selectedAddress =
          "  ${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}  ";
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = "Unknown address";
      });
    }
  }
}




class _ScrollableAddressFade extends StatefulWidget {
  final String text;
  final Color textColor;
  final Color backgroundColor;
  final bool enableFade;

  const _ScrollableAddressFade({
    required this.text,
    required this.textColor,
    required this.backgroundColor,
    required this.enableFade,
  });

  @override
  State<_ScrollableAddressFade> createState() => _ScrollableAddressFadeState();
}


class _ScrollableAddressFadeState extends State<_ScrollableAddressFade> {
  final _scrollController = ScrollController();
  bool _showRightFade = false;
  bool _showLeftFade = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableFade) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
      _scrollController.addListener(_handleScroll);
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || !widget.enableFade) return;

    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;

    final showRight = (max - current) > 8;
    final showLeft = current > 8;

    if (_showRightFade != showRight || _showLeftFade != showLeft) {
      setState(() {
        _showRightFade = showRight;
        _showLeftFade = showLeft;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scrollable text
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          alignment: Alignment.centerLeft,
          child: IntrinsicHeight(
            child: widget.enableFade
              ? ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.07, 0.98, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: _buildScrollableText(),
          )
              : _buildScrollableText(),
        ),
        ),
        if (widget.enableFade && _showLeftFade)
          _buildSideFade(left: true),

        if (widget.enableFade && _showRightFade)
          _buildSideFade(left: false),
      ],
    );
  }

  Widget _buildScrollableText() {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.text,
            style: TextStyle(
              color: widget.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 1.3,
            ),
            overflow: TextOverflow.visible,
            softWrap: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSideFade({required bool left}) {
    return Align(
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      child: IgnorePointer(
        child: Stack(
          children: [
            Container(
              width: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: left ? Alignment.centerRight : Alignment.centerLeft,
                  end: left ? Alignment.centerLeft : Alignment.centerRight,
                  colors: [
                    widget.backgroundColor,
                    widget.backgroundColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            if (!left)
              Container(
                width: 30,
                alignment: Alignment.center,
                child: Text(
                  "...",
                  style: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
