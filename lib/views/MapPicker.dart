import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:geocoding/geocoding.dart';

class MapPicker extends StatefulWidget {
  final LatLng? initialLocation;
  const MapPicker({Key? key, this.initialLocation}) : super(key: key);

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  late GoogleMapController _mapController;
  LatLng? _pickedLocation;
  final String _googleApiKey = 'AIzaSyBgeRLX_sa19dBqj75ovixwgnr21ZV-xzU'; // ضع مفتاحك هنا

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation ?? LatLng(33.3152, 44.3661); // بغداد افتراضي
  }

  void _onMapTap(LatLng pos) {
    setState(() {
      _pickedLocation = pos;
    });
  }

  Future<void> _searchPlace() async {
    var p = await PlacesAutocomplete.show(
      context: context,
      apiKey: _googleApiKey,
      mode: Mode.overlay,
      language: 'ar',
      hint: 'ابحث عن مكان...'
    );
    if (p != null && p.description != null) {
      List<Location> locations = await locationFromAddress(p.description!);
      if (locations.isNotEmpty) {
        final lat = locations.first.latitude;
        final lng = locations.first.longitude;
        _mapController.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
        setState(() {
          _pickedLocation = LatLng(lat, lng);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('حدد موقع المحل'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _searchPlace,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation!,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController.setMapStyle(_nightMapStyle);
            },
            onTap: _onMapTap,
            markers: _pickedLocation == null
                ? {}
                : {
                    Marker(
                      markerId: MarkerId('picked'),
                      position: _pickedLocation!,
                    ),
                  },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_pickedLocation != null) {
                  Navigator.of(context).pop(_pickedLocation);
                }
              },
              child: Text('تأكيد الموقع', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  final String _nightMapStyle = '''[
  {
    "elementType": "geometry",
    "stylers": [
      {"color": "#242f3e"}
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#746855"}
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {"color": "#242f3e"}
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#d59563"}
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#d59563"}
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {"color": "#263c3f"}
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#6b9a76"}
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {"color": "#38414e"}
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {"color": "#212a37"}
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#9ca5b3"}
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {"color": "#746855"}
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {"color": "#1f2835"}
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#f3d19c"}
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      {"color": "#2f3948"}
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#d59563"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {"color": "#17263c"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#515c6d"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [
      {"color": "#17263c"}
    ]
  }
]''';
}
