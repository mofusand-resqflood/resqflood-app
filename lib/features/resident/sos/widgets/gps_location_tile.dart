import 'package:flutter/material.dart';

import '../../../../services/location_service.dart';

class GpsLocationTile extends StatefulWidget {
  const GpsLocationTile({
    super.key,
    this.locationService,
    this.onLocationChanged,
  });

  /// Optional injection point for tests or a caller with a shared service.
  final LocationService? locationService;

  /// Called after each attempt, including attempts that return no location.
  final ValueChanged<LocationResult>? onLocationChanged;

  @override
  State<GpsLocationTile> createState() => _GpsLocationTileState();
}

class _GpsLocationTileState extends State<GpsLocationTile> {
  late final LocationService _locationService;

  LocationResult? _result;
  bool _isLoading = true;
  bool _isOpeningSettings = false;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? LocationService();

    // Fetch as soon as this tile is mounted. When it is included in the SOS
    // form, this starts the location request as the form opens.
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final result = await _locationService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      _result = result;
      _isLoading = false;
    });

    widget.onLocationChanged?.call(result);
  }

  Future<void> _openSettings() async {
    final issue = _result?.issue;
    if (issue == null || _isOpeningSettings) return;

    setState(() {
      _isOpeningSettings = true;
    });

    await _locationService.openSettingsFor(issue);

    if (!mounted) return;

    setState(() {
      _isOpeningSettings = false;
    });
  }

  bool get _shouldOfferSettings {
    final issue = _result?.issue;

    return issue == LocationIssue.locationServicesDisabled ||
        issue == LocationIssue.permissionDeniedForever;
  }

  String _issueMessage(LocationIssue issue) {
    switch (issue) {
      case LocationIssue.locationServicesDisabled:
        return 'Location services are off.';
      case LocationIssue.permissionDenied:
        return 'Location permission was denied.';
      case LocationIssue.permissionDeniedForever:
        return 'Location permission is blocked. Enable it in app settings.';
      case LocationIssue.currentLocationUnavailable:
        return 'Could not get a fresh location.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = _result?.location;
    final issue = _result?.issue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.my_location, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your location',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    tooltip: 'Retry location',
                    onPressed: _loadLocation,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (location != null) ...[
              Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
              Text(
                'Accuracy: ±${location.accuracyMeters.toStringAsFixed(0)} m',
              ),
              if (location.isLastKnown) ...[
                const SizedBox(height: 8),
                Text(
                  'Using last known location'
                  '${issue == null ? '.' : ' — ${_issueMessage(issue)}'}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Captured: ${location.capturedAt.toLocal()}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ] else if (_isLoading) ...[
              const Text('Getting your current location…'),
            ] else ...[
              Text(
                issue == null
                    ? 'Location is unavailable.'
                    : _issueMessage(issue),
              ),
            ],
            if (!_isLoading && _shouldOfferSettings) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isOpeningSettings ? null : _openSettings,
                icon: const Icon(Icons.settings),
                label: Text(
                  _isOpeningSettings ? 'Opening settings…' : 'Open settings',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
