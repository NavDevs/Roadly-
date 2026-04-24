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
  String _locationLabel = 'Detecting location…';
  bool _submitting = false;

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
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationLabel = 'Location unavailable');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationLabel = 'Location unavailable');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationLabel = 'Location unavailable');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _locationLabel = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      setState(() => _locationLabel = 'Current location');
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _photoUri = pickedFile.path);
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedType == null || _submitting) return;

    setState(() => _submitting = true);

    final appProvider = context.read<AppProvider>();
    appProvider.addReport(
      type: _selectedType!,
      description: _descriptionController.text.trim(),
      location: _locationLabel,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  // Type selection
                  _sectionLabel('What\'s happening?'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ReportTypes.types.map((t) {
                      final active = _selectedType == t.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = t.id),
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: active ? t.color : AppColors.card,
                            borderRadius: BorderRadius.circular(AppColors.radius),
                            border: Border.all(
                              color: active ? t.color : AppColors.border,
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
                                      ? Colors.white.withOpacity(0.2)
                                      : t.color.withOpacity(0.13),
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
                                '+${t.points} pts',
                                style: TextStyle(
                                  color: active
                                      ? Colors.white.withOpacity(0.9)
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
                  // Location
                  _sectionLabel('Location'),
                  const SizedBox(height: 10),
                  Container(
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
                            color: AppColors.primary.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Description
                  _sectionLabel('Description'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    style: const TextStyle(color: AppColors.foreground),
                    decoration: InputDecoration(
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
                  const SizedBox(height: 22),
                  // Photo
                  _sectionLabel('Photo (optional)'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickPhoto,
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
          // Submit button
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
              onTap: _selectedType == null || _submitting ? null : _handleSubmit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedType != null ? AppColors.primary : AppColors.secondary,
                  borderRadius: BorderRadius.circular(AppColors.radius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.send,
                      color: _selectedType != null ? Colors.white : AppColors.mutedForeground,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedType != null ? 'Submit report' : 'Choose a type',
                      style: TextStyle(
                        color: _selectedType != null ? Colors.white : AppColors.mutedForeground,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.camera_alt,
            color: AppColors.mutedForeground,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add photo evidence',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Speeds up verification',
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
