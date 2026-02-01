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

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heartcraft/models/character.dart';
import 'package:heartcraft/models/class.dart';
import 'package:heartcraft/models/trait.dart';
import 'package:heartcraft/models/advancements.dart';
import 'package:heartcraft/models/gold.dart';
import 'package:heartcraft/services/game_data_service.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Character XML ser/deser', () {
    late GameDataService gameDataService;
    late String testCompendiumXml;

    setUpAll(() async {
      // Load demo compendium XML from assets
      testCompendiumXml = await rootBundle
          .loadString('assets/data/app.heartcraft.homebrew.demo.xml');

      gameDataService = GameDataService();
      gameDataService.loadFromXmlStrings([testCompendiumXml]);
    });

    test('ser/deser round-trip: load(save(character)) == character', () {
      // 1. Create test character
      final originalCharacter = Character(
        id: Uuid().v4().toString(),
        name: 'Cecil Pebblepot',
        pronouns: 'he/him',
        description: 'From Waterdeep',
        ancestry: gameDataService.ancestries
            .firstWhere((a) => a.id == 'app.heartcraft.homebrew.demo.human'),
        community: gameDataService.communities.firstWhere(
            (c) => c.id == 'app.heartcraft.homebrew.demo.farmborne'),
        characterClass: gameDataService.characterClasses
            .firstWhere((c) => c.id == 'app.heartcraft.homebrew.demo.priest'),
        subclass: gameDataService
            .subclasses['app.heartcraft.homebrew.demo.priest']
            ?.firstWhere(
                (sc) => sc.id == 'app.heartcraft.homebrew.demo.pilgrim'),
        domains: gameDataService.domains
            .where((d) =>
                d.id == 'app.heartcraft.homebrew.demo.spirit' ||
                d.id == 'app.heartcraft.homebrew.demo.duty')
            .toList(),
        traits: {
          Trait.agility: 0,
          Trait.strength: 1,
          Trait.finesse: -1,
          Trait.instinct: 2,
          Trait.presence: 1,
          Trait.knowledge: 0,
        },
        evasion: 11,
        proficiency: 2,
        majorDamageThreshold: 7,
        severeDamageThreshold: 15,
        maxHitPoints: 6,
        currentHitPoints: 1,
        maxArmor: 4,
        currentArmor: 2,
        maxHope: 5,
        currentHope: 3,
        maxStress: 6,
        currentStress: 0,
        level: 1,
        subclassTier: SubclassTier.foundation,
        advancements: Advancements(),
        background: 'Former soldier turned priest',
        backgroundQuestionnaireAnswers: {
          'priest_bq_0': 'I found faith after witnessing a miracle',
          'priest_bq_1': 'My deity is the god of light',
        },
        experiences: [],
        connections: [
          'Jeremy - Saved life',
          'Ted - Rival priest',
        ],
        domainAbilities: gameDataService.domainAbilities
            .where((a) =>
                a.id == 'app.heartcraft.homebrew.demo.p1' ||
                a.id == 'app.heartcraft.homebrew.demo.p2')
            .toList(),
        inventory: [],
        primaryWeapon: gameDataService.primaryWeapons.firstWhere(
            (w) => w.id == 'app.heartcraft.homebrew.demo.broadsword'),
        equippedArmor: gameDataService.armor.firstWhere(
            (a) => a.id == 'app.heartcraft.homebrew.demo.padded_armor'),
        notes: 'Test character for serialization',
        gold: Gold(handfuls: 5, bags: 2, chests: 1, coins: 7),
        customWeapons: [],
        customArmor: [],
      );

      // 2. Serialise to XML
      final xmlString = originalCharacter.toXml();
      expect(xmlString, isNotEmpty);

      // 3. Deserialise from XML
      final loadedCharacter = Character.fromXml(xmlString, gameDataService);

      // 4. Verify equality
      expect(loadedCharacter.id, equals(originalCharacter.id));
      expect(loadedCharacter.name, equals(originalCharacter.name));
      expect(loadedCharacter.pronouns, equals(originalCharacter.pronouns));
      expect(
          loadedCharacter.description, equals(originalCharacter.description));

      // Ancestry
      expect(
          loadedCharacter.ancestry?.id, equals(originalCharacter.ancestry?.id));
      expect(loadedCharacter.ancestry?.name,
          equals(originalCharacter.ancestry?.name));

      // Community
      expect(loadedCharacter.community?.id,
          equals(originalCharacter.community?.id));
      expect(loadedCharacter.community?.name,
          equals(originalCharacter.community?.name));

      // Class and Subclass
      expect(loadedCharacter.characterClass?.id,
          equals(originalCharacter.characterClass?.id));
      expect(loadedCharacter.characterClass?.name,
          equals(originalCharacter.characterClass?.name));
      expect(
          loadedCharacter.subclass?.id, equals(originalCharacter.subclass?.id));
      expect(loadedCharacter.subclass?.name,
          equals(originalCharacter.subclass?.name));

      // Domains
      expect(loadedCharacter.domains.length,
          equals(originalCharacter.domains.length));
      for (var i = 0; i < originalCharacter.domains.length; i++) {
        expect(loadedCharacter.domains[i].id,
            equals(originalCharacter.domains[i].id));
      }

      // Traits
      expect(loadedCharacter.traits[Trait.agility],
          equals(originalCharacter.traits[Trait.agility]));
      expect(loadedCharacter.traits[Trait.strength],
          equals(originalCharacter.traits[Trait.strength]));
      expect(loadedCharacter.traits[Trait.finesse],
          equals(originalCharacter.traits[Trait.finesse]));
      expect(loadedCharacter.traits[Trait.instinct],
          equals(originalCharacter.traits[Trait.instinct]));
      expect(loadedCharacter.traits[Trait.presence],
          equals(originalCharacter.traits[Trait.presence]));
      expect(loadedCharacter.traits[Trait.knowledge],
          equals(originalCharacter.traits[Trait.knowledge]));

      // Stats
      expect(loadedCharacter.evasion, equals(originalCharacter.evasion));
      expect(
          loadedCharacter.proficiency, equals(originalCharacter.proficiency));
      expect(loadedCharacter.majorDamageThreshold,
          equals(originalCharacter.majorDamageThreshold));
      expect(loadedCharacter.severeDamageThreshold,
          equals(originalCharacter.severeDamageThreshold));
      expect(
          loadedCharacter.maxHitPoints, equals(originalCharacter.maxHitPoints));
      expect(loadedCharacter.currentHitPoints,
          equals(originalCharacter.currentHitPoints));
      expect(loadedCharacter.maxArmor, equals(originalCharacter.maxArmor));
      expect(
          loadedCharacter.currentArmor, equals(originalCharacter.currentArmor));
      expect(loadedCharacter.maxHope, equals(originalCharacter.maxHope));
      expect(
          loadedCharacter.currentHope, equals(originalCharacter.currentHope));
      expect(loadedCharacter.maxStress, equals(originalCharacter.maxStress));
      expect(loadedCharacter.currentStress,
          equals(originalCharacter.currentStress));
      expect(loadedCharacter.level, equals(originalCharacter.level));

      // Background
      expect(loadedCharacter.background, equals(originalCharacter.background));
      expect(loadedCharacter.backgroundQuestionnaireAnswers.length,
          equals(originalCharacter.backgroundQuestionnaireAnswers.length));

      // Connections
      expect(loadedCharacter.connections.length,
          equals(originalCharacter.connections.length));
      for (var i = 0; i < originalCharacter.connections.length; i++) {
        expect(loadedCharacter.connections[i],
            equals(originalCharacter.connections[i]));
      }

      // Domain abilities
      expect(loadedCharacter.domainAbilities.length,
          equals(originalCharacter.domainAbilities.length));
      for (var i = 0; i < originalCharacter.domainAbilities.length; i++) {
        expect(loadedCharacter.domainAbilities[i].id,
            equals(originalCharacter.domainAbilities[i].id));
      }

      // Equipment
      expect(loadedCharacter.primaryWeapon?.id,
          equals(originalCharacter.primaryWeapon?.id));
      expect(loadedCharacter.equippedArmor?.id,
          equals(originalCharacter.equippedArmor?.id));

      // Gold
      expect(loadedCharacter.gold.handfuls,
          equals(originalCharacter.gold.handfuls));
      expect(loadedCharacter.gold.bags, equals(originalCharacter.gold.bags));
      expect(
          loadedCharacter.gold.chests, equals(originalCharacter.gold.chests));
      expect(loadedCharacter.gold.coins, equals(originalCharacter.gold.coins));

      // Notes
      expect(loadedCharacter.notes, equals(originalCharacter.notes));
    });
  });
}
