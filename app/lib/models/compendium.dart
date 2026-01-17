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

import 'package:heartcraft/models/domain.dart';
import 'package:heartcraft/models/character.dart';
import 'package:heartcraft/models/class.dart';
import 'package:heartcraft/models/companion.dart';
import 'package:heartcraft/models/equipment.dart';
import 'package:heartcraft/models/gold.dart';
import 'package:heartcraft/models/ancestry.dart';
import 'package:heartcraft/models/community.dart';

class Compendium {
  String? id;
  int? version;
  String? name;
  String? description;
  String? author;
  String? url;
  String? license;
  String? licenseUrl;

  final List<CharacterClass> classes = [];
  final Map<String, List<SubClass>> subclasses = {};
  final List<Ancestry> ancestries = [];
  final List<Community> communities = [];
  final List<Domain> domains = [];
  final List<Weapon> primaryWeapons = [];
  final List<Weapon> secondaryWeapons = [];
  final List<Armor> armor = [];
  final Map<String, List<String>> classItems = {};
  final List<String> startingItems = [];
  Gold? startingGold;
  final List<OptionGroup> startingOptionGroups = [];
  final Map<String, Map<String, BackgroundQuestion>> backgroundQuestions = {};
  final List<Map<String, String>> experiences = [];
  final List<DomainAbility> domainAbilities = [];
  final Map<String, CompanionTemplate> companionTemplates = {};

  /// Returns a fully qualified ID for an entity in this compendium
  String fullyQualifiedId(String id) {
    return '${this.id}.$id';
  }

  String get displayName => name ?? id!;

  void merge(Compendium compendium) {
    classes.addAll(compendium.classes);

    compendium.subclasses.forEach((key, value) {
      if (subclasses.containsKey(key)) {
        subclasses[key]!.addAll(value);
      } else {
        subclasses[key] = value;
      }
    });

    ancestries.addAll(compendium.ancestries);
    communities.addAll(compendium.communities);
    domains.addAll(compendium.domains);
    primaryWeapons.addAll(compendium.primaryWeapons);
    secondaryWeapons.addAll(compendium.secondaryWeapons);
    armor.addAll(compendium.armor);
    experiences.addAll(compendium.experiences);
    domainAbilities.addAll(compendium.domainAbilities);

    compendium.classItems.forEach((key, value) {
      if (classItems.containsKey(key)) {
        classItems[key]!.addAll(value);
      } else {
        classItems[key] = value;
      }
    });

    // TODO: merging starting items is not straightforward.
    // Just append for now. Take starting gold from the last compendium
    startingItems.addAll(compendium.startingItems);
    startingOptionGroups.addAll(compendium.startingOptionGroups);
    startingGold ??= compendium.startingGold;

    compendium.backgroundQuestions.forEach((key, value) {
      if (backgroundQuestions.containsKey(key)) {
        backgroundQuestions[key]!.addAll(value);
      } else {
        backgroundQuestions[key] = value;
      }
    });

    compendium.companionTemplates.forEach((key, value) {
      companionTemplates[key] = value;
    });
  }
}
