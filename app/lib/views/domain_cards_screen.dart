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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:heartcraft/models/character.dart';
import 'package:heartcraft/models/domain.dart';
import 'package:heartcraft/services/game_data_service.dart';
import 'package:heartcraft/theme/heartcraft_theme.dart';
import 'package:heartcraft/utils/dialogs.dart';
import 'package:heartcraft/widgets/domain_card.dart';
import 'package:provider/provider.dart';
import '../view_models/character_view_model.dart';

/// Screen for managing domain cards
/// TODO: toggling between active and all is a little clunky.
/// Perhaps separate screens would be better...
/// TODO: display total recall cost of loadout change and
/// automatically validate/apply against current Stress?
class DomainCardsScreen extends StatefulWidget {
  const DomainCardsScreen({
    super.key,
  });

  @override
  State<DomainCardsScreen> createState() => DomainCardsScreenState();
}

enum SelectionMode { loadout, all }

class DomainCardsScreenState extends State<DomainCardsScreen> {
  List<DomainAbility> selectedLoadout = [];
  List<DomainAbility> selectedAllCards = [];
  SelectionMode mode = SelectionMode.loadout;

  static const minCardWidth = 350.0;

  @override
  void initState() {
    super.initState();

    final characterViewModel = context.read<CharacterViewModel>();
    final character = characterViewModel.currentCharacter!;

    selectedLoadout = List.from(character.domainLoadout);
    selectedAllCards = List.from(character.domainAbilities);
  }

  void _toggleMode() {
    setState(() {
      mode = mode == SelectionMode.loadout
          ? SelectionMode.all
          : SelectionMode.loadout;
    });
  }

  void _toggleAbility(DomainAbility ability) {
    setState(() {
      final selectedList =
          mode == SelectionMode.loadout ? selectedLoadout : selectedAllCards;

      if (selectedList.any((a) => a.id == ability.id)) {
        selectedList.removeWhere((a) => a.id == ability.id);

        // If removing from all cards, also remove from loadout
        if (mode == SelectionMode.all) {
          selectedLoadout.removeWhere((a) => a.id == ability.id);
        }
      } else {
        if (mode == SelectionMode.loadout &&
            selectedLoadout.length >= Character.maxDomainLoadoutSize) {
          // Reached max loadout size
          return;
        }
        selectedList.add(ability);
      }
    });
  }

  bool get _isFormValid {
    final characterViewModel = context.read<CharacterViewModel>();
    final character = characterViewModel.currentCharacter!;

    // Total number of chosen domain cards for this character must not change
    if (selectedAllCards.length != character.domainAbilities.length) {
      return false;
    }

    // Loadout must not exceed max size
    if (selectedLoadout.length > Character.maxDomainLoadoutSize) {
      return false;
    }

    // Loadout selection must be a subset of all chosen domain cards
    return selectedLoadout.every((loadoutCard) =>
        selectedAllCards.any((card) => card.id == loadoutCard.id));
  }

  void _saveAndReturn() {
    if (!_isFormValid) return;

    final characterViewModel = context.read<CharacterViewModel>();

    characterViewModel.updateDomainAbilities(selectedAllCards);
    characterViewModel.updateDomainLoadout(selectedLoadout);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final characterViewModel = context.watch<CharacterViewModel>();
    final character = characterViewModel.currentCharacter;

    if (character == null) {
      return const Scaffold(
        body: Center(child: Text('No character loaded')),
      );
    }

    final availableAbilities = mode == SelectionMode.loadout
        ? selectedAllCards
        : context.read<GameDataService>().getAvailableAbilitiesForClass(
              character.characterClass!,
              maxLevel: character.level,
            );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await showExitConfirmation(
          context,
          'changes',
        );
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Domain Cards'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: _isFormValid ? _saveAndReturn : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isFormValid ? HeartcraftTheme.gold : Colors.grey,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white70,
                ),
                icon: Icon(_isFormValid ? Icons.save : Icons.pending_actions),
                label: Text(
                  'Save',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildHeader(context, character),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child:
                    _buildAbilitiesGrid(context, availableAbilities, character),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Character character) {
    final isActiveMode = mode == SelectionMode.loadout;
    final maxLoadoutSize =
        min(Character.maxDomainLoadoutSize, character.domainAbilities.length);
    final selectedCount =
        isActiveMode ? selectedLoadout.length : selectedAllCards.length;
    final totalCount =
        isActiveMode ? maxLoadoutSize : character.domainAbilities.length;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: HeartcraftTheme.surfaceColor,
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Select ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  isActiveMode ? 'max $maxLoadoutSize' : 'exactly $totalCount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: HeartcraftTheme.gold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Text(' '),
                InkWell(
                  onTap: _toggleMode,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: HeartcraftTheme.gold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isActiveMode ? 'active' : 'all',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                Text(
                  ' domain cards ($selectedCount/$totalCount)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TODO: extract this into a separate widget
  Widget _buildAbilitiesGrid(
    BuildContext context,
    List<DomainAbility> availableAbilities,
    Character character,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 32.0;
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
        character,
      ),
    );
  }

  Widget _buildAbilityCard(
    BuildContext context,
    DomainAbility ability,
    Character character,
  ) {
    final selectedAbilities =
        mode == SelectionMode.loadout ? selectedLoadout : selectedAllCards;
    final isSelected = selectedAbilities.any((a) => a.id == ability.id);

    return DomainCard(
      ability: ability,
      domains: character.domains,
      isSelected: isSelected,
      onTap: () => _toggleAbility(ability),
    );
  }
}
