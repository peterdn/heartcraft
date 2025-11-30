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

import 'package:flutter/material.dart';
import '../../theme/heartcraft_theme.dart';

/// Resource card widget for displaying and editing character resources
/// Used for armor, HP, stress, and hope, for both character and companion
class ResourceCard extends StatelessWidget {
  final String title;
  final int maxValue;
  final int currentValue;
  final IconData icon;
  final Color color;
  final bool editMode;
  final VoidCallback? onMaxDecrement;
  final VoidCallback onMaxIncrement;
  final Function(int) onValueChanged;

  const ResourceCard({
    super.key,
    required this.title,
    required this.maxValue,
    required this.currentValue,
    required this.icon,
    required this.color,
    required this.editMode,
    required this.onMaxDecrement,
    required this.onMaxIncrement,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (editMode) ...[
                  Row(
                    children: [
                      ResourceEditButton(
                        icon: Icons.remove_circle_outline,
                        onPressed: onMaxDecrement,
                      ),
                      ResourceEditButton(
                        icon: Icons.add_circle_outline,
                        onPressed: onMaxIncrement,
                      ),
                    ],
                  ),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: HeartcraftTheme.gold,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '($currentValue/$maxValue)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ResourceSlots(
              maxSlots: maxValue,
              filledSlots: currentValue,
              icon: icon,
              color: color,
              editMode: true,
              onSlotTapped: onValueChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Edit button for adjusting resource max values
class ResourceEditButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const ResourceEditButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        size: 20,
      ),
      onPressed: onPressed,
      constraints: const BoxConstraints(
        minHeight: 24,
        minWidth: 24,
      ),
      padding: const EdgeInsets.only(right: 8),
    );
  }
}

/// Interactive resource slots for tracking current values
class ResourceSlots extends StatelessWidget {
  final int maxSlots;
  final int filledSlots;
  final IconData icon;
  final Color color;
  final bool editMode;
  final Function(int) onSlotTapped;

  const ResourceSlots({
    super.key,
    required this.maxSlots,
    required this.filledSlots,
    required this.icon,
    required this.color,
    required this.editMode,
    required this.onSlotTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(maxSlots, (index) {
        final isFilled = index < filledSlots;
        return GestureDetector(
          onTap: editMode
              ? () {
                  // When selecting an unfilled slot, fill up to and including that slot
                  // If selecting a filled slot, clear from that point onward
                  final newValue = isFilled ? index : index + 1;
                  onSlotTapped(newValue);
                }
              : null,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 2,
              ),
              color: isFilled
                  ? color.withValues(alpha: 0.8)
                  : color.withValues(alpha: 0.1),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isFilled ? Colors.white : color.withValues(alpha: 0.6),
            ),
          ),
        );
      }),
    );
  }
}
