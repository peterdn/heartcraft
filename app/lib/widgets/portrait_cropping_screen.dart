// Copyright (c) 2025 Peter Nelson & Heartcraft contributors
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Website: https://heartcraft.app
// GitHub: https://github.com/peterdn/heartcraft
//
// Heartcraft is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Heartcraft is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import '../theme/heartcraft_theme.dart';

/// Screen for cropping character portrait images
/// Powered by https://pub.dev/packages/crop_your_image
class PortraitCroppingScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final CropController _cropController = CropController();

  PortraitCroppingScreen({
    super.key,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Portrait'),
        backgroundColor: HeartcraftTheme.darkPurple,
        foregroundColor: HeartcraftTheme.primaryTextColor,
        actions: [
          TextButton(
            onPressed: () => _cropController.crop(),
            child: const Text(
              'Done',
              style: TextStyle(
                color: HeartcraftTheme.gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Crop(
          image: imageBytes,
          controller: _cropController,
          onCropped: (result) {
            if (result is CropSuccess) {
              Navigator.pop(context, result.croppedImage);
            } else if (result is CropFailure) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to crop image'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          aspectRatio: 1.0,
          radius: 16.0,
          cornerDotBuilder: (size, edgeAlignment) => Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: HeartcraftTheme.gold,
              shape: BoxShape.circle,
            ),
          ),
          baseColor: Colors.black.withValues(alpha: 0.7),
          maskColor: Colors.black.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
