import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/admin_attendance_service.dart';
import 'admin_ui_kit.dart';

class AdminAttendanceMap extends StatefulWidget {
  const AdminAttendanceMap({
    super.key,
    required this.selectedDate,
    required this.logs,
  });

  final DateTime selectedDate;
  final List<AdminAttendanceLogData> logs;

  @override
  State<AdminAttendanceMap> createState() => _AdminAttendanceMapState();
}

class _AdminAttendanceMapState extends State<AdminAttendanceMap> {
  final MapController _mapController = MapController();
  List<_MapPin> _pins = const [];

  @override
  void initState() {
    super.initState();
    _pins = _buildPins(widget.logs);
    _scheduleFit();
  }

  @override
  void didUpdateWidget(covariant AdminAttendanceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.logs != widget.logs) {
      setState(() {
        _pins = _buildPins(widget.logs);
      });
      _scheduleFit();
    }
  }

  List<_MapPin> _buildPins(List<AdminAttendanceLogData> rows) {
    final pins = <_MapPin>[];

    for (final row in rows) {
      final loc = row.clockInLocation;
      if (loc == null) continue;

      final lat = (loc['lat'] as num?)?.toDouble();
      final lng = (loc['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      if (!_isValidCoordinate(lat, lng)) continue;

      final time = row.clockIn == null
          ? '--:--'
          : DateFormat('HH:mm').format(row.clockIn!);

      pins.add(
        _MapPin(
          name: row.name,
          department: row.department,
          status: row.status,
          clockInTime: time,
          point: LatLng(lat, lng),
        ),
      );
    }

    return pins;
  }

  void _scheduleFit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fitMap();
    });
  }

  void _fitMap() {
    if (_pins.isEmpty) return;

    final points = _pins.map((p) => p.point).toList(growable: false);
    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }

    final minLat = points.map((p) => p.latitude).reduce(math.min);
    final maxLat = points.map((p) => p.latitude).reduce(math.max);
    final minLng = points.map((p) => p.longitude).reduce(math.min);
    final maxLng = points.map((p) => p.longitude).reduce(math.max);

    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    if (!latSpan.isFinite ||
        !lngSpan.isFinite ||
        latSpan <= 0.000001 ||
        lngSpan <= 0.000001) {
      _mapController.move(center, 15);
      return;
    }

    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(52)),
      );
    } catch (_) {
      _mapController.move(center, 13);
    }
  }

  bool _isValidCoordinate(double lat, double lng) {
    return lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _pins.isNotEmpty
        ? _pins.first.point
        : const LatLng(19.0760, 72.8777);

    return AdminSurfaceCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 300,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: _pins.isEmpty ? 11 : 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.equitec.eqhr',
                  ),
                  MarkerLayer(
                    markers: _pins
                        .map((pin) {
                          return Marker(
                            point: pin.point,
                            width: 122,
                            height: 76,
                            child: GestureDetector(
                              onTap: () => _showPinInfo(pin),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_pin,
                                    color: Color(0xFFE53935),
                                    size: 34,
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 116,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x330F172A),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      pin.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AdminColors.text,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.map_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Clock-In Map • ${DateFormat('dd MMM yyyy').format(widget.selectedDate)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_pins.length} pins',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_pins.isEmpty)
                Container(
                  color: Colors.black.withValues(alpha: 0.22),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'No clock-in locations for selected filters.',
                      style: TextStyle(
                        color: AdminColors.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 10,
                bottom: 10,
                child: InkWell(
                  onTap: _fitMap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x260F172A),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.center_focus_strong_rounded,
                      size: 18,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPinInfo(_MapPin pin) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE53935),
                child: Icon(Icons.location_pin, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pin.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.text,
                      ),
                    ),
                    Text(
                      pin.department,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AdminColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Clocked in at ${pin.clockInTime}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  pin.status.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapPin {
  const _MapPin({
    required this.name,
    required this.department,
    required this.status,
    required this.clockInTime,
    required this.point,
  });

  final String name;
  final String department;
  final String status;
  final String clockInTime;
  final LatLng point;
}
