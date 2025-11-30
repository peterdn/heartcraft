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

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:heartcraft/models/experience.dart';
import 'package:heartcraft/models/trait.dart';
import 'package:share_plus/share_plus.dart';
import '../models/character.dart';
import '../models/equipment.dart';
import '../models/gold.dart';
import '../services/character_data_service.dart';
import '../services/portrait_service.dart';

/// Provider for managing the currently active character's state
class CharacterProvider extends ChangeNotifier {
  final CharacterDataService dataService;
  final PortraitService portraitService;

  CharacterProvider({
    required this.dataService,
    required this.portraitService,
  });

  static const maxCharacterLevel = 4;

  Character? _currentCharacter;
  Character? get currentCharacter => _currentCharacter;

  // HACK: Counter to force portrait refresh
  int _portraitRefreshKey = 0;
  int get portraitRefreshKey => _portraitRefreshKey;

  /// Helper method to update character state with save and notify
  void _updateField(void Function() update) {
    if (_currentCharacter == null) return;
    update();
    notifyListeners();
    saveCharacter();
  }

  /// Helper method to update companion state with save and notify
  void _updateCompanionField(void Function() update) {
    if (_currentCharacter?.companion == null) return;
    update();
    notifyListeners();
    saveCharacter();
  }

  /// Load a character by ID
  Future<void> loadCharacter(String id) async {
    _currentCharacter = await dataService.loadCharacter(id);
    notifyListeners();
  }

  /// Create a new character
  void createNewCharacter() {
    _currentCharacter = Character.empty();
    notifyListeners();
  }

  /// Set the current character directly
  void setCurrentCharacter(Character character) {
    _currentCharacter = character;
    notifyListeners();
  }

  /// Save the current character
  /// TODO: sort out async handling here: should this be awaited by callers?
  /// Might be good to serialise writes and debounce...
  Future<void> saveCharacter() async {
    if (_currentCharacter == null) {
      throw StateError('No current character to save');
    }
    await dataService.saveCharacter(_currentCharacter!);
    notifyListeners();
  }

  /// Share/export current character as a zip archive (so portraits are included)
  /// If on desktop, prompts user to select save location
  /// If on mobile, exports to temporary directory and opens share dialog
  void shareCharacter(BuildContext context) async {
    if (_currentCharacter == null) return;

    try {
      final isDesktop =
          Platform.isWindows || Platform.isMacOS || Platform.isLinux;

      if (isDesktop) {
        final sanitizedName =
            _currentCharacter!.name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        final defaultFileName = '$sanitizedName.zip';

        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Export Character',
          fileName: defaultFileName,
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );

        if (outputPath != null) {
          await dataService.exportCharacter(_currentCharacter!,
              outputPath: outputPath);
        }
      } else {
        final archivePath =
            await dataService.exportCharacter(_currentCharacter!);

        final params = ShareParams(
          files: [XFile(archivePath)],
          subject: 'Character: ${_currentCharacter!.name}',
        );
        await SharePlus.instance.share(params);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export character: $e')),
        );
      }
    }
  }

  /// Update the character's name
  void updateName(String name) {
    _updateField(() => _currentCharacter!.name = name);
  }

  /// Update the character's pronouns
  void updatePronouns(String? pronouns) {
    _updateField(() => _currentCharacter!.pronouns = pronouns);
  }

  /// Update the character's description
  void updateDescription(String? description) {
    _updateField(() => _currentCharacter!.description = description);
  }

  /// Update the character's portrait from gallery
  /// Returns true if a portrait was selected and updated
  Future<bool> updatePortraitFromGallery(BuildContext context) async {
    if (_currentCharacter == null) {
      throw StateError('No character loaded');
    }

    final portraitPath = await portraitService.pickAndCropPortraitFromGallery(
      _currentCharacter!.id,
      context,
    );

    if (portraitPath != null) {
      // delete old portrait if it was not overwritten
      if (_currentCharacter!.portraitPath != null &&
          _currentCharacter!.portraitPath != portraitPath) {
        await portraitService.deletePortrait(_currentCharacter!.portraitPath);
      }
      _currentCharacter!.portraitPath = portraitPath;
      _portraitRefreshKey++; // Force portrait refresh
      notifyListeners();
      await saveCharacter();
      return true;
    }
    return false;
  }

  /// Update the character's portrait from camera
  /// Returns true if a photo was taken and updated
  Future<bool> takePortraitPhoto(BuildContext context) async {
    if (_currentCharacter == null) {
      throw StateError('No character loaded');
    }

    final portraitPath = await portraitService.takeAndCropPortraitFromCamera(
      _currentCharacter!.id,
      context,
    );

    if (portraitPath != null) {
      // delete old portrait if it was not overwritten
      if (_currentCharacter!.portraitPath != null &&
          _currentCharacter!.portraitPath != portraitPath) {
        await portraitService.deletePortrait(_currentCharacter!.portraitPath);
      }
      _currentCharacter!.portraitPath = portraitPath;
      _portraitRefreshKey++; // Force portrait refresh
      notifyListeners();
      await saveCharacter();
      return true;
    }
    return false;
  }

  /// Remove the character's portrait
  Future<void> removePortrait() async {
    if (_currentCharacter == null) {
      throw StateError('No character loaded');
    }

    if (_currentCharacter!.portraitPath != null) {
      await portraitService.deletePortrait(_currentCharacter!.portraitPath);
      _currentCharacter!.portraitPath = null;
      notifyListeners();
      await saveCharacter();
    }
  }

  /// Get the full path to the character's portrait
  Future<String?> getPortraitPath() async {
    if (_currentCharacter?.portraitPath == null) return null;
    return await portraitService
        .getPortraitPath(_currentCharacter!.portraitPath);
  }

  /// Update a trait value
  void updateTrait(Trait trait, int value) {
    _updateField(() => _currentCharacter!.traits[trait] = value);
  }

  /// Add an experience
  void addExperience(String experienceName, {int modifier = 2}) {
    _updateField(() => _currentCharacter!.experiences
        .add(Experience(name: experienceName, modifier: modifier)));
  }

  /// Remove an experience
  void removeExperience(String experienceName) {
    _updateField(() => _currentCharacter!.experiences
        .removeWhere((exp) => exp.name == experienceName));
  }

  /// Update an experience modifier
  void updateExperienceModifier(String experienceName, int modifier) {
    _updateField(() {
      final experience = _currentCharacter!.experiences
          .firstWhere((exp) => exp.name == experienceName);
      experience.modifier = modifier;
    });
  }

  /// Add a connection
  void addConnection(String connection) {
    _updateField(() => _currentCharacter!.connections.add(connection));
  }

  /// Remove a connection
  void removeConnection(String connection) {
    _updateField(() => _currentCharacter!.connections.remove(connection));
  }

  /// Add an item to inventory
  void addItem(Item item) {
    if (_currentCharacter == null) return;

    final existingIndex =
        _currentCharacter!.inventory.indexWhere((i) => i.id == item.id);

    if (existingIndex >= 0) {
      // Update quantity if item already exists in inventory
      _currentCharacter!.inventory[existingIndex].quantity += item.quantity;
    } else {
      _currentCharacter!.inventory.add(item);
    }

    notifyListeners();
    saveCharacter();
  }

  /// Update item quantity
  void updateItemQuantity(String itemId, int quantity) {
    if (_currentCharacter == null) return;

    final index =
        _currentCharacter!.inventory.indexWhere((i) => i.id == itemId);
    if (index >= 0) {
      if (quantity <= 0) {
        _currentCharacter!.inventory.removeAt(index);
      } else {
        _currentCharacter!.inventory[index].quantity = quantity;
      }
      notifyListeners();
      saveCharacter();
    }
  }

  /// Remove an item from inventory
  void removeItem(String itemId) {
    if (_currentCharacter == null) return;

    _currentCharacter!.inventory.removeWhere((i) => i.id == itemId);
    notifyListeners();
    saveCharacter();
  }

  /// Update character's background
  void updateBackground(String? background) {
    _updateField(() => _currentCharacter!.background = background);
  }

  /// Update character's background questionnaire answers
  void updateBackgroundQuestionnaireAnswers(Map<String, String> answers) {
    _updateField(() =>
        _currentCharacter!.backgroundQuestionnaireAnswers = Map.from(answers));
  }

  /// Update a single background question answer
  void updateBackgroundQuestionAnswer(String questionId, String? answer) {
    _updateField(() {
      if (answer == null || answer.isEmpty) {
        _currentCharacter!.backgroundQuestionnaireAnswers.remove(questionId);
      } else {
        _currentCharacter!.backgroundQuestionnaireAnswers[questionId] = answer;
      }
    });
  }

  /// Update character's notes
  void updateNotes(String notes) {
    _updateField(() => _currentCharacter!.notes = notes);
  }

  /// Update current HP, clamping between 0 and max HP
  void updateCurrentHitPoints(int hitPoints) {
    _updateField(() {
      _currentCharacter!.currentHitPoints =
          hitPoints.clamp(0, _currentCharacter!.maxHitPoints);
    });
  }

  /// Add gold to the current character (merge and normalize)
  void addGold(Gold goldToAdd) {
    _updateField(() => _currentCharacter!.gold.add(goldToAdd));
  }

  /// Set the character's gold directly
  void setGold(Gold gold) {
    _updateField(() => _currentCharacter!.gold = gold);
  }

  /// Attempt to spend the given gold amount. Returns true if successful.
  bool spendGold(Gold cost) {
    if (_currentCharacter == null) return false;

    final current = _currentCharacter!.gold;
    if (!current.canAfford(cost)) return false;

    final success = current.subtract(cost);
    if (success) {
      notifyListeners();
      saveCharacter();
      return true;
    }

    return false;
  }

  /// Update max HP
  void updateMaxHitPoints(int hitPoints) {
    _updateField(() {
      _currentCharacter!.maxHitPoints = hitPoints > 0 ? hitPoints : 1;
      // Ensure current HP doesn't exceed max
      if (_currentCharacter!.currentHitPoints >
          _currentCharacter!.maxHitPoints) {
        _currentCharacter!.currentHitPoints = _currentCharacter!.maxHitPoints;
      }
    });
  }

  /// Update max armor
  void updateMaxArmor(int armor) {
    _updateField(() {
      _currentCharacter!.maxArmor = armor >= 0 ? armor : 1;
      // Ensure current armor doesn't exceed max
      if (_currentCharacter!.currentArmor > _currentCharacter!.maxArmor) {
        _currentCharacter!.currentArmor = _currentCharacter!.maxArmor;
      }
    });
  }

  /// Update max stress
  void updateMaxStress(int stress) {
    _updateField(() {
      _currentCharacter!.maxStress = stress > 0 ? stress : 1;
      // Ensure current stress doesn't exceed max
      if (_currentCharacter!.currentStress > _currentCharacter!.maxStress) {
        _currentCharacter!.currentStress = _currentCharacter!.maxStress;
      }
    });
  }

  /// Update max hope
  void updateMaxHope(int hope) {
    _updateField(() {
      _currentCharacter!.maxHope = hope > 0 ? hope : 1;
      // Ensure current hope doesn't exceed max
      if (_currentCharacter!.currentHope > _currentCharacter!.maxHope) {
        _currentCharacter!.currentHope = _currentCharacter!.maxHope;
      }
    });
  }

  /// Update evasion
  void updateEvasion(int evasion) {
    _updateField(() => _currentCharacter!.evasion = evasion > 0 ? evasion : 0);
  }

  /// Update major damage threshold
  void updateMajorDamageThreshold(int threshold) {
    _updateField(() {
      _currentCharacter!.majorDamageThreshold =
          threshold >= 1 && threshold < _currentCharacter!.severeDamageThreshold
              ? threshold
              : _currentCharacter!.majorDamageThreshold;
    });
  }

  /// Update severe damage threshold
  void updateSevereDamageThreshold(int threshold) {
    _updateField(() {
      _currentCharacter!.severeDamageThreshold =
          threshold > _currentCharacter!.majorDamageThreshold
              ? threshold
              : _currentCharacter!.severeDamageThreshold;
    });
  }

  /// Update proficiency
  void updateProficiency(int proficiency) {
    _updateField(() =>
        _currentCharacter!.proficiency = proficiency > 0 ? proficiency : 1);
  }

  /// Update current armor
  void updateArmor(int armor) {
    _updateField(
        () => _currentCharacter!.currentArmor = armor >= 0 ? armor : 0);
  }

  /// Update current hope
  void updateHope(int hope) {
    _updateField(() => _currentCharacter!.currentHope =
        hope.clamp(0, _currentCharacter!.maxHope));
  }

  /// Update current stress
  void updateStress(int stress) {
    _updateField(() => _currentCharacter!.currentStress =
        stress.clamp(0, _currentCharacter!.maxStress));
  }

  /// Update primary weapon
  void updatePrimaryWeapon(Weapon? weapon) {
    _updateField(() {
      _currentCharacter!.primaryWeapon = weapon;
      // If selecting a two-handed weapon, clear secondary weapon
      if (weapon?.burden == WeaponBurden.twoHanded) {
        _currentCharacter!.secondaryWeapon = null;
      }
    });
  }

  /// Update secondary weapon
  void updateSecondaryWeapon(Weapon? weapon) {
    _updateField(() => _currentCharacter!.secondaryWeapon = weapon);
  }

  /// Update equipped armor
  void updateEquippedArmor(Armor? armor) {
    _updateField(() {
      _currentCharacter!.equippedArmor = armor;
      // Update max armor based on equipped armor
      if (armor != null) {
        _currentCharacter!.maxArmor = armor.baseScore;
        // Ensure current armor doesn't exceed max
        if (_currentCharacter!.currentArmor > _currentCharacter!.maxArmor) {
          _currentCharacter!.currentArmor = _currentCharacter!.maxArmor;
        }
      }
    });
  }

  // Companion methods

  /// Update companion name
  void updateCompanionName(String name) {
    _updateCompanionField(() => _currentCharacter!.companion!.name = name);
  }

  /// Update companion animal type
  void updateCompanionSubType(String subType) {
    _updateCompanionField(
        () => _currentCharacter!.companion!.subType = subType);
  }

  /// Update companion stress
  void updateCompanionStress(int stress) {
    if (_currentCharacter?.companion == null) return;
    _currentCharacter!.companion!.currentStress =
        stress.clamp(0, _currentCharacter!.companion!.maxStress);
    notifyListeners();
    saveCharacter();
  }

  /// Update companion max stress
  void updateCompanionMaxStress(int maxStress) {
    _updateCompanionField(() {
      _currentCharacter!.companion!.maxStress = maxStress > 0 ? maxStress : 1;
      // Ensure current stress doesn't exceed max
      if (_currentCharacter!.companion!.currentStress >
          _currentCharacter!.companion!.maxStress) {
        _currentCharacter!.companion!.currentStress =
            _currentCharacter!.companion!.maxStress;
      }
    });
  }

  /// Update companion evasion
  void updateCompanionEvasion(int evasion) {
    _updateCompanionField(() =>
        _currentCharacter!.companion!.evasion = evasion > 0 ? evasion : 1);
  }

  /// Update companion standard attack
  void updateCompanionStandardAttack(String attack) {
    _updateCompanionField(
        () => _currentCharacter!.companion!.standardAttack = attack);
  }

  /// Update companion range
  void updateCompanionRange(String range) {
    _updateCompanionField(() => _currentCharacter!.companion!.range = range);
  }

  /// Update companion damage die
  void updateCompanionDamageDie(String damageDie) {
    _updateCompanionField(
        () => _currentCharacter!.companion!.damageDie = damageDie);
  }
}
