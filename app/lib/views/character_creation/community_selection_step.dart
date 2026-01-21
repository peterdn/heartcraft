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
import 'package:heartcraft/models/community.dart';
import 'package:provider/provider.dart';
import '../../view_models/character_creation_view_model.dart';
import '../../services/game_data_service.dart';
import '../../theme/heartcraft_theme.dart';
import '../../utils/responsive_utils.dart';

/// Community selection step in character creation
class CommunitySelectionStep extends StatelessWidget {
  const CommunitySelectionStep({super.key});

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
            'Choose your community',
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
            'Your community represents the culture or environment that shaped your upbringing.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: ResponsiveUtils.responsiveValue(context,
                      narrow: 14, wide: 16),
                ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Consumer<CharacterCreationViewModel>(
            builder: (context, characterViewModel, child) {
              final communities = context.read<GameDataService>().communities;
              final selectedCommunity = characterViewModel.character.community;

              return ListView.builder(
                itemCount: communities.length,
                itemBuilder: (context, index) {
                  final community = communities[index];
                  final isSelected = selectedCommunity?.id == community.id;

                  return _buildCommunityCard(
                    context,
                    isSelected,
                    community,
                    characterViewModel,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityCard(BuildContext context, bool isSelected,
      Community community, CharacterCreationViewModel characterViewModel) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      color: isSelected
          ? HeartcraftTheme.darkPrimaryPurple.withValues(alpha: 0.3)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: isSelected
            ? const BorderSide(color: HeartcraftTheme.gold, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => characterViewModel.selectCommunity(community),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                community.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSelected ? HeartcraftTheme.gold : null,
                    ),
              ),
              if (community.description != null) ...[
                const SizedBox(height: 8),
                Text(community.description!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
