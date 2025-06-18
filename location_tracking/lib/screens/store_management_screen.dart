import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/home_controller.dart';
import '../controllers/store_controller.dart';
import 'map_location_picker.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  final StoreController storeController = Get.find();
  final HomeController homeController = Get.find();
  late final TextEditingController nameController;
  late final TextEditingController radiusController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    radiusController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Locations'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddStoreDialog(context),
          ),
        ],
      ),
      body: Obx(
        () => ListView.builder(
          itemCount: storeController.stores.length,
          itemBuilder: (context, index) {
            final store = storeController.stores[index];
            return ListTile(
              title: Text(store['name']),
              subtitle: Text(
                'Lat: ${store['latitude'].toStringAsFixed(6)}\n'
                'Lng: ${store['longitude'].toStringAsFixed(6)}\n'
                'Radius: ${store['radius']}m',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () => _showVisitHistory(context, store),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditStoreDialog(context, store),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(context, store),
                  ),
                ],
              ),
              isThreeLine: true,
            );
          },
        ),
      ),
    );
  }

  Future<void> _showAddStoreDialog(BuildContext context) async {
    nameController.clear();
    radiusController.text = '50'; // Default radius

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Store Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Store Name'),
              textCapitalization: TextCapitalization.words,
            ),
            TextField(
              controller: radiusController,
              decoration: const InputDecoration(
                labelText: 'Radius (meters)',
                hintText: 'Enter detection radius in meters',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _addStore(context, false),
            child: const Text('Current Location'),
          ),
          TextButton(
            onPressed: () => _selectLocationFromMap(context),
            child: const Text('Choose on Map'),
          ),
        ],
      ),
    );
  }

  Future<void> _addStore(BuildContext context, bool useMapCenter) async {
    final name = nameController.text.trim();
    final radius = double.tryParse(radiusController.text) ?? 50.0;

    if (name.isEmpty) {
      Get.snackbar('Error', 'Please enter a store name');
      return;
    }

    Navigator.pop(context);

    try {
      if (useMapCenter && homeController.mapController != null) {
        final cameraPosition = await homeController.mapController!.getLatLng(
          ScreenCoordinate(
            x: Get.width ~/ 2,
            y: Get.height ~/ 2,
          ),
        );
        await homeController.addStoreAtLocation(
          name,
          cameraPosition,
          radius,
        );
      } else {
        await homeController.addStoreAtCurrentLocation(name, radius);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add store location: $e');
    }
  }

  Future<void> _selectLocationFromMap(BuildContext context) async {
    Navigator.pop(context); // Close the add store dialog

    final LatLng? selectedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(),
      ),
    );

    if (selectedLocation != null) {
      final name = nameController.text.trim();
      final radius = double.tryParse(radiusController.text) ?? 50.0;

      if (name.isEmpty) {
        Get.snackbar('Error', 'Please enter a store name');
        return;
      }

      try {
        await homeController.addStoreAtLocation(
          name,
          selectedLocation,
          radius,
        );
      } catch (e) {
        Get.snackbar('Error', 'Failed to add store location: $e');
      }
    }
  }

  Future<void> _showEditStoreDialog(BuildContext context, Map<String, dynamic> store) async {
    nameController.text = store['name'];
    radiusController.text = store['radius'].toString();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Store Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Store Name'),
              textCapitalization: TextCapitalization.words,
            ),
            TextField(
              controller: radiusController,
              decoration: const InputDecoration(
                labelText: 'Radius (meters)',
                hintText: 'Enter detection radius in meters',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _editLocationFromMap(context, store),
              icon: const Icon(Icons.map),
              label: const Text('Change Location on Map'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _updateStore(context, store),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _editLocationFromMap(BuildContext context, Map<String, dynamic> store) async {
    Navigator.pop(context); // Close the edit store dialog

    final LatLng? selectedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLocation: LatLng(store['latitude'], store['longitude']),
        ),
      ),
    );

    if (selectedLocation != null) {
      final name = nameController.text.trim();
      final radius = double.tryParse(radiusController.text) ?? 50.0;

      if (name.isEmpty) {
        Get.snackbar('Error', 'Please enter a store name');
        return;
      }

      try {
        await storeController.updateStore(
          store['id'],
          name,
          selectedLocation,
          radius,
        );
      } catch (e) {
        Get.snackbar('Error', 'Failed to update store location: $e');
      }
    }
  }

  Future<void> _updateStore(BuildContext context, Map<String, dynamic> store) async {
    final name = nameController.text.trim();
    final radius = double.tryParse(radiusController.text) ?? 50.0;

    if (name.isEmpty) {
      Get.snackbar('Error', 'Please enter a store name');
      return;
    }

    Navigator.pop(context);

    try {
      await storeController.updateStore(
        store['id'],
        name,
        LatLng(store['latitude'], store['longitude']),
        radius,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update store location: $e');
    }
  }

  Future<void> _confirmDelete(BuildContext context, Map<String, dynamic> store) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Store'),
        content: Text('Are you sure you want to delete ${store['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await storeController.deleteStore(store['id']);
              } catch (e) {
                Get.snackbar('Error', 'Failed to delete store location: $e');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showVisitHistory(BuildContext context, Map<String, dynamic> store) async {
    final visits = await storeController.getStoreVisits(store['id']);
    
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Visit History - ${store['name']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final visit = visits[index];
              final entryTime = DateTime.parse(visit['entry_time']);
              final exitTime = visit['exit_time'] != null
                  ? DateTime.parse(visit['exit_time'])
                  : null;
              
              final duration = exitTime != null
                  ? exitTime.difference(entryTime)
                  : null;

              return ListTile(
                title: Text('Visit #${index + 1}'),
                subtitle: Text(
                  'Entry: ${_formatDateTime(entryTime)}\n'
                  'Exit: ${exitTime != null ? _formatDateTime(exitTime) : 'Still inside'}\n'
                  'Duration: ${duration != null ? _formatDuration(duration) : 'Ongoing'}',
                ),
                isThreeLine: true,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours}h ${minutes}m ${seconds}s';
  }
} 