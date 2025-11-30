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

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/portrait_cropping_screen.dart';

/// Service for managing character portrait images
class PortraitService {
  static const String _portraitDirectoryName = 'portraits';

  /// Get the directory where portrait images are stored
  Future<Directory> getPortraitsDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final charactersDir = Directory('${appDir.path}/characters');
    final portraitsDir =
        Directory('${charactersDir.path}/$_portraitDirectoryName');

    // Create directory if it doesn't exist
    if (!await portraitsDir.exists()) {
      await portraitsDir.create(recursive: true);
    }

    return portraitsDir;
  }

  /// Get the full path to a character's portrait image
  Future<String?> getPortraitPath(String? portraitFileName) async {
    if (portraitFileName == null || portraitFileName.isEmpty) {
      return null;
    }

    try {
      final portraitsDir = await getPortraitsDirectory();
      final portraitFile = File('${portraitsDir.path}/$portraitFileName');

      if (await portraitFile.exists()) {
        return portraitFile.path;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete a character's portrait image
  Future<bool> deletePortrait(String? portraitFileName) async {
    if (portraitFileName == null || portraitFileName.isEmpty) {
      return true;
    }

    try {
      final portraitsDir = await getPortraitsDirectory();
      final portraitFile = File('${portraitsDir.path}/$portraitFileName');

      if (await portraitFile.exists()) {
        await portraitFile.delete();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Pick and crop an image from gallery
  Future<String?> pickAndCropPortraitFromGallery(
      String characterId, BuildContext context) async {
    return pickAndCropImageFromSource(
        characterId, context, ImageSource.gallery);
  }

  /// Pick image from camera
  Future<String?> takeAndCropPortraitFromCamera(
      String characterId, BuildContext context) async {
    return pickAndCropImageFromSource(characterId, context, ImageSource.camera);
  }

  /// Pick and crop image from specified source
  Future<String?> pickAndCropImageFromSource(
      String characterId, BuildContext context, ImageSource source) async {
    try {
      // Pick image from camera
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        return null;
      }

      final Uint8List imageBytes = await image.readAsBytes();

      if (!context.mounted) {
        return null;
      }

      // Navigate to cropping screen
      final Uint8List? croppedBytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (context) => PortraitCroppingScreen(
            imageBytes: imageBytes,
          ),
        ),
      );

      if (croppedBytes == null) {
        return null;
      }

      // Save the cropped image to the portraits directory
      final portraitsDir = await getPortraitsDirectory();
      final fileName = '$characterId.jpg';
      final destinationPath = '${portraitsDir.path}/$fileName';

      await File(destinationPath).writeAsBytes(croppedBytes);

      return fileName;
    } catch (e) {
      return null;
    }
  }
}
