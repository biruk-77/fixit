// lib/screens/worker_detail_screen.dart
import 'dart:ui' as ui; // For ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart'; // For DateFormat
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:animated_rating_stars/animated_rating_stars.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:geolocator/geolocator.dart'; // For location services
import 'package:url_launcher/url_launcher.dart'; // For launching URLs (phone, maps)
import 'package:flutter_animate/flutter_animate.dart'; // REQUIRED FOR ALL ANIMATIONS
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:polyline_codec/polyline_codec.dart';
import 'package:http/http.dart' as http;
import '../models/worker.dart';
import '../models/user.dart';
import 'dart:convert'; // <-- ADD THIS LINE
import '../services/firebase_service.dart';
import '../services/app_string.dart'; // For localization (assumed to exist and contain methods)
import './jobs/create_job_screen.dart'; // Corrected path
import './jobs/quick_job_request_screen.dart'; // Corrected path
import './chat/conversation_pane.dart';

// --- NEW CUSTOM WIDGETS FOR THIS DESIGN ---

// Generic Section Wrapper (Clean, Modern, Elevated)
class _SectionContainer extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? headerWidget; // For custom header rows
  final EdgeInsetsGeometry padding;

  const _SectionContainer({
    required this.child,
    this.title,
    this.icon,
    this.headerWidget,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh, // Elevated surface color
        borderRadius: BorderRadius.circular(20), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || headerWidget != null) ...[
            headerWidget ??
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: cs.primary, size: 28),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        title!,
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
            const Divider(height: 25, thickness: 1, color: Colors.black12),
          ],
          child,
        ],
      ),
    );
  }
}

// Simplified Skill Pill
class _SkillPill extends StatelessWidget {
  final String skill;
  const _SkillPill({required this.skill});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        skill,
        style: tt.bodyMedium?.copyWith(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Simple Stat Wheel (Circular progress indicator with text)
class _StatWheel extends StatelessWidget {
  final String label;
  final IconData icon;
  final double progress; // 0.0 to 1.0
  final String valueText;
  final Color accentColor;

  const _StatWheel({
    required this.label,
    required this.icon,
    required this.progress,
    required this.valueText,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(
          width: 100, // Fixed size
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: accentColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
              Icon(icon, color: accentColor, size: 30),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          valueText,
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        Text(
          label,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Certification Pill (More functional than badge)
class _CertificationPill extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _CertificationPill({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: cs.secondary, size: 35),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              "View", // Simplified text for action (consider localizing if needed)
              style: tt.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Gallery Carousel with filter and view type toggle
class _GallerySection extends StatefulWidget {
  final AppStrings appStrings;
  final List<String> allImages;
  final Map<String, List<String>> filteredImages;
  final Function(int index, String filterType) onImageTap;

  const _GallerySection({
    required this.appStrings,
    required this.allImages,
    required this.filteredImages,
    required this.onImageTap,
  });

  @override
  State<_GallerySection> createState() => _GallerySectionState();
}

enum GalleryViewType { grid, carousel }

class _GallerySectionState extends State<_GallerySection> {
  String _currentFilter = 'All'; // Default filter
  GalleryViewType _currentViewType = GalleryViewType.grid; // Default view

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    List<String> imagesToShow = widget.filteredImages[_currentFilter] ?? [];
    if (imagesToShow.isEmpty && _currentFilter != 'All') {
      imagesToShow = widget.allImages;
    } else if (imagesToShow.isEmpty && _currentFilter == 'All') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          widget.appStrings.workerDetailNoGallery,
          style: tt.bodyLarge?.copyWith(
            color: cs.onSurfaceVariant.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        // Filter Buttons
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: widget.filteredImages.keys.map((filterName) {
              final bool isSelected = _currentFilter == filterName;
              return GestureDetector(
                onTap: () => setState(() => _currentFilter = filterName),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary.withOpacity(0.15)
                        : cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? cs.primary
                          : cs.outlineVariant.withOpacity(0.5),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      filterName,
                      style: tt.labelLarge?.copyWith(
                        color: isSelected ? cs.primary : cs.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        // View Type Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                Icons.view_carousel_outlined,
                color: _currentViewType == GalleryViewType.carousel
                    ? cs.secondary
                    : cs.onSurfaceVariant,
              ),
              onPressed: () =>
                  setState(() => _currentViewType = GalleryViewType.carousel),
              // FIX: Hardcoded tooltip
              tooltip: 'Carousel View',
            ),
            IconButton(
              icon: Icon(
                Icons.grid_on_outlined,
                color: _currentViewType == GalleryViewType.grid
                    ? cs.secondary
                    : cs.onSurfaceVariant,
              ),
              onPressed: () =>
                  setState(() => _currentViewType = GalleryViewType.grid),
              // FIX: Hardcoded tooltip
              tooltip: 'Grid View',
            ),
          ],
        ),
        const SizedBox(height: 15),
        // Display Gallery
        imagesToShow.isEmpty
            ? Text(
                widget.appStrings.workerDetailNoGallery,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: _currentViewType == GalleryViewType.grid
                    ? _buildGridView(imagesToShow)
                    : _buildCarouselView(imagesToShow),
              ),
      ],
    );
  }

  Widget _buildGridView(List<String> images) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      key: ValueKey('grid_$_currentFilter'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final imageUrl = images[index];
        return GestureDetector(
          onTap: () => widget.onImageTap(index, _currentFilter),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: cs.surfaceContainerHighest),
                errorWidget: (context, url, error) => Icon(
                  Icons.broken_image_rounded,
                  size: 40,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarouselView(List<String> images) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      key: ValueKey('carousel_$_currentFilter'),
      height: 200, // Fixed height for carousel
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          final imageUrl = images[index];
          return GestureDetector(
            onTap: () => widget.onImageTap(index, _currentFilter),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: cs.surfaceContainerHighest),
                  errorWidget: (context, url, error) => Icon(
                    Icons.broken_image_rounded,
                    size: 50,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Location and Availability Floating Bottom Bar
class _LocationAvailabilityBar extends StatelessWidget {
  final AppStrings appStrings;
  final String? distanceText;
  final bool isAvailable;

  const _LocationAvailabilityBar({
    required this.appStrings,
    this.distanceText,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withOpacity(
              0.8,
            ), // Semi-transparent, themed
            borderRadius: BorderRadius.circular(30),
            // FIX: Changed BorderSide to Border.all
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location & Distance
              Icon(Icons.location_on_outlined, color: cs.secondary, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // FIX: Changed to hardcoded string to avoid AppStrings getter error
                      'Distance',
                      style: tt.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      distanceText ?? appStrings.workerDetailDistanceUnknown,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              // Availability Indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAvailable
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined,
                    color: isAvailable ? Colors.green.shade500 : cs.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAvailable
                        ? appStrings.availability
                        : appStrings.notAvailable,
                    style: tt.bodyLarge?.copyWith(
                      color: isAvailable ? Colors.green.shade500 : cs.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Video Mini-Player (Floating)
class _VideoMiniPlayer extends StatelessWidget {
  final ChewieController? chewieController;
  final VoidCallback onTap;
  final bool isPlaying;
  final VoidCallback togglePlayback;

  const _VideoMiniPlayer({
    required this.chewieController,
    required this.onTap,
    required this.isPlaying,
    required this.togglePlayback,
  });

  @override
  Widget build(BuildContext context) {
    if (chewieController == null ||
        !chewieController!.videoPlayerController.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 150, // Size of mini-player
            height: 90,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: chewieController!.aspectRatio ?? 16 / 9,
                  child: Chewie(controller: chewieController!),
                ),
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white.withOpacity(0.8),
                    size: 40,
                  ),
                  onPressed: togglePlayback,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Main Video Player Section
class _VideoPlayerSection extends StatelessWidget {
  final ChewieController? chewieController;
  final bool isVideoInitialized;
  final bool isVideoPlaying;
  final VoidCallback togglePlayback;
  final String
  profileImageUrl; // Used as placeholder background if video not loaded
  final AppStrings appStrings; // For localized text

  const _VideoPlayerSection({
    required Key? key,
    required this.chewieController,
    required this.isVideoInitialized,
    required this.isVideoPlaying,
    required this.togglePlayback,
    required this.profileImageUrl,
    required this.appStrings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _SectionContainer(
      title: appStrings.workerDetailVideoIntro,
      icon: Icons.videocam_outlined,
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: chewieController?.aspectRatio ?? 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            isVideoInitialized && chewieController != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Chewie(controller: chewieController!),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(15),
                      image: profileImageUrl.isNotEmpty
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                profileImageUrl,
                              ),
                              fit: BoxFit.cover,
                              colorFilter: ui.ColorFilter.mode(
                                Colors.black.withOpacity(0.4),
                                ui.BlendMode.darken,
                              ),
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    // Only show spinner if there's no placeholder image AND video isn't initialized
                    child: profileImageUrl.isEmpty
                        ? CircularProgressIndicator(color: cs.primary)
                        : const SizedBox.shrink(),
                  ),
            // Custom Play/Pause button overlay
            GestureDetector(
              onTap: togglePlayback,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Icon(
                  isVideoPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ⬇️ REPLACE YOUR ENTIRE _LocationMapWidget WITH THIS CODE ⬇️
//
enum MapStyle { light, dark, satellite }

class _LocationMapWidget extends StatefulWidget {
  final AppStrings appStrings;
  final double workerLat;
  final double workerLng;
  final String? distanceText;
  final double? clientLat;
  final double? clientLng;

  const _LocationMapWidget({
    super.key,
    required this.appStrings,
    required this.workerLat,
    required this.workerLng,
    this.distanceText,
    required this.clientLat,
    required this.clientLng,
  });

  @override
  State<_LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<_LocationMapWidget> {
  MapStyle _currentStyle = MapStyle.satellite;
  final String _stadiaApiKey = 'ee647837-42e0-4187-9380-f4d31bc90fe9';
  final String _openRouteServiceApiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjlkZDE1MzM2N2ZmNzQ4ZDU4ZjI5NDVlY2JmYjhkMWFkIiwiaCI6Im11cm11cjY0In0=';

  List<LatLng> _routePoints = [];
  String? _updatedDistance;
  String? _updatedEta;
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRouteAndEta();
    });
  }

  Future<void> _fetchRouteAndEta() async {
    if (widget.clientLat == null || widget.clientLng == null) {
      if (mounted) setState(() => _isLoadingRoute = false);
      return;
    }

    final uri = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car/geojson',
    );
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept':
          'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
      'Authorization': _openRouteServiceApiKey,
    };
    final body = json.encode({
      "coordinates": [
        [widget.clientLng, widget.clientLat],
        [widget.workerLng, widget.workerLat],
      ],
    });

    try {
      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        if (features.isNotEmpty) {
          final geometry = features[0]['geometry']['coordinates'] as List;
          final properties = features[0]['properties'];
          final summary = properties['summary'];
          final durationInSeconds = summary['duration'];
          final distanceInMeters = summary['distance'];
          final List<LatLng> polylineCoordinates = geometry
              .map((p) => LatLng(p[1].toDouble(), p[0].toDouble()))
              .toList();
          if (mounted) {
            setState(() {
              _routePoints = polylineCoordinates;
              _updatedEta = '${(durationInSeconds / 60).round()} mins';
              _updatedDistance =
                  '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
              _isLoadingRoute = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingRoute = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  String _getMapUrl() {
    switch (_currentStyle) {
      case MapStyle.dark:
        return 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png?api_key=$_stadiaApiKey';
      case MapStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapStyle.light:
      default:
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final markers = <Marker>[
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(widget.workerLat, widget.workerLng),
        child: const Icon(Icons.location_on, color: Colors.red, size: 45.0),
      ),
    ];

    if (widget.clientLat != null && widget.clientLng != null) {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(widget.clientLat!, widget.clientLng!),
          child: Icon(Icons.my_location, color: cs.primary, size: 35.0),
        ),
      );
    }

    // This adds the ETA text as a marker above the worker's location pin
    if (_updatedEta != null) {
      markers.add(
        Marker(
          width: 120.0, // Give it more space
          height: 80.0, // Give it more space
          point: LatLng(widget.workerLat, widget.workerLng),
          child: Align(
            alignment:
                Alignment.bottomCenter, // Position it below the marker point
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 45.0,
              ), // Nudge it above the pin icon
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _updatedEta!,
                  style: tt.labelMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    MapOptions mapOptions;
    if (_routePoints.isNotEmpty) {
      mapOptions = MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(_routePoints),
          padding: const EdgeInsets.all(50.0),
        ),
      );
    } else {
      mapOptions = MapOptions(
        initialCenter: LatLng(widget.workerLat, widget.workerLng),
        initialZoom: 13.0, // Correct, wider zoom level
      );
    }

    return _SectionContainer(
      title: 'Location & ETA',
      icon: Icons.map_outlined,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                children: [
                  FlutterMap(
                    options: mapOptions,
                    children: [
                      TileLayer(
                        urlTemplate: _getMapUrl(),
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              color: cs.primary,
                              strokeWidth: 5,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: markers,
                        rotate: false,
                      ), // Disable marker rotation for stability
                    ],
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          _buildStyleChip(
                            context,
                            Icons.map_outlined,
                            MapStyle.light,
                          ),
                          const SizedBox(width: 5),
                          _buildStyleChip(
                            context,
                            Icons.dark_mode_outlined,
                            MapStyle.dark,
                          ),
                          const SizedBox(width: 5),
                          _buildStyleChip(
                            context,
                            Icons.satellite_alt_outlined,
                            MapStyle.satellite,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isLoadingRoute)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: CircularProgressIndicator(color: cs.primary),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoColumn(
                      'Distance',
                      _updatedDistance ?? widget.distanceText,
                      context,
                    ),
                    _buildInfoColumn('Estimated ETA', _updatedEta, context),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final Uri uri = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${widget.workerLat},${widget.workerLng}&travelmode=driving',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    icon: Icon(Icons.directions_outlined, color: cs.primary),
                    label: Text(
                      'View on Map',
                      style: tt.titleMedium?.copyWith(color: cs.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.primary.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String title, String? value, BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        if (value != null)
          Text(
            value,
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          )
        else
          SizedBox(
            height: 24,
            width: 24,
            child: _isLoadingRoute
                ? const CircularProgressIndicator(strokeWidth: 2)
                : const Text('-'),
          ),
      ],
    );
  }

  Widget _buildStyleChip(BuildContext context, IconData icon, MapStyle style) {
    final bool isSelected = _currentStyle == style;
    return GestureDetector(
      onTap: () => setState(() => _currentStyle = style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _BookingCalendar extends StatefulWidget {
  final AppStrings appStrings;
  final Map<DateTime, List<String>> availableSlots;
  final Function(DateTime date, String slot) onBookSlot;

  const _BookingCalendar({
    required this.appStrings,
    required this.availableSlots,
    required this.onBookSlot,
  });

  @override
  State<_BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<_BookingCalendar> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    List<DateTime> upcomingDays = List.generate(
      14,
      (i) => DateTime.now().add(Duration(days: i)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: upcomingDays.length,
            itemBuilder: (context, index) {
              final date = upcomingDays[index];
              final DateTime normalizedDate = DateTime(
                date.year,
                date.month,
                date.day,
              );
              final DateTime normalizedSelectedDate = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              );

              final bool isAvailableDay = widget.availableSlots.keys.any(
                (slotDate) =>
                    DateTime(slotDate.year, slotDate.month, slotDate.day) ==
                    normalizedDate,
              );
              final bool isSelected = normalizedDate == normalizedSelectedDate;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = date;
                  _selectedSlot = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 70,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary.withOpacity(0.15)
                        : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? cs.primary
                          : cs.outlineVariant.withOpacity(0.5),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat.E().format(date),
                        style: tt.bodySmall?.copyWith(
                          color: isSelected ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        DateFormat.d().format(date),
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      if (isAvailableDay)
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(
          // FIX: Changed to hardcoded string + interpolation to avoid AppStrings method error
          'Available Slots for ${DateFormat.yMd(widget.appStrings.locale.languageCode).format(_selectedDate)}',
          style: tt.titleMedium?.copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: 15),
        if (widget.availableSlots.keys.any(
          (slotDate) =>
              DateTime(slotDate.year, slotDate.month, slotDate.day) ==
              DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              ),
        ))
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: widget.availableSlots.entries
                .firstWhere(
                  (entry) =>
                      DateTime(
                        entry.key.year,
                        entry.key.month,
                        entry.key.day,
                      ) ==
                      DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                      ),
                  orElse: () => MapEntry(DateTime.now(), []),
                )
                .value
                .map(
                  (slot) => GestureDetector(
                    onTap: () => setState(() => _selectedSlot = slot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedSlot == slot
                            ? cs.secondary.withOpacity(0.2)
                            : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedSlot == slot
                              ? cs.secondary
                              : cs.outlineVariant.withOpacity(0.5),
                          width: _selectedSlot == slot ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        slot,
                        style: tt.bodyLarge?.copyWith(
                          color: _selectedSlot == slot
                              ? cs.onSecondary
                              : cs.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          )
        else
          // FIX: Changed to hardcoded string to avoid AppStrings getter error
          Text(
            'No slots available',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        const SizedBox(height: 25),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selectedSlot != null
                ? () {
                    widget.onBookSlot(_selectedDate, _selectedSlot!);
                    setState(() {
                      _selectedSlot = null;
                    });
                  }
                : null,
            icon: const Icon(Icons.calendar_month_outlined, size: 24),
            label: Text(
              _selectedSlot != null
                  // FIX: Changed to hardcoded string to avoid AppStrings getter error
                  ? 'Book Slot'
                  // FIX: Changed to hardcoded string to avoid AppStrings getter error
                  : 'Select a Time Slot',
              style: tt.titleLarge?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> reviews;
  final AppStrings appStrings;

  const _ReviewCarousel({required this.reviews, required this.appStrings});

  @override
  State<_ReviewCarousel> createState() => _ReviewCarouselState();
}

class _ReviewCarouselState extends State<_ReviewCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page != null) {
        final newPage = _pageController.page!.round();
        if (newPage != _currentPage) {
          setState(() => _currentPage = newPage);
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.reviews.length,
            itemBuilder: (context, index) {
              final review = widget.reviews[index];
              final reviewDate =
                  (review['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                            review['clientPhotoUrl'] ?? '',
                          ),
                          radius: 24,
                          backgroundColor: cs.surfaceContainerHighest,
                          child:
                              (review['clientPhotoUrl'] == null ||
                                  review['clientPhotoUrl']!.isEmpty)
                              ? Icon(Icons.person, color: cs.onSurfaceVariant)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review['userName'] ??
                                    widget.appStrings.workerDetailAnonymous,
                                style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                timeago.format(
                                  reviewDate,
                                  locale: widget.appStrings.locale.languageCode,
                                ),
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              (review['rating'] as num? ?? 0.0).toStringAsFixed(
                                1,
                              ),
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          review['comment'] ?? '',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.reviews.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _currentPage == index ? 25 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _currentPage == index ? cs.primary : cs.outlineVariant,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class WorkerDetailScreen extends StatefulWidget {
  final Worker worker;
  const WorkerDetailScreen({super.key, required this.worker});

  @override
  _WorkerDetailScreenState createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final _controllerReview = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _mainVideoSectionKey = GlobalKey(); // Key for video section

  String? _currentUserType;
  bool _isSubmittingReview = false;
  bool _isWorkerFav = false;
  bool _isLoadingFavorite = true;
  double _currentRating = 0.0;
  int _visibleReviewCount = 3;
  AppUser? _userProfile; // For 'Show All'/'Show Less' in reviews section

  // Video Player state
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;
  bool _showVideoMiniPlayer = false; // State for floating mini-player
  final double _videoSectionHeight =
      250.0; // Height of the main video section (adjust as needed)

  // Client's current location for distance calculation
  double? _clientLat;
  double? _clientLng;

  @override
  void initState() {
    super.initState();
    _loadUserAndMedia();
    _fetchClientLocation();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controllerReview.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // --- NEW: Internet Connectivity Check (Conceptual) ---
  // In a real app, you would use a package like 'connectivity_plus'
  // to get real-time network status.
  Future<bool> _checkInternetConnectivity(AppStrings appStrings) async {
    // This is a placeholder. Replace with actual connectivity check.
    // Example using connectivity_plus:
    // var connectivityResult = await (Connectivity().checkConnectivity());
    // if (connectivityResult == ConnectivityResult.none) {
    //   _showErrorSnackbar(appStrings.noInternetConnection);
    //   return false;
    // }
    // return true;

    // For now, always return true to allow functionality, but in production,
    // implement actual network check.
    debugPrint("🌐 Performing conceptual internet connectivity check...");
    return true; // Assume internet is available for now
  }

  // --- VIDEO MINI-PLAYER LOGIC ---
  void _handleScroll() {
    final RenderBox? videoRenderBox =
        _mainVideoSectionKey.currentContext?.findRenderObject() as RenderBox?;
    if (videoRenderBox == null) return;

    final double videoSectionTop = videoRenderBox.localToGlobal(Offset.zero).dy;

    // Show mini-player when the bottom of the video section scrolls past the top of the safe area
    final bool shouldShowMiniPlayer =
        videoSectionTop + _videoSectionHeight <
        MediaQuery.of(context).padding.top;

    if (shouldShowMiniPlayer != _showVideoMiniPlayer) {
      setState(() {
        _showVideoMiniPlayer = shouldShowMiniPlayer;
        // The play/pause logic here might conflict with Chewie's internal state
        // if not handled carefully. Consider only pausing the main player
        // when mini-player appears and letting mini-player control its own playback.
        if (_showVideoMiniPlayer) {
          _chewieController?.pause(); // Pause main video if showing mini-player
        } else {
          // Only play if it was playing before mini-player appeared
          if (_isVideoPlaying) {
            _chewieController
                ?.play(); // Resume main video if mini-player is hidden
          }
        }
      });
    }
  }

  void _jumpToVideoSection() {
    _scrollController.animateTo(
      0.0, // Scroll to the top where the video section is
      duration: 500.milliseconds,
      curve: Curves.easeInOutCubic,
    );
  }

  // --- DATA & ACTIONS ---

  Future<void> _loadUserAndMedia() async {
    await _loadUserTypeAndFavoriteStatus();
    // Only attempt to initialize video player if there's a URL and internet
    final AppStrings? appStrings = AppLocalizations.of(context);
    if (widget.worker.introVideoUrl != null &&
        widget.worker.introVideoUrl!.isNotEmpty &&
        appStrings != null &&
        await _checkInternetConnectivity(appStrings)) {
      _initializeVideoPlayer();
    }
  }

  Future<void> _fetchClientLocation() async {
    final AppStrings? appStrings = AppLocalizations.of(context);
    // Check internet before proceeding with location fetch
    if (appStrings == null || !await _checkInternetConnectivity(appStrings)) {
      debugPrint("Skipping location fetch due to no internet.");
      return;
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          debugPrint("Location permissions denied by client.");
          // FIX: Changed to hardcoded string to avoid AppStrings getter error
          if (mounted) _showErrorSnackbar('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        if (mounted) {
          setState(() {
            _clientLat = position.latitude;
            _clientLng = position.longitude;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching client location: $e");
      if (mounted && appStrings != null) {
        // FIX: Changed to hardcoded string to avoid AppStrings getter error
        _showErrorSnackbar('Error fetching location.');
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    final AppStrings? appStrings = AppLocalizations.of(context);
    if (appStrings == null) return; // Cannot proceed without appStrings

    // Defensive check: Ensure the video URL is valid and not empty
    if (widget.worker.introVideoUrl == null ||
        widget.worker.introVideoUrl!.isEmpty) {
      debugPrint("Video URL is null or empty. Cannot initialize video player.");
      // FIX: Changed to hardcoded string to avoid AppStrings getter error
      if (mounted) _showErrorSnackbar('Could not load video.');
      if (mounted) setState(() => _isVideoInitialized = false);
      return;
    }

    // Check internet connectivity before attempting to load video
    if (!await _checkInternetConnectivity(appStrings)) {
      debugPrint("Skipping video player initialization due to no internet.");
      // FIX: Changed to hardcoded string to avoid AppStrings getter error
      _showErrorSnackbar('No internet connection.');
      if (mounted) setState(() => _isVideoInitialized = false);
      return;
    }

    try {
      final videoUri = Uri.parse(widget.worker.introVideoUrl!);
      _videoController = VideoPlayerController.networkUrl(videoUri);
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true, // Autoplay
        looping: true,
        showControls: false, // Custom controls
        aspectRatio: _videoController!.value.aspectRatio,
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, errorMessage) {
          debugPrint("Chewie video error: $errorMessage");
          // This captures errors from Chewie itself, including network issues
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_off_rounded,
                  size: 50,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 8),
                Text(
                  // FIX: Changed to hardcoded string to avoid AppStrings getter error
                  'Video load failed.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  errorMessage, // Display the actual error message from Chewie
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
      if (mounted) setState(() => _isVideoInitialized = true);
      _isVideoPlaying = true; // Set initial playing state
    } catch (e) {
      debugPrint("Error initializing video player: $e");
      if (mounted && appStrings != null)
        // FIX: Changed to hardcoded string to avoid AppStrings getter error
        _showErrorSnackbar('Could not load video.');
      _videoController?.dispose();
      _chewieController?.dispose();
      if (mounted) setState(() => _isVideoInitialized = false);
    }
  }

  void _toggleVideoPlayback() async {
    // Made async to await _checkInternetConnectivity
    final AppStrings? appStrings = AppLocalizations.of(context);
    if (appStrings == null) return;

    if (!await _checkInternetConnectivity(appStrings)) {
      // FIX: Changed to hardcoded string to avoid AppStrings getter error
      _showErrorSnackbar('Cannot play video without internet.');
      return;
    }

    if (!_isVideoInitialized || _chewieController == null) {
      // If not initialized but there's a URL and internet, try to initialize
      if (widget.worker.introVideoUrl != null &&
          widget.worker.introVideoUrl!.isNotEmpty) {
        _initializeVideoPlayer(); // This will handle network checks internally
      } else {
        // FIX: Changed to hardcoded string to avoid AppStrings getter error
        _showErrorSnackbar('Could not load video.'); // No URL to play
      }
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isVideoPlaying = !_isVideoPlaying;
      if (_isVideoPlaying) {
        _chewieController!.play();
      } else {
        _chewieController!.pause();
      }
    });
  }

  Future<void> _loadUserTypeAndFavoriteStatus() async {
    if (!mounted) return;
    setState(() => _isLoadingFavorite = true);
    final user = _firebaseService.getCurrentUser();
    bool isFavorite = false;

    try {
      final userProfile = await _firebaseService.getCurrentUserProfile();
      _userProfile =
          userProfile; // Store user profile for review submission check
      _currentUserType = userProfile?.role ?? 'guest';

      if (user != null && _currentUserType == 'client') {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(widget.worker.id)
            .get();
        isFavorite = doc.exists;
      }
    } catch (e) {
      final AppStrings? appStrings = AppLocalizations.of(context);
      if (mounted && appStrings != null) {
        _showErrorSnackbar(appStrings.snackErrorCheckFavorites);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isWorkerFav = isFavorite;
          _isLoadingFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.lightImpact();
    final AppStrings? appStrings = AppLocalizations.of(context);
    if (_isLoadingFavorite || appStrings == null) return;

    // Check internet before attempting Firestore operation
    if (!await _checkInternetConnectivity(appStrings)) {
      return; // Already showed snackbar in _checkInternetConnectivity
    }

    setState(() => _isLoadingFavorite = true);
    final user = _firebaseService.getCurrentUser();
    if (user == null) {
      _showErrorSnackbar(appStrings.snackPleaseLogin);
      if (mounted) setState(() => _isLoadingFavorite = false);
      return;
    }
    try {
      final favRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.worker.id);
      if (_isWorkerFav) {
        await favRef.delete();
        _showSuccessSnackbar(appStrings.snackFavoriteRemoved);
      } else {
        await favRef.set({
          'workerId': widget.worker.id,
          'addedAt': FieldValue.serverTimestamp(),
          'workerName': widget.worker.name,
          'workerProfession': widget.worker.profession,
          'workerImageUrl': widget.worker.profileImage,
        });
        _showSuccessSnackbar(appStrings.snackFavoriteAdded);
      }
      if (mounted) setState(() => _isWorkerFav = !_isWorkerFav);
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
      _showErrorSnackbar(appStrings.snackErrorUpdateFavorites);
    } finally {
      if (mounted) setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _submitReview() async {
    HapticFeedback.mediumImpact();
    final AppStrings? appStrings = AppLocalizations.of(context);
    if (_isSubmittingReview || appStrings == null) return;

    // Check internet before attempting Firestore operation
    if (!await _checkInternetConnectivity(appStrings)) {
      return; // Already showed snackbar
    }

    final reviewText = _controllerReview.text.trim();
    if (reviewText.isEmpty || _currentRating == 0.0) {
      _showErrorSnackbar(appStrings.snackReviewMissing);
      return;
    }

    // Check user profile for completed jobs/payments for review submission
    // Ensure _userProfile is properly loaded in _loadUserTypeAndFavoriteStatus
    if (_userProfile == null ||
        (_userProfile!.jobsCompleted == null ||
            _userProfile!.jobsCompleted! < 1)) {
      // FIX: Changed to hardcoded string to avoid AppStrings getter error
      _showErrorSnackbar(
        'You need to complete at least one\njob and one payment to submit a review.',
      );
      return;
    }

    setState(() => _isSubmittingReview = true);
    try {
      await _firebaseService.addReview(
        widget.worker.id,
        reviewText,
        _currentRating,
        clientPhotoUrl: _userProfile?.profileImage,
        jobTitle: 'Review for ${widget.worker.profession}',
      ); // You might need to get an actual job title here
      _controllerReview.clear();
      setState(() => _currentRating = 0.0);
      _showSuccessSnackbar(appStrings.snackSuccessReviewSubmitted);
    } catch (e) {
      debugPrint("Error submitting review: $e");
      _showErrorSnackbar('${appStrings.snackErrorSubmitting}: $e');
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  // Helper method: _buildStatChip - Was missing, now added
  Widget _buildStatChip(
    IconData icon,
    String label,
    Color color,
    BuildContext context,
  ) {
    return Chip(
      avatar: Icon(icon, color: color, size: 20),
      label: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  String? _getDistanceText(AppStrings appStrings) {
    // Geolocator is required here for distance calculation
    if (widget.worker.latitude == null ||
        widget.worker.longitude == null ||
        _clientLat == null ||
        _clientLng == null) {
      return appStrings.workerDetailDistanceUnknown;
    }
    final distance = Geolocator.distanceBetween(
      _clientLat!,
      _clientLng!,
      widget.worker.latitude!,
      widget.worker.longitude!,
    );
    if (distance < 1000) {
      return appStrings.distanceMeters(distance.toStringAsFixed(0));
    } else {
      return appStrings.distanceKilometers(
        (distance / 1000).toStringAsFixed(1),
      );
    }
  }
  // ⬇️ REPLACE your old _showErrorSnackbar method with this one ⬇️

  void _showErrorSnackbar(String m) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final t = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m, style: TextStyle(color: t.colorScheme.onError)),
          backgroundColor: t.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    });
  }

  void _showSuccessSnackbar(String m) {
    if (!mounted) return;
    final t = Theme.of(context);
    final c = t.brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade700;
    final oc = t.brightness == Brightness.dark ? Colors.black : Colors.white;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: TextStyle(color: oc)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // --- Navigation & Dialogs ---
  Route _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  void _navigateToCreateJob() {
    Navigator.push(
      context,
      _createFadeRoute(CreateJobScreen(preselectedWorkerId: widget.worker.id)),
    );
  }

  void _navigateToQuickRequest() {
    Navigator.push(
      context,
      _createFadeRoute(QuickJobRequestScreen(worker: widget.worker)),
    );
  }

  void _showHireDialog() {
    final appStrings = AppLocalizations.of(context);
    final dialogTheme = Theme.of(context);
    if (appStrings == null) return;

    // Check internet before showing dialog that leads to network operations
    _checkInternetConnectivity(appStrings).then((isConnected) {
      if (!isConnected) {
        return; // Snackbar already shown
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            appStrings.hireWorker(widget.worker.name),
            style: dialogTheme.textTheme.titleLarge,
          ),
          backgroundColor: dialogTheme.colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text(appStrings.workerDetailHireDialogContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appStrings.generalCancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToQuickRequest();
              },
              child: Text(appStrings.workerDetailHireDialogQuick),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToCreateJob();
              },
              child: Text(appStrings.workerDetailHireDialogFull),
            ),
          ],
        ),
      );
    });
  }

  void _showFullScreenImage(
    BuildContext context,
    int initialIndex,
    List<String> images,
    String heroTagPrefix,
  ) {
    HapticFeedback.lightImpact();
    final appStrings = AppLocalizations.of(context);
    if (appStrings == null) return;

    // Check internet before attempting to show network images
    _checkInternetConnectivity(appStrings).then((isConnected) {
      if (!isConnected) {
        return; // Snackbar already shown
      }
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          pageBuilder: (BuildContext context, _, __) => _FullScreenImageViewer(
            initialIndex: initialIndex,
            images: images,
            heroTagPrefix: heroTagPrefix,
          ),
        ),
      );
    });
  }

  void _showTextDialog(String title, String content) {
    HapticFeedback.lightImpact();
    final AppStrings? appStrings = AppLocalizations.of(context);
    if (appStrings == null) return; // Ensure appStrings is available

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: Theme.of(context).textTheme.titleLarge),
          content: SingleChildScrollView(
            child: Text(content, style: Theme.of(context).textTheme.bodyLarge),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(appStrings.ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        );
      },
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final appStrings = AppLocalizations.of(context);

    if (appStrings == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: cs.primary)),
      );
    }

    // Safe data access for worker properties
    final workerName = widget.worker.name;
   
    final workerAbout = widget.worker.about;
    final workerSkills = widget.worker.skills;
    final workerExperience = widget.worker.experience;
    final workerCompletedJobs = widget.worker.completedJobs;
    final workerRating = widget.worker.rating;
    final workerProfileImageUrl = widget.worker.profileImage;
    final workerIntroVideoUrl = widget.worker.introVideoUrl;

    return Scaffold(
      backgroundColor: cs.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
     
      floatingActionButton:
          FloatingActionButton.extended(
            onPressed: () {
              // This is the navigation logic
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConversationPane(
                    // Pass the worker's ID to the conversation screen
                    otherUserId: widget.worker.id,
                  ),
                ),
              );
            },
            
            label: Text(
              appStrings
                  .workerDetailChat, // Assuming you have a string for "Chat"
              style: tt.titleMedium?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: Icon(Icons.chat_bubble_outline_rounded, color: cs.onPrimary),
            backgroundColor: cs.primary,
            elevation: 8.0,
          ).animate().slideX(
            begin: 1, // Start off-screen at the bottom
            duration: 500.milliseconds,
            delay: 800.milliseconds, // Wait for other animations to start
            curve: Curves.easeOutCubic,
          ), // Use background for base
      body: Stack(
        children: [
          // Main Scrollable Content
          Positioned.fill(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildSliverAppBar(context, appStrings), // Overlapping header

                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20.0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Call/Hire/Chat Buttons
                      if (_currentUserType == 'client')
                        _buildActionButtons(context, appStrings)
                            .animate()
                            .fadeIn(
                              delay: 200.milliseconds,
                              duration: 400.milliseconds,
                            )
                            .slideY(begin: 0.2),
                      const SizedBox(height: 20),

                      // Intro Video Section
                      if (workerIntroVideoUrl != null &&
                          workerIntroVideoUrl.isNotEmpty) ...[
                        _VideoPlayerSection(
                              key:
                                  _mainVideoSectionKey, // Assign key for scroll detection
                              chewieController: _chewieController,
                              isVideoInitialized: _isVideoInitialized,
                              isVideoPlaying: _isVideoPlaying,
                              togglePlayback: _toggleVideoPlayback,
                              profileImageUrl: workerProfileImageUrl,
                              appStrings: appStrings,
                            )
                            .animate()
                            .fadeIn(
                              delay: 300.milliseconds,
                              duration: 400.milliseconds,
                            )
                            .slideY(begin: 0.2),
                        const SizedBox(height: 20),
                      ],

                      // About Section
                      _SectionContainer(
                            title: appStrings.workerDetailAbout(workerName),
                            icon: Icons.info_outline,
                            child: Text(
                              workerAbout.isEmpty
                                  ? appStrings.workerDetailNoAbout
                                  : workerAbout,
                              style: tt.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.6,
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(
                            delay: 400.milliseconds,
                            duration: 400.milliseconds,
                          )
                          .slideY(begin: 0.2),
                      const SizedBox(height: 10),

                      // Skills Section
                      _SectionContainer(
                            title: appStrings.workerDetailSkills,
                            icon: Icons.handyman_outlined,
                            child: workerSkills.isEmpty
                                ? Text(
                                    appStrings.workerDetailNoSkills,
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: workerSkills
                                        .map(
                                          (skill) => _SkillPill(skill: skill),
                                        )
                                        .toList(),
                                  ),
                          )
                          .animate()
                          .fadeIn(
                            delay: 500.milliseconds,
                            duration: 400.milliseconds,
                          )
                          .slideY(begin: 0.2),
                      const SizedBox(height: 10),

                      // Job Stats Dashboard
                      _SectionContainer(
                            // FIX: Changed to hardcoded string to avoid AppStrings getter error
                            title: 'Performance Overview',
                            icon: Icons.analytics_outlined,
                            child: SizedBox(
                              height: 180, // Fixed height for horizontal scroll
                              child: SingleChildScrollView(
                                // FIX: Wrapped with SingleChildScrollView
                                scrollDirection: Axis
                                    .horizontal, // FIX: Added scrollDirection
                                child: Row(
                                  // This Row is at the problematic line 2116
                                  children:
                                      [
                                            _StatWheel(
                                              label:
                                                  appStrings.profileStatRating,
                                              icon: Icons.star_rounded,
                                              progress: workerRating / 5.0,
                                              valueText: workerRating
                                                  .toStringAsFixed(1),
                                              accentColor:
                                                  Colors.amber.shade600,
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ), // Added spacing between widgets
                                            _StatWheel(
                                              label: appStrings
                                                  .profileStatJobsCompleted,
                                              icon: Icons.work_outline_rounded,
                                              progress:
                                                  (workerCompletedJobs / 100.0)
                                                      .clamp(0, 1),
                                              valueText: workerCompletedJobs
                                                  .toString(),
                                              accentColor: cs.primary,
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ), // Added spacing between widgets
                                            _StatWheel(
                                              label: appStrings
                                                  .profileStatExperience,
                                              icon: Icons.history_edu_outlined,
                                              progress:
                                                  (workerExperience / 20.0)
                                                      .clamp(0, 1),
                                              valueText: '${workerExperience}+',
                                              accentColor: cs.secondary,
                                            ),
                                          ]
                                          .animate(interval: 100.milliseconds)
                                          .slideX(
                                            begin: 0.2,
                                            duration: 500.milliseconds,
                                          )
                                          .fadeIn(),
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(
                            delay: 600.milliseconds,
                            duration: 400.milliseconds,
                          )
                          .slideY(begin: 0.2),
                      const SizedBox(height: 10),

                      // Certifications
                      _buildCertificationsSection(context, appStrings)
                          .animate()
                          .fadeIn(
                            delay: 700.milliseconds,
                            duration: 400.milliseconds,
                          )
                          .slideY(begin: 0.2),
                      const SizedBox(height: 10),

                      // Gallery
                      _buildGallerySection(context, appStrings)
                          .animate()
                          .fadeIn(
                            delay: 800.milliseconds,
                            duration: 400.milliseconds,
                          )
                          .slideY(begin: 0.2),
                      const SizedBox(height: 10),

                      // Mini-Map
                      if (widget.worker.latitude != null &&
                          widget.worker.longitude != null)
                        // THE NEW, FIXED CODE
                        _LocationMapWidget(
                              appStrings: appStrings,
                              workerLat: widget.worker.latitude!,
                              workerLng: widget.worker.longitude!,
                              distanceText: _getDistanceText(appStrings),

                              clientLat: _clientLat,
                              clientLng: _clientLng,
                            )
                            .animate()
                            .fadeIn(
                              delay: 900.milliseconds,
                              duration: 400.milliseconds,
                            )
                            .slideY(begin: 0.2),
                      const SizedBox(height: 10),

                      // Reviews Section
                      _buildReviewsAndAddReview(context, appStrings)
                          .animate()
                          .fadeIn(
                            delay: 1000.milliseconds,
                            duration: 400.milliseconds,
                          )
                          .slideY(begin: 0.2),
                      const SizedBox(height: 40), // Final bottom padding
                    ]),
                  ),
                ),
              ],
            ),
          ),
          // Floating Bottom Location & Availability Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child:
                _LocationAvailabilityBar(
                  appStrings: appStrings,
                  distanceText: _getDistanceText(appStrings),
                  isAvailable:
                      widget.worker.isAvailable, // Using worker's availability
                ).animate().slideY(
                  begin: 1,
                  duration: 500.milliseconds,
                  curve: Curves.easeOutCubic,
                ),
          ),
          // Floating Video Mini-Player (top-right)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            top: _showVideoMiniPlayer
                ? MediaQuery.of(context).padding.top + 10
                : -150, // Position in top safe area
            right: _showVideoMiniPlayer ? 10 : -150,
            child: _VideoMiniPlayer(
              chewieController: _chewieController,
              onTap: _jumpToVideoSection,
              isPlaying: _isVideoPlaying,
              togglePlayback: _toggleVideoPlayback,
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION BUILDERS ---

  // Sliver App Bar (Profile header)
  SliverAppBar _buildSliverAppBar(BuildContext context, AppStrings appStrings) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      stretch: true,
      backgroundColor: cs.surface, // Background color when collapsed
      foregroundColor: cs.onSurface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: cs.onSurface.withOpacity(0.9),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (_currentUserType == 'client')
          IconButton(
            icon: _isLoadingFavorite
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  )
                : Icon(
                    _isWorkerFav
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: _isWorkerFav ? cs.primary : cs.onSurfaceVariant,
                  ),
            tooltip: _isWorkerFav
                ? appStrings.workerDetailRemoveFavoriteTooltip
                : appStrings.workerDetailAddFavoriteTooltip,
            onPressed: _toggleFavorite,
          ),
        IconButton(
          icon: Icon(Icons.share_outlined, color: cs.onSurfaceVariant),
          tooltip: appStrings.workerDetailShareProfileTooltip,
          onPressed: () {
            Share.share(
              appStrings.workerDetailShareMessage(
                widget.worker.name,
                widget.worker.profession,
                widget.worker.phoneNumber,
              ),
              subject: 'Worker Profile - FixIt',
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image (Profile)
            Positioned.fill(
              child: Hero(
                tag: 'worker_image_detail_${widget.worker.id}',
                child:
                    (widget
                        .worker
                        .profileImage
                        .isNotEmpty) // FIX: Check if string is not empty
                    ? CachedNetworkImage(
                        imageUrl: widget.worker.profileImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: cs.surfaceContainerHighest),
                        errorWidget: (context, url, error) => Container(
                          color: cs.surfaceContainerHighest,
                          child: Icon(
                            Icons.person,
                            size: 80,
                            color: cs.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                      )
                    : Container(
                        // FIX: Fallback if URL is empty
                        color: cs.surfaceContainerHighest,
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: cs.onSurfaceVariant.withOpacity(0.5),
                        ),
                      ),
              ),
            ),
            // Darker Gradient from bottom for Title Contrast
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.4, 1.0],
                    colors: [
                      Colors.transparent,
                      cs.surface.withOpacity(0.95), // Fade to surface color
                    ],
                  ),
                ),
              ),
            ),
            // Info overlaid at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.worker.name,
                      style: tt.headlineLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.worker.profession,
                      style: tt.titleMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatChip(
                            Icons.star_rounded,
                            widget.worker.rating.toStringAsFixed(1),
                            const ui.Color.fromARGB(255, 138, 251, 0),
                            context,
                          ),
                          const SizedBox(width: 10),
                          _buildStatChip(
                            Icons.work_outline_rounded,
                            appStrings.workerCardJobsDone(
                              widget.worker.completedJobs,
                            ),
                            cs.secondary,
                            context,
                          ),
                          const SizedBox(width: 10),
                          _buildStatChip(
                            Icons.history_edu_outlined,
                            appStrings.workerCardYearsExp(
                              widget.worker.experience,
                            ),
                            cs.tertiary,
                            context,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        stretchModes: const [StretchMode.zoomBackground],
      ),
    );
  }

  // Action Buttons Section (Call, Hire)
  Widget _buildActionButtons(BuildContext context, AppStrings appStrings) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.phone_outlined, color: cs.onPrimary),
              label: Text(
                appStrings.workerDetailCall,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: cs.onPrimary),
              ),
              onPressed: () async {
                final Uri phoneUri = Uri.parse(
                  'tel://${widget.worker.phoneNumber}',
                );
                final AppStrings? currentAppStrings = AppLocalizations.of(
                  context,
                );
                // Check internet before launching phone dialer
                if (currentAppStrings != null &&
                    await _checkInternetConnectivity(currentAppStrings)) {
                  if (!await launchUrl(
                    phoneUri,
                    mode: LaunchMode.externalApplication,
                  )) {
                    // FIX: Changed to hardcoded string to avoid AppStrings getter error
                    _showErrorSnackbar('Failed to make call.');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.secondary, // Accent color for call
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.handshake_rounded, color: cs.onPrimary),
              label: Text(
                appStrings.workerDetailHireNow,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: cs.onPrimary),
              ),
              onPressed: _showHireDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary, // Primary color for hire
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Certifications Section
  Widget _buildCertificationsSection(
    BuildContext context,
    AppStrings appStrings,
  ) {
    final certifications = widget.worker.certificationImages;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return _SectionContainer(
      title: appStrings.workerDetailCertifications,
      icon: Icons.verified_user_outlined,
      child: certifications.isEmpty
          ? Text(
              appStrings.workerDetailNoCerts,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2, // Adjusted aspect ratio for content
              ),
              itemCount: certifications.length,
              itemBuilder: (context, index) {
                final cert = certifications[index];
                final isImageUrl = Uri.tryParse(cert)?.hasAbsolutePath == true;
                return _CertificationPill(
                      text: isImageUrl
                          ? appStrings.viewImageButton
                          : appStrings.viewDetailsButton,
                      icon: isImageUrl
                          ? Icons.image_outlined
                          : Icons.description_outlined,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (isImageUrl) {
                          _showFullScreenImage(
                            context,
                            index,
                            certifications,
                            'cert',
                          );
                        } else {
                          _showTextDialog(
                            appStrings.workerDetailCertifications,
                            cert,
                          );
                        }
                      },
                    )
                    .animate()
                    .fade(duration: 500.milliseconds)
                    .scale(
                      duration: 500.milliseconds,
                      delay: 500.milliseconds,
                      curve: Curves.easeOut,
                    );
              },
            ),
    );
  }

  // Gallery Section
  Widget _buildGallerySection(BuildContext context, AppStrings appStrings) {
    // 1. Safely cast the galleryImages from the model into the expected Map format.
    // This assumes `widget.worker.galleryImages` is a `Map<String, dynamic>`.
    final galleryMap = Map<String, List<String>>.from(
      (widget.worker.galleryImages).map(
        (key, value) =>
            MapEntry(key.toString(), List<String>.from(value as List)),
      ),
    );

    // 2. Create a flat list for the "All" category by combining all the category lists.
    final allImages = galleryMap.values.expand((list) => list).toList();

    // 3. Create the full, filtered map for the UI, including the "All" tab.
    final Map<String, List<String>> filteredImages = {
      'All': allImages,
      ...galleryMap,
    };

    // Optional: Remove any categories that ended up being empty to keep the UI clean.
    filteredImages.removeWhere((key, value) => value.isEmpty && key != 'All');

    // If there are no images at all, show a simple message.
    if (allImages.isEmpty) {
      return _SectionContainer(
        title: appStrings.workerDetailGallery,
        icon: Icons.photo_library_outlined,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              appStrings.workerDetailNoGallery,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    // 4. Pass the correctly formatted data to the _GallerySection UI widget.
    return _SectionContainer(
      title: appStrings.workerDetailGallery,
      icon: Icons.photo_library_outlined,
      child: _GallerySection(
        appStrings: appStrings,
        allImages: allImages, // This is now correctly a List<String>
        filteredImages: filteredImages, // This is a Map<String, List<String>>
        onImageTap: (index, filterType) {
          // This logic correctly looks up the right list from the map
          _showFullScreenImage(
            context,
            index,
            filteredImages[filterType]!,
            'gallery_$filterType',
          );
        },
      ),
    );
  }

  // Reviews and Add Review Section
  Widget _buildReviewsAndAddReview(
    BuildContext context,
    AppStrings appStrings,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return _SectionContainer(
      headerWidget: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firebaseService.streamWorkerReviews(widget.worker.id),
        builder: (context, snapshot) {
          final reviews = snapshot.data ?? [];
          final canShowMore = reviews.length > _visibleReviewCount;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appStrings.workerDetailReviews(reviews.length),
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              if (reviews.length > 3)
                TextButton(
                  onPressed: () {
                    setState(
                      () => _visibleReviewCount = canShowMore
                          ? reviews.length
                          : 3,
                    );
                  },
                  child: Text(
                    canShowMore
                        ? appStrings.workerDetailShowAll
                        : appStrings.workerDetailShowLess,
                  ),
                ),
            ],
          );
        },
      ),
      icon: Icons.reviews_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firebaseService.streamWorkerReviews(widget.worker.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final reviews = snapshot.data ?? [];
              if (reviews.isEmpty) {
                return Text(
                  appStrings.workerDetailNoReviews,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                );
              }
              return Column(
                children: reviews
                    .take(_visibleReviewCount)
                    .map(
                      (review) => _buildReviewCard(context, review, appStrings),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Divider(color: cs.outlineVariant.withOpacity(0.5)),
          const SizedBox(height: 20),
          if (_currentUserType == 'client')
            _buildAddReviewSection(context, appStrings),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    BuildContext context,
    Map<String, dynamic> review,
    AppStrings appStrings,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final reviewDate =
        (review['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.tertiaryContainer,
                backgroundImage:
                    review['clientPhotoUrl'] != null &&
                        (review['clientPhotoUrl'] as String).isNotEmpty
                    ? CachedNetworkImageProvider(review['clientPhotoUrl'])
                    : null,
                child:
                    review['clientPhotoUrl'] == null ||
                        (review['clientPhotoUrl'] as String).isEmpty
                    ? Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: cs.onTertiaryContainer,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['userName'] ?? appStrings.workerDetailAnonymous,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeago.format(
                        reviewDate,
                        locale: appStrings.locale.languageCode,
                      ),
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (review['rating'] as num? ?? 0.0).toStringAsFixed(1),
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review['comment'] ?? appStrings.jobNoDescription,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddReviewSection(BuildContext context, AppStrings appStrings) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appStrings.workerDetailLeaveReview,
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: AnimatedRatingStars(
            customFilledIcon: Icons.star_rounded,
            customHalfFilledIcon: Icons.star_half_rounded,
            customEmptyIcon: Icons.star_border_rounded,
            initialRating: _currentRating,
            minRating: 0.0,
            maxRating: 5.0,
            filledColor: cs.secondary,
            emptyColor: cs.onSurface.withOpacity(0.3),
            onChanged: (double rating) =>
                setState(() => _currentRating = rating),
            displayRatingValue: true,
            interactiveTooltips: true,
            starSize: 35.0,
            animationDuration: const Duration(milliseconds: 300),
            animationCurve: Curves.easeInOut,
            readOnly: _isSubmittingReview,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _controllerReview,
          decoration: InputDecoration(
            hintText: appStrings.workerDetailWriteReviewHint,
            filled: true,
            fillColor: cs.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          maxLines: 4,
          maxLength: 500,
          enabled: !_isSubmittingReview,
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    appStrings.workerDetailReviewLengthCounter(
                      currentLength,
                      maxLength ?? 500,
                    ),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                );
              },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _isSubmittingReview
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            // FIX: Changed to hardcoded string to avoid AppStrings getter error
            label: Text(
              _isSubmittingReview ? appStrings.loading : 'Submit Review',
            ),
            onPressed: _isSubmittingReview ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper to parse date safely ---
  // (This method seems unused, but kept for completeness if needed elsewhere)
  DateTime _parseReviewDate(dynamic createdAt) {
    try {
      if (createdAt is Timestamp) return createdAt.toDate();
      if (createdAt is String) return DateTime.parse(createdAt);
    } catch (e) {
      debugPrint('Error parsing review date ($createdAt): $e');
    }
    return DateTime.now(); // Fallback
  }

  // --- Mock Data for Availability (Replace with real data) ---
  Map<DateTime, List<String>> _getMockAvailableSlots() {
    return {
      DateTime.now().add(const Duration(days: 1)): [
        '9:00 AM',
        '10:00 AM',
        '11:00 AM',
        '1:00 PM',
        '2:00 PM',
        '3:00 PM',
      ],
      DateTime.now().add(const Duration(days: 2)): [
        '9:00 AM - 5:00 PM (Full Day)',
      ],
      DateTime.now().add(const Duration(days: 3)): [],
      DateTime.now().add(const Duration(days: 4)): [
        '2:00 PM',
        '3:00 PM',
        '4:00 PM',
        '5:00 PM',
      ],
    };
  }
} // End of _WorkerDetailScreenState

// Full-screen image viewer with backdrop blur and zoom
class _FullScreenImageViewer extends StatelessWidget {
  final int initialIndex;
  final List<String> images;
  final String
  heroTagPrefix; // Kept heroTagPrefix for potential Hero animations elsewhere

  const _FullScreenImageViewer({
    required this.initialIndex,
    required this.images,
    this.heroTagPrefix = '', // Default to empty string if not provided
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (d) {
        if (d.primaryVelocity != null && d.primaryVelocity! > 300) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: Colors.black.withOpacity(0.98),
            child: Stack(
              children: [
                PageView.builder(
                  controller: PageController(initialPage: initialIndex),
                  itemCount: images.length,
                  itemBuilder: (c, i) {
                    final hTag = '$heroTagPrefix-${images[i]}';
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Hero(
                        tag: hTag,
                        child: CachedNetworkImage(
                          imageUrl: images[i],
                          fit: BoxFit.contain,
                          placeholder: (c, u) => const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white70,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: 80,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
