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

import 'package:heartcraft/models/feature.dart';
import 'package:heartcraft/models/companion.dart';
import 'package:heartcraft/models/trait.dart';

/// Represents a character class
class CharacterClass {
  String id;
  String name;
  String? description;
  int startingEvasion;
  int startingHitPoints;
  List<String> domains;

  // Includes Hope Feature for now
  List<Feature> classFeatures;

  CharacterClass({
    required this.id,
    required this.name,
    required this.description,
    required this.startingEvasion,
    required this.startingHitPoints,
    required this.domains,
    required this.classFeatures,
  });
}

enum SubclassTier { foundation, specialization, mastery }

class SubClass {
  CharacterClass characterClass;
  String id;
  String name;
  String? description;
  Trait? spellcastTrait;
  CompanionTemplate? companion; // Optional companion for this subclass

  List<Feature> foundationFeatures;
  List<Feature> specializationFeatures;
  List<Feature> masteryFeatures;

  SubClass({
    required this.characterClass,
    required this.id,
    required this.name,
    this.description,
    this.spellcastTrait,
    this.companion,
    required this.foundationFeatures,
    required this.specializationFeatures,
    required this.masteryFeatures,
  });
}
