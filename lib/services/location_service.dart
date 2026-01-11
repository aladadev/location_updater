import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:location_updater/database/db_helper.dart';
import 'package:location_updater/models/location_model.dart';
import 'package:workmanager/workmanager.dart';

const String locationTrackingTask = 'locationTrackingTask';

// Workmanager stuffs
// This function runs in the background
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('Background task started: $task');

      // Checking Location Permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location Permission denied in background');
        return Future.value(true);
      }

      // Checking for location service is enabled or not
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      ;
      if (!serviceEnabled) {
        print('Location service disabled in background');
        return Future.value(true);
      }

      // Get Current Location with Timeout
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

      // Saving to database
      final location = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      await DBHelper.instance.create(location);
      print(
        'Background Location saved: ${position.latitude}, ${position.longitude}',
      );
      return Future.value(true);
    } catch (error) {
      print("Error in background in location service try block: $error");
      return Future.value(true);
    }
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _locationSaveTimer;
  Position? _lastPosition;
  bool _isTracking = false;
  bool get isTracking => _isTracking;

  //Initialize the Workmanager
  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  // Check and request location permissions
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    //Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    //check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Start location tracking (foreground + background)
  Future<bool> startTracking() async {
    if (_isTracking) {
      return true;
    }

    // Check Permissions
    bool hasPermission = await checkAndRequestPermission();
    if (!hasPermission) {
      return false;
    }

    try {
      // Starting Foreground Tracking
      _startForegroundTracking();

      // Start Background using workmanager
      await Workmanager().registerPeriodicTask(
        '1',
        locationTrackingTask,
        frequency: Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.notRequired),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );

      _isTracking = true;
      print('Location tracking started successfully');
      return true;
    } catch (error) {
      print('Error While starting tracking: $error');
      return false;
    }
  }

  // Start Foreground Location Tracking
  void _startForegroundTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
            // Storing the latest position, saved by timer every 1 minute
            _lastPosition = position;
            print(
              'Position Updated: ${position.latitude}, ${position.longitude}',
            );
          },
          onError: (error) {
            print('Error getting location: $error');
          },
        );
  }

  //Start timer to save location every 1 minute
  void _startLocationSaveTimer() {
    //saving initial location immediately
    _saveCurrentPosition();

    // Saving every 1 minute
    _locationSaveTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _saveCurrentPosition();
    });
  }

  // Save the current position to database
  Future<void> _saveCurrentPosition() async {
    if (_lastPosition != null) {
      final location = LocationModel(
        latitude: _lastPosition!.latitude,
        longitude: _lastPosition!.longitude,
        timestamp: DateTime.now(),
      );

      await DBHelper.instance.create(location);
      print(
        'Location Saved: ${_lastPosition!.latitude},${_lastPosition!.longitude}',
      );
    } else {
      print('No Position available to save');
    }
  }

  // Stop Location Tracking
  Future<void> stopTracking() async {
    if (!isTracking) {
      return;
    }

    // Cancel Foreground Tracking
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    // Cancel Timer
    _locationSaveTimer?.cancel();
    _locationSaveTimer = null;

    // Clear Last Position
    _lastPosition = null;

    //Cancel Background Tracking
    await Workmanager().cancelByUniqueName('1');

    _isTracking = false;

    print('Location Tracking has been stopped!');
  }

  // Get current location once
  Future<Position?> getCurrentLocation() async {
    bool hasPermission = await checkAndRequestPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );
      return position;
    } catch (error) {
      print('Error getting current location: $error');
      return null;
    }
  }

  // Save Location Manually
  Future<void> saveLocation(double latitude, double longitude) async {
    final location = LocationModel(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
    );
    await DBHelper.instance.create(location);
  }
}
