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

import 'package:flutter/foundation.dart';
import '../models/character.dart';
import '../models/advancements.dart';
import '../models/trait.dart';
import '../models/experience.dart';
import '../models/domain.dart';

/// Manages character level-up state and validation
/// Tracks all auto and manual selections for level up including:
/// - Auto increases to proficiency and thresholds
/// - Level achievement domain card (i.e. for each new level)
/// - New experiences (for levels 2, 5, 8)
/// - Advancement choices (HP, stress, evasion, traits, experiences, domain cards)
/// - Trait marking
/// - TODO: Tier 3+4 advancements, multi-classing
class CharacterAdvancementViewModel extends ChangeNotifier {
  Character? _character;

  // Level up selections
  String? _newExperienceName;
  DomainAbility? _levelAchievementDomainCard;
  DomainAbility? _additionalDomainCard;
  Set<String> _selectedExperiencesForBonus = {};

  // Tier 2 draft (character's existing + this level up)
  late Tier2Advancements _tier2;
  late List<Trait> _markedTraits;

  Character? get character => _character;
  String? get newExperienceName => _newExperienceName;
  DomainAbility? get levelAchievementDomainCard => _levelAchievementDomainCard;
  DomainAbility? get additionalDomainCard => _additionalDomainCard;
  Set<String> get selectedExperiencesForBonus => _selectedExperiencesForBonus;
  Tier2Advancements get tier2 => _tier2;
  List<Trait> get markedTraits => _markedTraits;

  int get newLevel => (_character?.level ?? 0) + 1;
  bool get isValid => _validateLevelUp();

  /// Initialize ViewModel with character
  void initialize(Character character) {
    _character = character;
    _tier2 = character.advancements.tier2.copy();
    _markedTraits = List<Trait>.from(character.advancements.markedTraits);
    _newExperienceName = null;
    _levelAchievementDomainCard = null;
    _additionalDomainCard = null;
    _selectedExperiencesForBonus = {};
    notifyListeners();
  }

  /// Calculate remaining tier 2 selections for this level
  int getRemainingTier2Selections() {
    if (_character == null) return 0;
    final selectionsUsedThisLevel =
        _tier2.totalSelections - _character!.advancements.tier2.totalSelections;
    return 2 - selectionsUsedThisLevel; // 2 selections per level
  }

  // Setters with validation
  void setNewExperience(String? name) {
    _newExperienceName = name;
    notifyListeners();
  }

  void setLevelAchievementDomainCard(DomainAbility? card) {
    _levelAchievementDomainCard = card;
    notifyListeners();
  }

  void setAdditionalDomainCard(DomainAbility? card) {
    _additionalDomainCard = card;
    notifyListeners();
  }

  void toggleExperienceForBonus(String expName) {
    if (_selectedExperiencesForBonus.contains(expName)) {
      _selectedExperiencesForBonus.remove(expName);
    } else if (_selectedExperiencesForBonus.length < 2) {
      _selectedExperiencesForBonus.add(expName);
    }
    notifyListeners();
  }

  void toggleTrait(Trait trait) {
    if (_character == null) return;

    final wasAlreadyMarked =
        _character!.advancements.markedTraits.contains(trait);
    if (wasAlreadyMarked) return;

    final isNewlyMarked = _markedTraits.contains(trait) && !wasAlreadyMarked;
    final traitsIncreasedThisLevel =
        _tier2.increaseTraits - _character!.advancements.tier2.increaseTraits;
    final newlyMarkedCount =
        _markedTraits.length - _character!.advancements.markedTraits.length;
    final canMark =
        !wasAlreadyMarked && newlyMarkedCount < (traitsIncreasedThisLevel * 2);

    if (isNewlyMarked) {
      _markedTraits.remove(trait);
    } else if (canMark) {
      _markedTraits.add(trait);
    }

    notifyListeners();
  }

  void incrementHitPoints() {
    if (_tier2.increaseHitpoints < 2 && getRemainingTier2Selections() > 0) {
      _tier2.increaseHitpoints++;
      notifyListeners();
    }
  }

  void decrementHitPoints() {
    if (_tier2.increaseHitpoints > 0) {
      _tier2.increaseHitpoints--;
      notifyListeners();
    }
  }

  void incrementStress() {
    if (_tier2.increaseStress < 2 && getRemainingTier2Selections() > 0) {
      _tier2.increaseStress++;
      notifyListeners();
    }
  }

  void decrementStress() {
    if (_tier2.increaseStress > 0) {
      _tier2.increaseStress--;
      notifyListeners();
    }
  }

  void toggleEvasion() {
    if (!_tier2.increaseEvasion && getRemainingTier2Selections() > 0) {
      _tier2.increaseEvasion = true;
      notifyListeners();
    } else if (_tier2.increaseEvasion) {
      _tier2.increaseEvasion = false;
      notifyListeners();
    }
  }

  void incrementTraits() {
    if (_tier2.increaseTraits < 3 && getRemainingTier2Selections() > 0) {
      _tier2.increaseTraits++;
      notifyListeners();
    }
  }

  void decrementTraits() {
    if (_tier2.increaseTraits > 0) {
      _tier2.increaseTraits--;
      notifyListeners();
    }
  }

  void toggleIncreaseExperiences() {
    if (!_tier2.increaseExperiences && getRemainingTier2Selections() > 0) {
      _tier2.increaseExperiences = true;
      notifyListeners();
    } else if (_tier2.increaseExperiences) {
      _tier2.increaseExperiences = false;
      _selectedExperiencesForBonus.clear();
      notifyListeners();
    }
  }

  void toggleAdditionalDomainCard() {
    if (!_tier2.additionalDomainCard && getRemainingTier2Selections() > 0) {
      _tier2.additionalDomainCard = true;
      notifyListeners();
    } else if (_tier2.additionalDomainCard) {
      _tier2.additionalDomainCard = false;
      _additionalDomainCard = null;
      notifyListeners();
    }
  }

  /// Validate all level-up requirements
  bool _validateLevelUp() {
    if (_character == null) return false;

    // 1. Level Achievement Domain Card must be selected
    if (_levelAchievementDomainCard == null) return false;

    // 2. New Experience must be chosen for levels 2, 5, 8
    if (newLevel == 2 || newLevel == 5 || newLevel == 8) {
      if (_newExperienceName == null || _newExperienceName!.isEmpty) {
        return false;
      }
    }

    // 3. Tier 2 validations (levels >= 2)
    if (newLevel >= 2) {
      // Must use exactly 2 selections
      if (getRemainingTier2Selections() != 0) return false;

      // Trait marking validation - must mark 2x the number of trait increases
      final traitIncreaseChoicesMadeThisLevel =
          _tier2.increaseTraits - _character!.advancements.tier2.increaseTraits;
      final newlyMarkedTraits =
          _markedTraits.length - _character!.advancements.markedTraits.length;
      if (newlyMarkedTraits != traitIncreaseChoicesMadeThisLevel * 2) {
        return false;
      }

      // Experience bonus validation - must select 2 experiences for +1 bonus
      if (_tier2.increaseExperiences &&
          !_character!.advancements.tier2.increaseExperiences) {
        if (_selectedExperiencesForBonus.length != 2) return false;
      }

      // Additional domain card validation
      if (_tier2.additionalDomainCard &&
          !_character!.advancements.tier2.additionalDomainCard) {
        if (_additionalDomainCard == null) return false;
      }
    }

    return true;
  }

  /// Perform the level up - returns updated character
  Character performLevelUp() {
    if (!isValid || _character == null) {
      throw StateError('Cannot level up: validation failed');
    }

    // Apply tier 2 advancements
    _character!.advancements.tier2 = _tier2;

    // Add level achievement domain card
    if (_levelAchievementDomainCard != null) {
      _character!.addDomainAbility(_levelAchievementDomainCard!);
    }

    // Add new experience
    if (_newExperienceName != null) {
      _character!.experiences.add(
        Experience(name: _newExperienceName!, modifier: 2),
      );
    }

    // Apply experience bonuses
    for (var expName in _selectedExperiencesForBonus) {
      final exp = _character!.experiences.firstWhere((e) => e.name == expName);
      exp.modifier++;
    }

    // Add additional domain card
    if (_additionalDomainCard != null) {
      _character!.addDomainAbility(_additionalDomainCard!);
    }

    // Apply trait increases
    for (var trait in _markedTraits) {
      if (!_character!.advancements.markedTraits.contains(trait)) {
        _character!.traits[trait] = (_character!.traits[trait] ?? 0) + 1;
      }
    }
    _character!.advancements.markedTraits = _markedTraits;

    // Level up
    _character!.level++;
    _character!.majorDamageThreshold++;
    _character!.severeDamageThreshold++;

    // Proficiency increase
    if (_character!.level == 2 ||
        _character!.level == 5 ||
        _character!.level == 8) {
      _character!.proficiency++;
    }

    return _character!;
  }
}
