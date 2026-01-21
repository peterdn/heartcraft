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

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:heartcraft/models/domain.dart';
import 'package:heartcraft/models/experience.dart';
import 'package:heartcraft/models/class.dart';
import 'package:heartcraft/models/companion.dart';
import 'package:heartcraft/models/equipment.dart';
import 'package:heartcraft/models/ancestry.dart';
import 'package:heartcraft/models/community.dart';
import 'package:heartcraft/models/trait.dart';
import 'package:heartcraft/services/game_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';

/// Step in the character creation wizard
enum CharacterCreationStep {
  classAndSubclass,
  companion,
  ancestry,
  community,
  traits,
  equipment,
  background,
  experiences,
  domainCards,
  personalDetails,
  review;

  String get name {
    switch (this) {
      case CharacterCreationStep.classAndSubclass:
        return 'Class';
      case CharacterCreationStep.companion:
        return 'Companion';
      case CharacterCreationStep.ancestry:
        return 'Ancestry';
      case CharacterCreationStep.community:
        return 'Community';
      case CharacterCreationStep.traits:
        return 'Traits';
      case CharacterCreationStep.equipment:
        return 'Equipment';
      case CharacterCreationStep.background:
        return 'Background';
      case CharacterCreationStep.experiences:
        return 'Experiences';
      case CharacterCreationStep.domainCards:
        return 'Domain Cards';
      case CharacterCreationStep.personalDetails:
        return 'Details';
      case CharacterCreationStep.review:
        return 'Review';
    }
  }
}

/// ViewModel for managing the character creation wizard state.
/// This is more complex than just "character state" as we need to
/// track partial (in-progress) selections, and step completion.
class CharacterCreationViewModel extends ChangeNotifier {
  final GameDataService gameDataService;

  CharacterCreationViewModel({required this.gameDataService});

  // Available trait values for character creation
  static const List<int> availableTraitValues = [2, 1, 1, 0, 0, -1];

  Map<Trait, int?> _inProgressTraits = {
    Trait.agility: null,
    Trait.instinct: null,
    Trait.strength: null,
    Trait.finesse: null,
    Trait.presence: null,
    Trait.knowledge: null,
  };
  Map<Trait, int?> get inProgressTraits => _inProgressTraits;

  // Character being created
  Character _character = Character.empty();
  Character get character => _character;

  // Mixed ancestry UI state tracking
  bool _isMixedAncestryMode = false;
  bool get isMixedAncestryMode => _isMixedAncestryMode;

  // Current wizard step
  CharacterCreationStep _currentStep = CharacterCreationStep.classAndSubclass;
  CharacterCreationStep get currentStep => _currentStep;

  // Completion state of each step (they can be completed out of order)
  final Map<CharacterCreationStep, bool> _stepCompleted = {
    CharacterCreationStep.classAndSubclass: false,
    CharacterCreationStep.companion: false,
    CharacterCreationStep.ancestry: false,
    CharacterCreationStep.community: false,
    CharacterCreationStep.traits: false,
    CharacterCreationStep.equipment: false,
    CharacterCreationStep.background: false,
    CharacterCreationStep.experiences: false,
    CharacterCreationStep.domainCards: false,
    CharacterCreationStep.personalDetails: false,
    CharacterCreationStep.review: false,
  };

  // Equipment selection state for inventory
  // items not directly stored on character model
  // TODO: explicitly store these on character model?
  Map<String, String> optionGroupSelections = {};
  String? selectedClassItem;

  bool isStepCompleted(CharacterCreationStep step) =>
      _stepCompleted[step] ?? false;

  // Background and experiences are optional: user may
  // want to just skip them and fill them in later?
  bool isStepOptional(CharacterCreationStep step) {
    return step == CharacterCreationStep.background ||
        step == CharacterCreationStep.experiences;
  }

  /// Whether the current subclass has a companion
  bool get currentSubclassHasCompanion {
    return _character.subclass?.companion != null;
  }

  /// Set the companion for the character
  void setCompanion(String name, String animal, List<Experience> experiences) {
    if (_character.subclass?.companion != null) {
      _character.companion = Companion(
        companionTemplate: _character.subclass!.companion!,
        name: name,
        subType: animal,
        experiences: experiences,
      );
      _stepCompleted[CharacterCreationStep.companion] =
          name.isNotEmpty && animal.isNotEmpty;
      _updateState();
    }
  }

  /// Check if there is character creation progress saved
  Future<bool> hasCharacterCreationInProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('character_creation_in_progress') ?? false;
  }

  /// Initialize the ViewModel: called when the app starts
  Future<void> initialize() async {
    if (await hasCharacterCreationInProgress()) {
      await _loadProgress();
    } else {
      startNewCharacter();
    }
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // Load in-progress character data from shared prefs
    final characterXml =
        prefs.getString('character_creation_progress_character');
    if (characterXml != null) {
      _character = Character.fromXml(characterXml, gameDataService);
    }

    // Load in-progress traits
    final traitsJson = prefs.getString('character_creation_progress_traits');
    if (traitsJson != null) {
      final Map<String, dynamic> traitsMap = jsonDecode(traitsJson);
      _inProgressTraits = traitsMap.map((traitName, value) =>
          MapEntry(Trait.values.byName(traitName), value as int?));
    } else {
      // They must be complete; load from character model
      _inProgressTraits = {
        for (Trait trait in Trait.values) trait: _character.traits[trait],
      };
    }

    // Load current step
    final stepIndex = prefs.getInt('current_step') ?? 0;
    _currentStep = CharacterCreationStep.values[stepIndex];

    // Load step completion states
    for (var step in CharacterCreationStep.values) {
      _stepCompleted[step] =
          prefs.getBool('step_${step.index}_completed') ?? false;
    }

    // Are we in mixed ancestry UI mode?
    _isMixedAncestryMode = prefs.getBool('mixed_ancestry_mode') ?? false;

    notifyListeners();
  }

  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("character_creation_in_progress", true);

    // Save in-progress character data to shared prefs
    await prefs.setString(
        'character_creation_progress_character', _character.toXml());

    // Save in-progress traits
    await prefs.setString(
        "character_creation_progress_traits",
        jsonEncode(_inProgressTraits.map(
            (key, value) => MapEntry(key.toString().split('.').last, value))));

    // Save current wizard step
    await prefs.setInt('current_step', _currentStep.index);

    // Save step completion states
    for (var step in CharacterCreationStep.values) {
      await prefs.setBool(
          'step_${step.index}_completed', _stepCompleted[step] ?? false);
    }

    // Save mixed ancestry UI mode
    await prefs.setBool('mixed_ancestry_mode', _isMixedAncestryMode);
  }

  void _updateState() {
    saveProgress();
    notifyListeners();
  }

  void startNewCharacter() {
    _character = Character.empty();
    _currentStep = CharacterCreationStep.classAndSubclass;
    _isMixedAncestryMode = false;
    _resetCompletionStatus();

    _inProgressTraits = {
      for (Trait trait in Trait.values) trait: null,
    };

    // NOTE: Do NOT _updateState() here to avoid saving empty progress e.g.
    // when user exits immediately after starting new character
  }

  /// Reset all step completion statuses
  void _resetCompletionStatus() {
    for (var step in CharacterCreationStep.values) {
      _stepCompleted[step] = false;
    }
  }

  /// Move to the next step in the wizard
  bool goToNextStep() {
    _stepCompleted[_currentStep] = true;
    if (_currentStep == CharacterCreationStep.review) {
      return true;
    }
    int nextIndex = _currentStep.index + 1;
    // Skip Companion step for subclasses without a companion
    if (nextIndex < CharacterCreationStep.values.length &&
        CharacterCreationStep.values[nextIndex] ==
            CharacterCreationStep.companion &&
        !currentSubclassHasCompanion) {
      ++nextIndex;
    }
    if (nextIndex < CharacterCreationStep.values.length) {
      _currentStep = CharacterCreationStep.values[nextIndex];
    }
    _updateState();
    return false;
  }

  /// Go back to the previous step in the wizard
  void goToPreviousStep() {
    if (_currentStep.index == 0) {
      return;
    }
    int prevIndex = _currentStep.index - 1;
    // Skip Companion step for subclasses without a companion
    if (prevIndex >= 0 &&
        CharacterCreationStep.values[prevIndex] ==
            CharacterCreationStep.companion &&
        !currentSubclassHasCompanion) {
      --prevIndex;
    }
    if (prevIndex >= 0) {
      _currentStep = CharacterCreationStep.values[prevIndex];
    }
    _updateState();
  }

  /// Jump to a specific step in the wizard
  void goToStep(CharacterCreationStep step) {
    _currentStep = step;
    _updateState();
  }

  /// Update the ancestry selection step completion based on current state
  void _updateStepCompletion() {
    if (_character.ancestry != null) {
      if (_isMixedAncestryMode) {
        // In mixed mode, need both ancestries selected
        _stepCompleted[CharacterCreationStep.ancestry] =
            _character.secondAncestry != null;
      } else {
        // In normal mode, just need primary ancestry
        _stepCompleted[CharacterCreationStep.ancestry] = true;
      }
    } else {
      _stepCompleted[CharacterCreationStep.ancestry] = false;
    }
  }

  /// Clear saved character creation progress
  Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('character_creation_in_progress');
    await prefs.remove('character_creation_progress_character');
    await prefs.remove('character_creation_progress_traits');
    await prefs.remove('current_step');

    // Clear step completion statuses
    for (var step in CharacterCreationStep.values) {
      await prefs.remove('step_${step.index}_completed');
    }

    // Clear mixed ancestry mode
    await prefs.remove('mixed_ancestry_mode');
  }

  /// Complete character creation and clear saved progress,
  /// whether by creating a character or cancelling the process
  Future<void> exitCharacterCreation() async {
    await clearProgress();
    _character = Character.empty();
    _currentStep = CharacterCreationStep.classAndSubclass;
    _isMixedAncestryMode = false;
    _resetCompletionStatus();
    notifyListeners();
  }

  /// Check if all required steps are completed
  bool isCharacterComplete() {
    // Required steps (experiences is optional like equipment and background)
    return _stepCompleted[CharacterCreationStep.classAndSubclass]! &&
        _stepCompleted[CharacterCreationStep.ancestry]! &&
        _stepCompleted[CharacterCreationStep.community]! &&
        _stepCompleted[CharacterCreationStep.traits]! &&
        _stepCompleted[CharacterCreationStep.background]! &&
        _stepCompleted[CharacterCreationStep.experiences]! &&
        _stepCompleted[CharacterCreationStep.domainCards]! &&
        _stepCompleted[CharacterCreationStep.personalDetails]!;
  }

  // ***************************************************
  // * Character creation step completion methods      *
  // * TODO: character model mutation somewhere else?  *
  // ***************************************************

  /// Select a class and subclass for the character
  Future<void> selectClass(
      CharacterClass characterClass, SubClass? subclass) async {
    _character.characterClass = characterClass;
    _character.subclass = subclass;

    // Copy domains from the selected class
    // TODO: why don't I link em directly through class?
    _character.domains = gameDataService.domains
        .where((domain) => characterClass.domains.contains(domain.id))
        .toList();

    // Clear companion if new subclass doesn't have one
    if (subclass?.companion == null) {
      _character.companion = null;
      _stepCompleted[CharacterCreationStep.companion] = false;
    } else {
      // Reset companion step completion if subclass has a companion
      _stepCompleted[CharacterCreationStep.companion] = false;
    }

    _character.evasion = characterClass.startingEvasion;
    _character.maxHitPoints = characterClass.startingHitPoints;
    _character.currentHitPoints = 0;

    // Clear equipment selections when class changes
    clearEquipmentSelections();

    // Clear background answers when class changes
    _character.backgroundQuestionnaireAnswers.clear();

    _stepCompleted[CharacterCreationStep.classAndSubclass] = true;
    _updateState();
  }

  /// Select an ancestry for the character
  Future<void> selectAncestry(Ancestry ancestry) async {
    _character.ancestry = ancestry;

    if (!_isMixedAncestryMode) {
      // Clear second ancestry if not in mixed mode
      _character.secondAncestry = null;
    }

    _updateStepCompletion();
    _updateState();
  }

  void toggleMixedAncestryMode(bool enabled) {
    if (enabled == _isMixedAncestryMode) {
      return;
    }

    _isMixedAncestryMode = enabled;

    // Clear second ancestry as either we are exiting mixed mode
    // therefore it is not needed, or entering mixed mode therefore
    // force selection of a second ancestry
    _character.secondAncestry = null;

    _updateStepCompletion();
    _updateState();
  }

  /// Select a secondary ancestry for mixed ancestry
  Future<void> selectSecondaryAncestry(Ancestry ancestry) async {
    if (!_isMixedAncestryMode) return;

    _character.secondAncestry = ancestry;
    _updateStepCompletion();
    _updateState();
  }

  /// Select a community for the character
  Future<void> selectCommunity(Community community) async {
    _character.community = community;

    _stepCompleted[CharacterCreationStep.community] = true;
    _updateState();
  }

  /// Assign trait values
  void assignTraits(Map<Trait, int?> traits) {
    _inProgressTraits = traits;

    _character.traits.clear();
    for (final entry in traits.entries) {
      if (entry.value != null) {
        _character.traits[entry.key] = entry.value!;
      }
    }

    // Only mark step as complete if all required trait values are assigned
    final assignedValues = traits.values.toList();
    final isComplete = assignedValues.length == Trait.values.length &&
        assignedValues.every((value) => availableTraitValues.contains(value)) &&
        availableTraitValues.every((value) => assignedValues.contains(value));

    _stepCompleted[CharacterCreationStep.traits] = isComplete;
    _updateState();
  }

  /// Select primary weapon
  void selectPrimaryWeapon(Weapon? weapon) {
    _character.primaryWeapon = weapon;

    // If selecting a two-handed weapon, clear secondary
    if (weapon?.burden == WeaponBurden.twoHanded) {
      _character.secondaryWeapon = null;
    }

    _updateEquipmentInventory();
  }

  /// Select secondary weapon
  void selectSecondaryWeapon(Weapon? weapon) {
    _character.secondaryWeapon = weapon;
    _updateEquipmentInventory();
  }

  /// Select armor
  void selectArmor(Armor? armor) {
    _character.equippedArmor = armor;

    if (armor != null) {
      _character.maxArmor = armor.baseScore;
      _character.majorDamageThreshold = armor.majorDamageThreshold + 1;
      _character.severeDamageThreshold = armor.severeDamageThreshold + 1;
    }

    _updateEquipmentInventory();
  }

  /// Select an option from an equipment option group
  void selectOptionGroupItem(String optionGroupId, String? itemName) {
    if (itemName != null) {
      optionGroupSelections[optionGroupId] = itemName;
    } else {
      optionGroupSelections.remove(optionGroupId);
    }
    _updateEquipmentInventory();
  }

  /// Select a class-specific item
  void selectClassItem(String? itemName) {
    selectedClassItem = itemName;
    _updateEquipmentInventory();
  }

  /// Clear all equipment selections (used when class changes)
  void clearEquipmentSelections() {
    _character.primaryWeapon = null;
    _character.secondaryWeapon = null;
    _character.equippedArmor = null;
    _character.inventory.clear();
    optionGroupSelections.clear();
    selectedClassItem = null;

    _stepCompleted[CharacterCreationStep.equipment] = false;
    _updateState();
  }

  /// Update equipment selections (replaces existing equipment items)
  void setEquipmentSelections(List<Item> equipmentItems) {
    _character.inventory.clear();
    _character.inventory.addAll(equipmentItems);

    _stepCompleted[CharacterCreationStep.equipment] = equipmentItems.isNotEmpty;
    _updateState();
  }

  /// Internal method to rebuild inventory from current equipment selections
  /// TODO: sort out magic ID generation
  void _updateEquipmentInventory() {
    final items = <Item>[];

    // Add automatic starting items from game data
    final automaticItems = gameDataService.startingItems;
    for (final itemName in automaticItems) {
      items.add(Item(
        id: 'auto_${itemName.toLowerCase().replaceAll(' ', '_')}',
        name: itemName,
        quantity: 1,
      ));
    }

    // Add selected items from option groups
    final optionGroups = gameDataService.startingOptionGroups;
    for (final entry in optionGroupSelections.entries) {
      final optionGroupId = entry.key;
      final selectedItemName = entry.value;

      final optionGroup =
          optionGroups.firstWhere((og) => og.id == optionGroupId);
      final selectedOption =
          optionGroup.options.firstWhere((o) => o.item == selectedItemName);

      items.add(Item(
        id: '${optionGroupId}_${selectedItemName.toLowerCase().replaceAll(' ', '_')}',
        name: selectedItemName,
        description: selectedOption.description,
        quantity: 1,
      ));
    }

    // Add selected class item
    if (selectedClassItem != null) {
      items.add(Item(
        id: 'class_item_${selectedClassItem!.toLowerCase().replaceAll(' ', '_')}',
        name: selectedClassItem!,
        description: 'Class-specific item',
        quantity: 1,
      ));
    }

    // Update character's inventory and gold
    _character.inventory.clear();
    _character.inventory.addAll(items);

    final startingGold = gameDataService.startingGold;
    if (startingGold != null) {
      _character.gold = startingGold;
    }

    // Mark step as completed if we have at least armor or a weapon selected
    _stepCompleted[CharacterCreationStep.equipment] =
        _character.primaryWeapon != null || _character.equippedArmor != null;

    _updateState();
  }

  /// Set the character's background
  void setBackground({
    Map<String, String>? questionnaireAnswers,
    String? generalBackground,
  }) {
    if (questionnaireAnswers != null) {
      _character.backgroundQuestionnaireAnswers =
          Map.from(questionnaireAnswers);
    }

    _character.background = generalBackground?.trim().isNotEmpty == true
        ? generalBackground!.trim()
        : null;

    _stepCompleted[CharacterCreationStep.background] = true;

    _updateState();
  }

  /// Skip the background step. Even though it's optional we don't want
  /// to prematurely mark the step as completed before user has visited it
  void skipBackground() {
    _stepCompleted[CharacterCreationStep.background] = true;
    _updateState();
  }

  /// Add experiences
  void addExperiences(List<String> experienceNames) {
    _character.experiences =
        experienceNames.map((name) => Experience(name: name)).toList();
    _stepCompleted[CharacterCreationStep.experiences] = true;
    _updateState();
  }

  /// Skip the experiences step. Even though it's optional we don't want
  /// to prematurely mark the step as completed before user has visited it
  void skipExperiences() {
    _stepCompleted[CharacterCreationStep.experiences] = true;
    _updateState();
  }

  /// Add selected domain abilities (replaces existing abilities)
  void setDomainAbilities(List<DomainAbility> abilities) {
    _character.domainAbilities.clear();
    _character.domainAbilities.addAll(abilities);
    _stepCompleted[CharacterCreationStep.domainCards] = abilities.length == 2;
    _updateState();
  }

  /// Set personal details
  void setPersonalDetails({
    required String name,
    String? pronouns,
    String? description,
    List<String>? connections,
  }) {
    _character.name = name;
    _character.pronouns = pronouns;
    _character.description = description;

    if (connections != null) {
      _character.connections = connections;
    }

    _stepCompleted[CharacterCreationStep.personalDetails] = name.isNotEmpty;
    _updateState();
  }
}
