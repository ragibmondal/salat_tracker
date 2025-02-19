import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  bool _hasPermissions = false;
  double? _direction;
  double? _qiblaDirection;
  final double kaabaLat = 21.422487;
  final double kaabaLng = 39.826206;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.locationWhenInUse.request();
    if (locationStatus.isGranted) {
      final position = await Geolocator.getCurrentPosition();
      final qiblaDirection = _calculateQiblaDirection(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _hasPermissions = true;
        _qiblaDirection = qiblaDirection;
      });

      FlutterCompass.events?.listen((event) {
        setState(() {
          _direction = event.heading;
        });
      });
    }
  }

  double _calculateQiblaDirection(double lat, double lng) {
    const double kaabaLat = 21.422487;
    const double kaabaLng = 39.826206;

    final double latRad = lat * pi / 180;
    final double lngRad = lng * pi / 180;
    final double kaabaLatRad = kaabaLat * pi / 180;
    final double kaabaLngRad = kaabaLng * pi / 180;

    double y = sin(kaabaLngRad - lngRad);
    double x = cos(latRad) * tan(kaabaLatRad) -
        sin(latRad) * cos(kaabaLngRad - lngRad);

    double qiblaRad = atan2(y, x);
    double qiblaDeg = qiblaRad * 180 / pi;

    return qiblaDeg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla Direction'),
      ),
      body: Builder(
        builder: (context) {
          if (!_hasPermissions) {
            return _buildPermissionRequest();
          }

          if (_direction == null || _qiblaDirection == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final qiblaAngle = _qiblaDirection! - _direction!;
          
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 4,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Transform.rotate(
                          angle: (qiblaAngle * pi / 180),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/images/compass.png',
                                width: 200,
                                height: 200,
                              ),
                              const Icon(
                                Icons.arrow_upward,
                                size: 48,
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -60,
                        child: Transform.rotate(
                          angle: (qiblaAngle * pi / 180),
                          child: const Icon(
                            Icons.location_on,
                            size: 48,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Qibla Direction',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${qiblaAngle.toStringAsFixed(1)}°',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Point the arrow towards the Qibla direction. '
                        'The red marker indicates magnetic north.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Location permission is required\nto determine Qibla direction',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _checkPermissions,
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }
} 