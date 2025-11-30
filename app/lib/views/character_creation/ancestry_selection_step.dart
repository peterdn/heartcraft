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
import 'package:heartcraft/models/ancestry.dart';
import 'package:provider/provider.dart';
import '../../providers/character_creation_provider.dart';
import '../../services/game_data_service.dart';
import '../../theme/heartcraft_theme.dart';
import '../../utils/responsive_utils.dart';

/// Ancestry selection step in character creation
/// Supports mixed ancestry mode which then allows user to select the first feature
/// from the primary ancestry and second feature from the secondary ancestry.
class AncestrySelectionStep extends StatelessWidget {
  const AncestrySelectionStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: ResponsiveUtils.responsiveValue(
            context,
            narrow: const EdgeInsets.only(left: 16, right: 160),
            wide: const EdgeInsets.symmetric(horizontal: 24.0),
          ),
          child: Text(
            'Choose your ancestry',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: HeartcraftTheme.gold,
                  fontSize: ResponsiveUtils.responsiveValue(context,
                      narrow: 20, wide: 24),
                ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: ResponsiveUtils.responsiveValue(
            context,
            narrow: const EdgeInsets.only(left: 16, right: 160),
            wide: const EdgeInsets.symmetric(horizontal: 24.0),
          ),
          child: Text(
            'Your ancestry represents your species or lineage and grants you unique abilities.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: ResponsiveUtils.responsiveValue(context,
                      narrow: 14, wide: 16),
                ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Consumer<CharacterCreationProvider>(
            builder: (context, characterProvider, child) {
              final ancestries = context.read<GameDataService>().ancestries;
              final selectedAncestry = characterProvider.character.ancestry;
              final selectedSecondaryAncestry =
                  characterProvider.character.secondAncestry;
              final isMixedMode = characterProvider.isMixedAncestryMode;

              return ListView.builder(
                itemCount: ancestries.length,
                itemBuilder: (context, index) {
                  final ancestry = ancestries[index];
                  final isPrimarySelected = selectedAncestry?.id == ancestry.id;
                  final isSecondarySelected =
                      selectedSecondaryAncestry?.id == ancestry.id;

                  // This ancestry can currently be chosen as the secondary ancestry when:
                  // - A primary ancestry is already selected
                  // - Mixed mode is enabled (i.e. user has chosen to have a mixed ancestry)
                  // - This ancestry is not the same as the primary ancestry
                  // - This ancestry has a 2nd feature to gain
                  final canThisAncestryBeSecondary = isMixedMode &&
                      selectedAncestry != null &&
                      ancestry.id != selectedAncestry.id &&
                      ancestry.features.length > 1; // Must have second feature

                  return _buildAncestryCard(
                    context,
                    ancestry,
                    canThisAncestryBeSecondary
                        ? isSecondarySelected
                        : isPrimarySelected,
                    characterProvider,
                    isSecondary: canThisAncestryBeSecondary,
                    isMixedMode: isMixedMode,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build a card for ancestry selection
  Widget _buildAncestryCard(
    BuildContext context,
    Ancestry ancestry,
    bool isSelected,
    CharacterCreationProvider characterProvider, {
    required bool isSecondary,
    required bool isMixedMode,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: isSelected
          ? HeartcraftTheme.darkPrimaryPurple.withValues(alpha: 0.3)
          : isSecondary
              ? Colors.grey.withValues(alpha: 0.1)
              : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: isSelected
            ? const BorderSide(color: HeartcraftTheme.gold, width: 2)
            : isSecondary
                ? const BorderSide(color: Colors.grey, width: 1)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => isSecondary
            ? characterProvider.selectSecondaryAncestry(ancestry)
            : characterProvider.selectAncestry(ancestry),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ancestry.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: isSelected ? HeartcraftTheme.gold : null,
                          ),
                    ),
                  ),

                  // Top right corner: checkbox to enable/disable mixed ancestry mode
                  // (or for the secondary ancestry, just a label)
                  if (isSecondary && isSelected) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        'Mixed heritage (secondary)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.orange[700],
                            ),
                      ),
                    ),
                  ] else if (!isSecondary &&
                      isSelected &&
                      ancestry.features.isNotEmpty) ...[
                    InkWell(
                      onTap: () => characterProvider
                          .toggleMixedAncestryMode(!isMixedMode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: isMixedMode
                              ? HeartcraftTheme.gold.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isMixedMode
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 16,
                              color: isMixedMode
                                  ? HeartcraftTheme.gold
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Mixed heritage (primary)',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: isMixedMode
                                        ? HeartcraftTheme.gold
                                        : Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (ancestry.description != null) ...[
                const SizedBox(height: 8),
                Text(ancestry.description!),
              ],

              // Show ancestry features
              if (ancestry.features.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  isSecondary ? 'Feature gained:' : 'Features:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? HeartcraftTheme.gold : null,
                      ),
                ),
                const SizedBox(height: 4),

                // For secondary ancestry, show only the second feature
                if (isSecondary && ancestry.features.length > 1) ...[
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? HeartcraftTheme.gold.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ancestry.features[1].name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ancestry.features[1].description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ] else if (!isSecondary) ...[
                  // For primary ancestry, show all features or if in mixed mode, only first
                  ...ancestry.features.asMap().entries.map((entry) {
                    final isFirstFeature = entry.key == 0;
                    final feature = entry.value;
                    final showFeature =
                        !isMixedMode || (isMixedMode && isFirstFeature);

                    if (!showFeature) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? HeartcraftTheme.gold.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              feature.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],

              // Helper text for mixed mode (primary only)
              if (!isSecondary && isSelected && isMixedMode) ...[
                const SizedBox(height: 2),
                Text(
                  'Select a second ancestry to gain its second feature',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
