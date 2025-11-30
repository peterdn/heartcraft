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
import 'package:flutter/material.dart';
import '../services/portrait_service.dart';
import '../theme/heartcraft_theme.dart';

/// Displays a character portrait image
class CharacterPortrait extends StatefulWidget {
  final String? portraitPath;
  final double size;
  final bool showBorder;
  final VoidCallback? onTap;
  final int? refreshKey; // Optional key to force refresh

  const CharacterPortrait({
    super.key,
    this.portraitPath,
    this.size = 96.0,
    this.showBorder = true,
    this.onTap,
    this.refreshKey,
  });

  @override
  State<CharacterPortrait> createState() => _CharacterPortraitState();
}

class _CharacterPortraitState extends State<CharacterPortrait> {
  final PortraitService _portraitService = PortraitService();
  String? _fullPortraitPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPortraitPath();
  }

  @override
  void didUpdateWidget(CharacterPortrait oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portraitPath != widget.portraitPath ||
        oldWidget.refreshKey != widget.refreshKey) {
      _loadPortraitPath();
    }
  }

  Future<void> _loadPortraitPath() async {
    setState(() {
      _isLoading = true;
    });

    // Clear any existing cached image first
    if (_fullPortraitPath != null) {
      final imageProvider = FileImage(File(_fullPortraitPath!));
      imageProvider.evict();
    }

    final fullPath =
        await _portraitService.getPortraitPath(widget.portraitPath);

    if (mounted) {
      setState(() {
        _fullPortraitPath = fullPath;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: widget.showBorder
              ? Border.all(
                  color: HeartcraftTheme.gold,
                  width: 2.0,
                )
              : null,
        ),
        child: ClipOval(
          child: _buildPortraitContent(),
        ),
      ),
    );
  }

  Widget _buildPortraitContent() {
    if (_isLoading) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_fullPortraitPath != null && File(_fullPortraitPath!).existsSync()) {
      return Image.file(
        File(_fullPortraitPath!),
        key: ValueKey('${_fullPortraitPath}_${widget.refreshKey ?? 0}'),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultPortrait();
        },
      );
    }

    return _buildDefaultPortrait();
  }

  Widget _buildDefaultPortrait() {
    return Container(
      color: HeartcraftTheme.backgroundColor,
      child: Icon(
        Icons.person,
        size: widget.size * 0.6,
        color: HeartcraftTheme.gold,
      ),
    );
  }
}

/// Character portrait in edit mode
/// Options to pick from gallery, take photo, or delete
class EditableCharacterPortrait extends StatelessWidget {
  final String? portraitPath;
  final double size;
  final VoidCallback? onPickFromGallery;
  final VoidCallback? onTakePhoto;
  final VoidCallback? onRemove;
  final int? refreshKey; // Optional key to force refresh

  const EditableCharacterPortrait({
    super.key,
    this.portraitPath,
    this.size = 120.0,
    this.onPickFromGallery,
    this.onTakePhoto,
    this.onRemove,
    this.refreshKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CharacterPortrait(
              portraitPath: portraitPath,
              size: size,
              showBorder: true,
              refreshKey: refreshKey,
            ),
            if (portraitPath != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                    onPressed: onRemove,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: HeartcraftTheme.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 16,
                  ),
                  onPressed: () => _showPortraitOptions(context),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPortraitOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  onPickFromGallery?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  onTakePhoto?.call();
                },
              ),
              if (portraitPath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Portrait'),
                  onTap: () {
                    Navigator.pop(context);
                    onRemove?.call();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
