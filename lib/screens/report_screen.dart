import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/report_types.dart';
import '../models/report.dart';
import '../providers/app_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportType? _selectedType;
  final _descriptionController = TextEditingController();
  String? _photoUri;
  String _locationLabel = 'Detecting location...';
  double? _latitude;
  double? _longitude;
  bool _submitting = false;
  bool _locating = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _locating = true;
      _locationLabel = 'Detecting location...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please turn on GPS / Location services first.'),
              action: SnackBarAction(
                label: 'Turn On',
                onPressed: () => Geolocator.openLocationSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        setState(() {
          _locationLabel = 'GPS is turned off — tap to retry';
          _locating = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission is required to report hazards.')),
            );
          }
          setState(() {
            _locationLabel = 'Permission denied — tap to retry';
            _locating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission permanently denied.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        setState(() {
          _locationLabel = 'Open settings to allow location';
          _locating = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationLabel =
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        _locating = false;
      });
    } catch (e) {
      setState(() {
        _locationLabel = 'Failed to get location — tap to retry';
        _locating = false;
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (pickedFile != null) {
      setState(() => _photoUri = pickedFile.path);
    }
  }

  Future<void> _showPhotoSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.foreground),
                title: const Text('Take photo', style: TextStyle(color: AppColors.foreground)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.foreground),
                title: const Text('Choose from gallery', style: TextStyle(color: AppColors.foreground)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (_photoUri != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                  title: const Text('Remove photo', style: TextStyle(color: AppColors.danger)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _photoUri = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedType == null || _submitting) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Waiting for GPS. Enable location and retry.'),
          action: SnackBarAction(label: 'Retry', onPressed: _getCurrentLocation),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final appProvider = context.read<AppProvider>();
    final error = await appProvider.addReport(
      type: _selectedType!,
      description: _descriptionController.text.trim(),
      location: _locationLabel,
      photoUri: _photoUri,
      latitude: _latitude,
      longitude: _longitude,
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }

    final isEmergency =
        _selectedType == ReportType.accident || _selectedType == ReportType.fire;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEmergency
              ? 'Report submitted — emergency services are being notified.'
              : 'Report submitted successfully.',
        ),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _selectedType != null && !_submitting && !_locating && _latitude != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New report',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(context).padding.bottom + 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('What\'s happening?'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ReportTypes.types.map((t) {
                      final active = _selectedType == t.id;
                      final isEmergency =
                          t.id == ReportType.accident || t.id == ReportType.fire;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = t.id),
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: active ? t.color : AppColors.card,
                            borderRadius: BorderRadius.circular(AppColors.radius),
                            border: Border.all(
                              color: active
                                  ? t.color
                                  : (isEmergency
                                      ? t.color.withValues(alpha: 0.45)
                                      : AppColors.border),
                              width: isEmergency ? 1.4 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: active
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : t.color.withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getIconData(t.iconName),
                                  color: active ? Colors.white : t.color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                t.short,
                                style: TextStyle(
                                  color: active ? Colors.white : AppColors.foreground,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEmergency
                                    ? 'Alerts Signal-Aid'
                                    : '+${t.points} pts',
                                style: TextStyle(
                                  color: active
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : AppColors.mutedForeground,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  _sectionLabel('Location'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _locating ? null : _getCurrentLocation,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppColors.radius),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _locating
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(
                                    Icons.location_on,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current location',
                                  style: TextStyle(
                                    color: AppColors.foreground,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _locationLabel,
                                  style: const TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_locating)
                            const Icon(Icons.refresh, color: AppColors.mutedForeground, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionLabel('Description'),
                  const SizedBox(height: 10),
                  // Fixed height + internal scroll: this field can never
                  // overflow the form, no matter the window size or text scale.
                  SizedBox(
                    height: 120,
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(color: AppColors.foreground),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(14),
                        hintText: 'Add a quick note for other drivers…',
                        hintStyle: TextStyle(color: AppColors.mutedForeground),
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppColors.radius),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppColors.radius),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionLabel('Photo (optional)'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _showPhotoSheet,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppColors.radius),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: _photoUri != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppColors.radius),
                              child: Image.file(
                                File(_photoUri!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return _photoEmpty();
                                },
                              ),
                            )
                          : _photoEmpty(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(context).padding.bottom + 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: GestureDetector(
              onTap: canSubmit ? _handleSubmit : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: canSubmit ? AppColors.primary : AppColors.secondary,
                  borderRadius: BorderRadius.circular(AppColors.radius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_submitting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        Icons.send,
                        color: canSubmit ? Colors.white : AppColors.mutedForeground,
                        size: 18,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _submitting
                          ? 'Submitting…'
                          : (_selectedType == null
                              ? 'Choose a type'
                              : (_latitude == null ? 'Waiting for GPS…' : 'Submit report')),
                      style: TextStyle(
                        color: canSubmit ? Colors.white : AppColors.mutedForeground,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.mutedForeground,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _photoEmpty() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt, color: AppColors.mutedForeground, size: 28),
        SizedBox(height: 8),
        Text(
          'Add photo evidence',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Camera or gallery',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'alert_octagon':
        return Icons.warning;
      case 'flame':
        return Icons.local_fire_department;
      case 'tool':
        return Icons.build;
      case 'truck':
        return Icons.local_shipping;
      case 'slash':
        return Icons.block;
      default:
        return Icons.error_outline;
    }
  }
}
