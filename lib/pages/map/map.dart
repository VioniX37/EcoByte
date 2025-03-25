import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class EWasteMapPage extends StatefulWidget {
  const EWasteMapPage({Key? key}) : super(key: key);

  @override
  State<EWasteMapPage> createState() => _EWasteMapPageState();
}

class _EWasteMapPageState extends State<EWasteMapPage> {
  // List of e-waste recycling centers in India with their coordinates
  final List<EWasteCenter> recyclingCenters = [
    EWasteCenter(
      name: "Clean Kerala Company",
      location: LatLng(10.0159, 76.3419), // Kochi
      address: "Building No. 27/588, Vikas Bhavan, Kochi, Kerala 682020",
      phone: "+91-484-2336154",
    ),
    EWasteCenter(
      name: "Earth Sense Recyclers",
      location: LatLng(8.5074, 76.9730), // Thiruvananthapuram
      address: "TC 23/1542, Thycaud P.O, Thiruvananthapuram, Kerala 695014",
      phone: "+91-471-2324604",
    ),
    EWasteCenter(
      name: "Attero Recycling",
      location: LatLng(28.4595, 77.0266),
      address: "Plot No. 50, Sector 5, IMT Manesar, Gurugram, Haryana",
      phone: "+91-124-4016500",
    ),
    EWasteCenter(
      name: "E-Parisaraa",
      location: LatLng(12.9716, 77.5946),
      address: "No. 30, 1st Floor, 1st Main Road, Mysore Road, Bangalore",
      phone: "+91-80-26740083",
    ),
    EWasteCenter(
      name: "Cerebra Green",
      location: LatLng(13.0878, 77.5828),
      address: "S-5, Concorde Anthuriam, Bangalore",
      phone: "+91-80-22284491",
    ),
    EWasteCenter(
      name: "Eco Recycling Ltd (Ecoreco)",
      location: LatLng(19.0760, 72.8777),
      address: "422, The Summit Business Bay, Andheri Kurla Road, Mumbai",
      phone: "+91-22-40524141",
    ),
    EWasteCenter(
      name: "Earth Sense Recycle",
      location: LatLng(17.3850, 78.4867),
      address: "8-2-684/3/25, Road No 12, Banjara Hills, Hyderabad",
      phone: "+91-40-23354440",
    ),
    EWasteCenter(
      name: "GreenTek Reman",
      location: LatLng(28.6139, 77.2090),
      address: "D-222, Okhla Industrial Area, Phase-I, New Delhi",
      phone: "+91-11-46560000",
    ),
    EWasteCenter(
      name: "Hulladek Recycling",
      location: LatLng(22.5726, 88.3639),
      address: "4, Dr. Rajendra Prasad Sarani, Kolkata",
      phone: "+91-33-40649100",
    ),
    EWasteCenter(
      name: "SIMS Recycling",
      location: LatLng(13.0827, 80.2707),
      address: "No 1, Sipcot Industrial Park, Chennai",
      phone: "+91-44-67401000",
    ),
    EWasteCenter(
      name: "TES-AMM",
      location: LatLng(12.9352, 77.6155),
      address: "46/1 Doddathogur, Electronic City, Bangalore",
      phone: "+91-80-28520392",
    ),
    EWasteCenter(
      name: "Exigo Recycling",
      location: LatLng(28.5355, 77.3910),
      address: "Plot No. 17, Udyog Kendra, Greater Noida",
      phone: "+91-120-4260400",
    ),
  ];

  final mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Waste Recycling Centers'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: LatLng(23.5937, 78.9629), // Center of India
                initialZoom: 5.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: recyclingCenters
                      .map((center) => Marker(
                            point: center.location,
                            child: GestureDetector(
                              onTap: () {
                                _showCenterDetails(center);
                              },
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40.0,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.green.shade100,
            child: const Text(
              'Tap on a marker to view details about the e-waste recycling center',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showCenterDetails(EWasteCenter center) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                center.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Address: ${center.address}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _launchPhone(center.phone),
                child: Text(
                  'Phone: ${center.phone}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => _launchMaps(center),
                  child: const Text('Get Directions'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _launchPhone(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone app')),
        );
      }
    }
  }

  void _launchMaps(EWasteCenter center) async {
    // Try Google Maps first
    final googleUrl =
        'https://www.google.com/maps/search/?api=1&query=${center.location.latitude},${center.location.longitude}';
    final Uri googleUri = Uri.parse(googleUrl);

    // Fallback to OpenStreetMap if Google fails
    final osmUrl =
        'https://www.openstreetmap.org/?mlat=${center.location.latitude}&mlon=${center.location.longitude}#map=15/${center.location.latitude}/${center.location.longitude}';
    final Uri osmUri = Uri.parse(osmUrl);

    if (await canLaunchUrl(googleUri)) {
      await launchUrl(googleUri);
    } else if (await canLaunchUrl(osmUri)) {
      await launchUrl(osmUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch any map application')),
        );
      }
    }
  }
}

class EWasteCenter {
  final String name;
  final LatLng location;
  final String address;
  final String phone;

  EWasteCenter({
    required this.name,
    required this.location,
    required this.address,
    required this.phone,
  });
}
