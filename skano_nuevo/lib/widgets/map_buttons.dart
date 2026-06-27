import 'package:flutter/material.dart';

class MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const MapButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class ZoomButtons extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const ZoomButtons({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MapButton(
          icon: Icons.add,
          onTap: onZoomIn,
        ),
        const SizedBox(height: 10),
        MapButton(
          icon: Icons.remove,
          onTap: onZoomOut,
        ),
      ],
    );
  }
}

class CenterLocationButton extends StatelessWidget {
  final VoidCallback onTap;

  const CenterLocationButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MapButton(
      icon: Icons.my_location,
      onTap: onTap,
    );
  }
}
