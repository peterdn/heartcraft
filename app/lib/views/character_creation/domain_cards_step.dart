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
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:heartcraft/models/domain.dart';
import '../../view_models/character_creation_view_model.dart';
import '../../services/game_data_service.dart';
import '../../theme/heartcraft_theme.dart';
import '../../widgets/domain_card.dart';
import '../../utils/responsive_utils.dart';

/// Domain card selection step for character creation
class DomainCardsStep extends StatelessWidget {
  static const int maxSelectedAbilities = 2;

  final CharacterCreationViewModel viewModel;

  const DomainCardsStep({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final domains = viewModel.character.domains;

    if (domains.length != 2) {
      return const Center(child: Text('Domains not set for this character.'));
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, domains),
          _buildContent(context, domains),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<Domain> domains) {
    return Padding(
      padding: ResponsiveUtils.responsiveValue(
        context,
        narrow: const EdgeInsets.only(left: 16, right: 160, bottom: 16),
        wide: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Domain Cards',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: HeartcraftTheme.gold,
                  fontSize: ResponsiveUtils.responsiveValue(context,
                      narrow: 20, wide: 24),
                ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: ResponsiveUtils.responsiveValue(context,
                        narrow: 14, wide: 16),
                  ),
              children: [
                const TextSpan(
                    text: 'Select 2 cards from your class domains: '),
                TextSpan(
                  text: domains[0].name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: HeartcraftTheme.gold,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: domains[1].name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: HeartcraftTheme.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Domain> domains) {
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: ResponsiveUtils.responsiveValue(
            context,
            narrow: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            wide: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
          ),
          child: () {
            final allAbilities =
                context.read<GameDataService>().domainAbilities;
            final availableAbilities = allAbilities
                .where((a) =>
                    a.level == 1 &&
                    (a.domain == domains[0].id || a.domain == domains[1].id))
                .toList();

            return _buildAbilitiesGrid(context, availableAbilities, domains);
          }(),
        ),
      ),
    );
  }

  Widget _buildAbilitiesGrid(
    BuildContext context,
    List<DomainAbility> availableAbilities,
    List<Domain> domains,
  ) {
    // Get current selection from ViewModel
    final selectedAbilities = availableAbilities
        .where((a) => viewModel.character.domainAbilities
            .any((sel) => sel.name == a.name))
        .toList();

    final minCardWidth = 350.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = ResponsiveUtils.responsiveValue(
      context,
      narrow: 32.0,
      wide: 48.0,
    );
    final availableWidth = screenWidth - horizontalPadding;
    final crossAxisCount = availableWidth ~/ minCardWidth;

    return MasonryGridView.count(
      crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      itemCount: availableAbilities.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => _buildAbilityCard(
        context,
        availableAbilities[index],
        domains,
        selectedAbilities,
      ),
    );
  }

  Widget _buildAbilityCard(
    BuildContext context,
    DomainAbility ability,
    List<Domain> domains,
    List<DomainAbility> selectedAbilities,
  ) {
    final isSelected = selectedAbilities.contains(ability);
    return DomainCard(
      ability: ability,
      domains: domains,
      isSelected: isSelected,
      onTap: () => _onDomainCardTap(context, ability, selectedAbilities),
    );
  }

  // Handle domain card tap, updating selection in ViewModel
  void _onDomainCardTap(BuildContext context, DomainAbility ability,
      List<DomainAbility> currentAbilities) {
    final selectedAbilities = List<DomainAbility>.from(currentAbilities);

    if (selectedAbilities.contains(ability)) {
      selectedAbilities.remove(ability);
    } else if (selectedAbilities.length < maxSelectedAbilities) {
      selectedAbilities.add(ability);
    }

    viewModel.setDomainAbilities(selectedAbilities);
  }
}
