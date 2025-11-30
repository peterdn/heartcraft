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

import 'package:heartcraft/models/experience.dart';

/// Template for a companion, as defined in a compendium
class CompanionTemplate {
  final String id;
  final String type;
  final String name;
  final String description;
  final int startingEvasion;
  final List<String> availableExperiences;

  CompanionTemplate({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.startingEvasion,
    required this.availableExperiences,
  });

  String get typeTitle {
    return type[0].toUpperCase() + type.substring(1);
  }
}

/// A specific companion instance owned by a character
class Companion {
  final CompanionTemplate companionTemplate;

  String? name;
  String? subType;
  List<Experience> experiences;

  int evasion;
  int maxStress;
  int currentStress;

  // Attack & damage
  // TODO: make enum or class for these
  String standardAttack;
  String range;
  String damageDie;

  // TODO: define starting maxStress, standardAttack,
  // range, damageDie in compendium
  Companion({
    required this.companionTemplate,
    this.name,
    this.subType,
    List<Experience>? experiences,
    int? evasion,
    this.maxStress = 3,
    this.currentStress = 0,
    this.standardAttack = 'Claws',
    this.range = 'Melee',
    this.damageDie = 'd6',
  })  : experiences = experiences ?? [],
        evasion = evasion ?? companionTemplate.startingEvasion;
}
