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
import 'package:heartcraft/models/experience.dart';
import 'package:heartcraft/models/feature.dart';
import 'package:heartcraft/models/class.dart';
import 'package:heartcraft/models/equipment.dart';
import 'package:heartcraft/models/advancements.dart';
import 'package:heartcraft/models/ancestry.dart';
import 'package:heartcraft/models/community.dart';
import 'package:heartcraft/models/trait.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';
import 'gold.dart';
import 'companion.dart';
import '../services/game_data_service.dart';

class Character {
  String id;
  String name;
  String? pronouns;
  String? description;

  Ancestry? ancestry;
  Ancestry? secondAncestry; // For mixed ancestry - null if not mixed
  Community? community;
  CharacterClass? characterClass;
  SubClass? subclass;
  List<Domain> domains;

  Map<Trait, int> traits;

  int evasion;
  int proficiency;
  int majorDamageThreshold;
  int severeDamageThreshold;
  int maxHitPoints;
  int currentHitPoints;
  int maxArmor;
  int currentArmor;
  int maxHope;
  int currentHope;
  int maxStress;
  int currentStress;

  int level;
  SubclassTier subclassTier;
  Advancements advancements;

  String? background;
  Map<String, String>
      backgroundQuestionnaireAnswers; // Maps question ID -> answer
  List<Experience> experiences;
  List<String> connections;
  String notes;

  // Portrait image path (relative to character directory)
  String? portraitPath;

  // Domain cards
  List<DomainAbility> domainAbilities;

  // Companion (optional, for certain subclasses)
  Companion? companion;

  // Equipment and inventory
  // TODO: inventory weapons
  List<Item> inventory;
  Armor? equippedArmor;
  Weapon? primaryWeapon;
  Weapon? secondaryWeapon;
  Gold gold;

  // TODO: tidy up this huge mess of nullables and requireds...
  Character({
    required this.id,
    required this.name,
    this.pronouns,
    this.description,
    this.ancestry,
    this.secondAncestry,
    this.community,
    this.characterClass,
    this.subclass,
    required this.domains,
    required this.traits,
    required this.evasion,
    required this.proficiency,
    required this.majorDamageThreshold,
    required this.severeDamageThreshold,
    required this.maxHitPoints,
    required this.currentHitPoints,
    required this.maxArmor,
    required this.currentArmor,
    required this.maxHope,
    required this.currentHope,
    required this.maxStress,
    required this.currentStress,
    required this.subclassTier,
    required this.level,
    required this.advancements,
    this.background,
    required this.backgroundQuestionnaireAnswers,
    required this.experiences,
    required this.connections,
    this.portraitPath,
    required this.domainAbilities,
    this.companion,
    required this.inventory,
    this.equippedArmor,
    this.primaryWeapon,
    this.secondaryWeapon,
    required this.notes,
    required this.gold,
  });

  static String _generateCharacterId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Uuid().v4().substring(0, 8);
  }

  /// Create a new, empty character with default values
  factory Character.empty() {
    return Character(
      id: _generateCharacterId(),
      name: '',
      domains: [],
      traits: {},
      evasion: 0,
      proficiency: 1,
      majorDamageThreshold: 1,
      severeDamageThreshold: 2,
      maxHitPoints: 10,
      currentHitPoints: 0,
      maxArmor: 0,
      currentArmor: 0,
      maxHope: 6,
      currentHope: 0,
      maxStress: 6,
      currentStress: 0,
      subclassTier: SubclassTier.foundation,
      level: 1,
      advancements: Advancements(),
      backgroundQuestionnaireAnswers: {},
      experiences: [],
      connections: [],
      domainAbilities: [],
      inventory: [],
      notes: '',
      gold: Gold.empty(),
    );
  }

  /// Create a Character from XML string
  factory Character.fromXml(String xmlString, GameDataService gameDataService) {
    final document = XmlDocument.parse(xmlString);
    final characterElement = document.rootElement;

    final id = characterElement.getAttribute('id');
    if (id == null) {
      throw Exception('Character XML is missing required "id" attribute.');
    }

    final name = characterElement.getElement('name')?.innerText ?? '';
    final pronouns = characterElement.getElement('pronouns')?.innerText;
    final description = characterElement.getElement('description')?.innerText;
    final portraitPath = characterElement.getElement('portraitPath')?.innerText;

    // Ancestry
    final ancestryElement = characterElement.getElement('ancestry');
    Ancestry? ancestry;
    if (ancestryElement != null) {
      ancestry = gameDataService.ancestries.firstWhere(
          (a) => a.id == (ancestryElement.getAttribute('id') ?? ''));
    }

    // Second ancestry (if any) representing mixed ancestry
    final secondAncestryElement = characterElement.getElement('secondAncestry');
    Ancestry? secondAncestry;
    if (secondAncestryElement != null) {
      secondAncestry = gameDataService.ancestries.firstWhere(
          (a) => a.id == (secondAncestryElement.getAttribute('id') ?? ''));
    }

    // Community
    final communityElement = characterElement.getElement('community');
    Community? community;
    if (communityElement != null) {
      community = gameDataService.communities.firstWhere(
          (c) => c.id == (communityElement.getAttribute('id') ?? ''));
    }

    // Class and subclass
    final classElement = characterElement.getElement('class');
    CharacterClass? characterClass;
    SubClass? subclass;
    List<Domain> domains = [];
    if (classElement != null) {
      final classId = classElement.getAttribute('id') ?? '';
      characterClass =
          gameDataService.characterClasses.firstWhere((c) => c.id == classId);
      final subclassId = classElement.getAttribute('subclass');
      final subclassName = classElement.getAttribute('subclassName');
      if (subclassId != null && subclassName != null) {
        final allSubclasses = gameDataService.subclasses[classId] ?? [];
        subclass = allSubclasses.firstWhere(
          (sc) => sc.id == subclassId,
        );
      }
      // Resolve domains from character class
      domains = gameDataService.domains
          .where((domain) => characterClass!.domains.contains(domain.id))
          .toList();
    }

    // Companion
    // TODO: fix defaults - unlikely to come up, assuming no manual
    // meddling with XML files at which point all bets are off...
    Companion? companion;
    final companionElement = characterElement.getElement('companion');
    if (companionElement != null) {
      final companionTemplateId = companionElement.getAttribute('id') ?? '';
      final companionName = companionElement.getElement('name')?.innerText;
      final companionSubType =
          companionElement.getElement('subType')?.innerText;

      final companionTemplate =
          gameDataService.companionTemplates[companionTemplateId]!;

      final evasion = int.tryParse(
              companionElement.getElement('evasion')?.innerText ??
                  companionTemplate.startingEvasion.toString()) ??
          10;
      final maxStress = int.tryParse(
              companionElement.getElement('maxStress')?.innerText ?? '3') ??
          3;
      final currentStress = int.tryParse(
              companionElement.getElement('currentStress')?.innerText ?? '0') ??
          0;

      // Attack & damage
      final standardAttack =
          companionElement.getElement('standardAttack')?.innerText ?? 'Claws';
      final range = companionElement.getElement('range')?.innerText ?? 'Melee';
      final damageDie =
          companionElement.getElement('damageDie')?.innerText ?? 'd6';

      // Companion experiences
      final companionExperiences = <Experience>[];
      final companionExpElement = companionElement.getElement('experiences');
      if (companionExpElement != null) {
        for (var expElement in companionExpElement.findElements('experience')) {
          final name = expElement.innerText.trim();
          final modifier =
              int.tryParse(expElement.getAttribute('modifier') ?? '2') ?? 2;
          if (name.isNotEmpty) {
            companionExperiences
                .add(Experience(name: name, modifier: modifier));
          }
        }
      }

      companion = Companion(
        companionTemplate: companionTemplate,
        name: companionName,
        subType: companionSubType,
        experiences: companionExperiences,
        evasion: evasion,
        maxStress: maxStress,
        currentStress: currentStress,
        standardAttack: standardAttack,
        range: range,
        damageDie: damageDie,
      );
    }

    // Parse traits
    final traitsElement = characterElement.getElement('traits');
    Map<Trait, int> traits = {};
    if (traitsElement != null) {
      for (var traitElement in traitsElement.findElements('trait')) {
        final name = traitElement.getAttribute('name');
        final value = int.tryParse(traitElement.innerText);
        if (name != null && value != null) {
          final trait = Trait.fromName(name);
          if (trait != null) {
            traits[trait] = value;
          }
        }
      }
    }

    final evasion =
        int.tryParse(characterElement.getElement('evasion')!.innerText) ?? 0;
    final proficiency =
        int.tryParse(characterElement.getElement('proficiency')!.innerText) ??
            1;
    final majorDamageThreshold = int.tryParse(
            characterElement.getElement('majorDamageThreshold')!.innerText) ??
        1;
    final severeDamageThreshold = int.tryParse(
            characterElement.getElement('severeDamageThreshold')!.innerText) ??
        2;
    final maxHitPoints =
        int.tryParse(characterElement.getElement('maxHitPoints')!.innerText) ??
            10;
    final currentHitPoints = int.tryParse(
            characterElement.getElement('currentHitPoints')!.innerText) ??
        10;
    final maxArmor =
        int.tryParse(characterElement.getElement('maxArmor')!.innerText) ?? 0;
    final currentArmor =
        int.tryParse(characterElement.getElement('currentArmor')!.innerText) ??
            0;
    final maxHope =
        int.tryParse(characterElement.getElement('maxHope')!.innerText) ?? 6;
    final currentHope =
        int.tryParse(characterElement.getElement('currentHope')!.innerText) ??
            0;
    final maxStress =
        int.tryParse(characterElement.getElement('maxStress')!.innerText) ?? 6;
    final currentStress =
        int.tryParse(characterElement.getElement('currentStress')!.innerText) ??
            0;

    // TODO: Tier 3 and Tier 4 advancements can change subclass tier
    final subclassTier = SubclassTier.foundation;

    final level =
        int.tryParse(characterElement.getElement('level')!.innerText) ?? 1;

    // Advancements
    final advancements =
        Advancements.fromXml(characterElement.getElement('advancements'));

    // Background
    final backgroundRaw = characterElement.getElement('background')?.innerText;
    final background = backgroundRaw?.trim();

    // Background questionnaire answers, linking to question ID
    // TODO: probably overkill to link to question ID
    // rather than just copying the text as with experiences
    Map<String, String> backgroundQuestionnaireAnswers = {};
    final backgroundQuestionsElement =
        characterElement.getElement('backgroundQuestions');
    if (backgroundQuestionsElement != null) {
      for (var answerElement
          in backgroundQuestionsElement.findElements('answer')) {
        final questionId = answerElement.getAttribute('questionId');
        final answerText = answerElement.innerText;
        if (questionId != null && answerText.isNotEmpty) {
          backgroundQuestionnaireAnswers[questionId] = answerText;
        }
      }
    }

    // Experiences
    final experiencesElement = characterElement.getElement('experiences');
    List<Experience> experiences = [];
    if (experiencesElement != null) {
      for (var expElement in experiencesElement.findElements('experience')) {
        final experienceName = expElement.innerText;
        final modifier =
            int.tryParse(expElement.getAttribute('modifier')!) ?? 2;
        if (experienceName.isNotEmpty) {
          experiences.add(Experience(name: experienceName, modifier: modifier));
        }
      }
    }

    // Connections
    final connectionsElement = characterElement.getElement('connections');
    List<String> connections = [];
    if (connectionsElement != null) {
      for (var connElement in connectionsElement.findElements('connection')) {
        final connection = connElement.innerText;
        if (connection.isNotEmpty) {
          connections.add(connection);
        }
      }
    }

    // Chosen domain abilities, linked to compendium by ID
    final domainAbilitiesElement =
        characterElement.getElement('domainAbilities');
    List<DomainAbility> domainAbilities = [];
    if (domainAbilitiesElement != null) {
      for (var abilityElement
          in domainAbilitiesElement.findElements('domainAbility')) {
        final domainAbilityID = abilityElement.getAttribute('id');
        domainAbilities.add(gameDataService.domainAbilities
            .firstWhere((da) => da.id == domainAbilityID));
      }
    }

    // Inventory
    final inventoryElement = characterElement.getElement('inventory');
    List<Item> inventory = [];
    if (inventoryElement != null) {
      for (var itemElement in inventoryElement.findElements('item')) {
        inventory.add(Item(
          id: itemElement.getAttribute('id') ?? '',
          name: itemElement.getAttribute('name') ?? '',
          description: itemElement.innerText,
          quantity:
              int.tryParse(itemElement.getAttribute('quantity') ?? '1') ?? 1,
        ));
      }
    }

    // Armor
    Armor? equippedArmor;
    final equippedArmorElement = characterElement.getElement('equippedArmor');
    if (equippedArmorElement != null) {
      final armorId = equippedArmorElement.getAttribute('id');
      if (armorId != null && armorId.isNotEmpty) {
        equippedArmor =
            gameDataService.armor.firstWhere((armor) => armor.id == armorId);
      }
    }

    // Equipped weapons
    Weapon? primaryWeapon;
    Weapon? secondaryWeapon;
    final primaryWeaponElement = characterElement.getElement('primaryWeapon');
    if (primaryWeaponElement != null) {
      final weaponId = primaryWeaponElement.getAttribute('id');
      if (weaponId != null && weaponId.isNotEmpty) {
        primaryWeapon = gameDataService.weapons
            .firstWhere((weapon) => weapon.id == weaponId);
      }
    }

    final secondaryWeaponElement =
        characterElement.getElement('secondaryWeapon');
    if (secondaryWeaponElement != null) {
      final weaponId = secondaryWeaponElement.getAttribute('id');
      if (weaponId != null && weaponId.isNotEmpty) {
        secondaryWeapon = gameDataService.weapons
            .firstWhere((weapon) => weapon.id == weaponId);
      }
    }

    // Notes
    final notesRaw = characterElement.getElement('notes')?.innerText ?? '';
    final notes = notesRaw.trim();

    // Gold
    Gold gold = Gold.empty();
    final goldElement = characterElement.getElement('gold');
    if (goldElement != null) {
      int chests =
          int.tryParse(goldElement.getElement('chest')?.innerText ?? '0') ?? 0;
      int bags =
          int.tryParse(goldElement.getElement('bag')?.innerText ?? '0') ?? 0;
      int handfuls =
          int.tryParse(goldElement.getElement('handful')?.innerText ?? '0') ??
              0;
      int coins =
          int.tryParse(goldElement.getElement('coin')?.innerText ?? '0') ?? 0;
      gold = Gold(chests: chests, bags: bags, handfuls: handfuls, coins: coins);
    }

    return Character(
      id: id,
      name: name,
      pronouns: pronouns,
      description: description,
      ancestry: ancestry,
      secondAncestry: secondAncestry,
      community: community,
      characterClass: characterClass,
      subclass: subclass,
      domains: domains,
      traits: traits,
      evasion: evasion,
      proficiency: proficiency,
      majorDamageThreshold: majorDamageThreshold,
      severeDamageThreshold: severeDamageThreshold,
      maxHitPoints: maxHitPoints,
      currentHitPoints: currentHitPoints,
      maxArmor: maxArmor,
      currentArmor: currentArmor,
      maxHope: maxHope,
      currentHope: currentHope,
      maxStress: maxStress,
      currentStress: currentStress,
      subclassTier: subclassTier,
      level: level,
      advancements: advancements,
      background: background,
      backgroundQuestionnaireAnswers: backgroundQuestionnaireAnswers,
      experiences: experiences,
      connections: connections,
      portraitPath: portraitPath,
      domainAbilities: domainAbilities,
      companion: companion,
      inventory: inventory,
      equippedArmor: equippedArmor,
      primaryWeapon: primaryWeapon,
      secondaryWeapon: secondaryWeapon,
      notes: notes,
      gold: gold,
    );
  }

  /// Convert Character to XML string
  String toXml() {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element('character', nest: () {
      builder.attribute('id', id);
      builder.element('name', nest: name);

      if (pronouns != null) {
        builder.element('pronouns', nest: pronouns);
      }

      if (description != null) {
        builder.element('description', nest: description);
      }

      if (portraitPath != null) {
        builder.element('portraitPath', nest: portraitPath);
      }

      // Ancestry
      if (ancestry != null) {
        builder.element('ancestry', nest: () {
          builder.attribute('id', ancestry!.id);
          builder.attribute('name', ancestry!.name);
        });
      }

      // Second ancestry for mixed ancestry
      if (secondAncestry != null) {
        builder.element('secondAncestry', nest: () {
          builder.attribute('id', secondAncestry!.id);
          builder.attribute('name', secondAncestry!.name);
        });
      }

      // Community
      if (community != null) {
        builder.element('community', nest: () {
          builder.attribute('id', community!.id);
          builder.attribute('name', community!.name);
        });
      }

      // Class and subclass
      if (characterClass != null) {
        builder.element('class', nest: () {
          builder.attribute('id', characterClass!.id);
          builder.attribute('name', characterClass!.name);
          if (subclass != null) {
            builder.attribute('subclass', subclass!.id);
            builder.attribute('subclassName', subclass!.name);
          }
        });
      }

      // Companion
      if (companion != null) {
        builder.element('companion', nest: () {
          builder.attribute('id', companion!.companionTemplate.id);

          if (companion!.name != null) {
            builder.element('name', nest: companion!.name!);
          }

          if (companion!.subType != null) {
            builder.element('subType', nest: companion!.subType!);
          }

          builder.element('evasion', nest: companion!.evasion.toString());
          builder.element('maxStress', nest: companion!.maxStress.toString());
          builder.element('currentStress',
              nest: companion!.currentStress.toString());

          // Attack & damage
          builder.element('standardAttack', nest: companion!.standardAttack);
          builder.element('range', nest: companion!.range);
          builder.element('damageDie', nest: companion!.damageDie);

          // Experiences
          builder.element('experiences', nest: () {
            for (var exp in companion!.experiences) {
              builder.element('experience', nest: () {
                builder.attribute('modifier', exp.modifier.toString());
                builder.text(exp.name);
              });
            }
          });
        });
      }

      // Traits
      builder.element('traits', nest: () {
        traits.forEach((trait, value) {
          builder.element('trait', nest: () {
            builder.attribute('name', trait.name);
            builder.text(value.toString());
          });
        });
      });

      // Combat & resources
      builder.element('evasion', nest: evasion.toString());
      builder.element('proficiency', nest: proficiency.toString());
      builder.element('majorDamageThreshold',
          nest: majorDamageThreshold.toString());
      builder.element('severeDamageThreshold',
          nest: severeDamageThreshold.toString());
      builder.element('maxHitPoints', nest: maxHitPoints.toString());
      builder.element('currentHitPoints', nest: currentHitPoints.toString());
      builder.element('maxArmor', nest: maxArmor.toString());
      builder.element('currentArmor', nest: currentArmor.toString());
      builder.element('maxHope', nest: maxHope.toString());
      builder.element('currentHope', nest: currentHope.toString());
      builder.element('maxStress', nest: maxStress.toString());
      builder.element('currentStress', nest: currentStress.toString());

      // Level and advancements
      builder.element('level', nest: level.toString());
      advancements.toXml(builder);

      // Background
      if (background != null) {
        builder.element('background', nest: () {
          builder.cdata(background!.trim());
        });
      }

      // Background questionnaire answers
      if (backgroundQuestionnaireAnswers.isNotEmpty) {
        builder.element('backgroundQuestions', nest: () {
          for (var entry in backgroundQuestionnaireAnswers.entries) {
            builder.element('answer', nest: () {
              builder.attribute('questionId', entry.key);
              builder.text(entry.value);
            });
          }
        });
      }

      // Experiences
      builder.element('experiences', nest: () {
        for (var exp in experiences) {
          builder.element('experience', nest: () {
            builder.attribute('modifier', exp.modifier.toString());
            builder.text(exp.name);
          });
        }
      });

      // Connections
      builder.element('connections', nest: () {
        for (var conn in connections) {
          builder.element('connection', nest: conn);
        }
      });

      // Domain abilities
      builder.element('domainAbilities', nest: () {
        for (var domainAbility in domainAbilities) {
          builder.element('domainAbility', nest: () {
            builder.attribute('id', domainAbility.id);
          });
        }
      });

      // Inventory
      builder.element('inventory', nest: () {
        for (var item in inventory) {
          builder.element('item', nest: () {
            builder.attribute('id', item.id);
            builder.attribute('name', item.name);
            builder.attribute('quantity', item.quantity.toString());
            builder.text(item.description ?? '');
          });
        }
      });

      // Armor
      if (equippedArmor != null) {
        builder.element('equippedArmor', nest: () {
          builder.attribute('id', equippedArmor!.id);
        });
      }

      // Equipped weapons
      if (primaryWeapon != null) {
        builder.element('primaryWeapon', nest: () {
          builder.attribute('id', primaryWeapon!.id);
        });
      }

      if (secondaryWeapon != null) {
        builder.element('secondaryWeapon', nest: () {
          builder.attribute('id', secondaryWeapon!.id);
        });
      }

      // Gold
      builder.element('gold', nest: () {
        builder.element('chest', nest: gold.chests.toString());
        builder.element('bag', nest: gold.bags.toString());
        builder.element('handful', nest: gold.handfuls.toString());
        builder.element('coin', nest: gold.coins.toString());
      });

      // Notes
      builder.element('notes', nest: () {
        builder.cdata(notes.trim());
      });
    });

    final document = builder.buildDocument();
    return document.toXmlString(pretty: true);
  }

  /// Check if this character has a mixed ancestry
  bool get hasMixedAncestry => secondAncestry != null;

  /// Get the display name for the character's ancestry
  String get ancestryDisplayName {
    if (hasMixedAncestry) {
      return '${ancestry?.name ?? 'Unknown'} / ${secondAncestry?.name ?? 'Unknown'}';
    }
    return ancestry?.name ?? 'None';
  }

  /// Get the ancestry features selected for this character
  /// (if mixed: first from primary, second from secondary)
  List<Feature> get selectedAncestryFeatures {
    final features = <Feature>[];

    // Always take first feature from primary ancestry
    if (ancestry != null && ancestry!.features.isNotEmpty) {
      features.add(ancestry!.features.first);
    }

    if (hasMixedAncestry &&
        secondAncestry != null &&
        secondAncestry!.features.length > 1) {
      // Take second feature from second ancestry, if mixed
      features.add(secondAncestry!.features[1]);
    } else if (!hasMixedAncestry &&
        ancestry != null &&
        ancestry!.features.length > 1) {
      // Take second feature from primary ancestry if not mixed
      features.add(ancestry!.features[1]);
    }

    return features;
  }

  /// Get the subclass features for the current suclass tier and below
  /// Includes foundation features always; specialization and mastery if applicable
  List<Feature> get subclassFeatures {
    if (subclass == null) return [];

    List<Feature> features = [];
    features.addAll(subclass!.foundationFeatures);

    if (subclassTier == SubclassTier.specialization ||
        subclassTier == SubclassTier.mastery) {
      features.addAll(subclass!.specializationFeatures);
    }

    if (subclassTier == SubclassTier.mastery) {
      features.addAll(subclass!.masteryFeatures);
    }

    return features;
  }

  /// Get class and subclass string for display
  /// (e.g. "Ranger (Beastbound)")
  String get className {
    if (characterClass == null) return 'Unknown';

    String name = characterClass!.name;
    if (subclass != null) {
      name += ' (${subclass!.name})';
    }

    return name;
  }

  /// Returns a formatted string of class and level
  /// (e.g. "Ranger (Beastbound) 6")
  String get classLevelString {
    return '$className $level';
  }
}

// Stores a character creation background question
// TODO: overkill to have a separate class for this?
class BackgroundQuestion {
  final String id;
  final String text;

  BackgroundQuestion({required this.id, required this.text});
}
