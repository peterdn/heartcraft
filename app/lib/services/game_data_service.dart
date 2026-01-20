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

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:heartcraft/models/domain.dart';
import 'package:heartcraft/models/feature.dart';
import 'package:heartcraft/models/class.dart';
import 'package:heartcraft/models/compendium.dart';
import 'package:heartcraft/models/ancestry.dart';
import 'package:heartcraft/models/community.dart';
import 'package:heartcraft/models/trait.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';
import '../models/character.dart';
import '../models/companion.dart';
import '../models/equipment.dart';
import '../models/gold.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for loading game data from XML files
class GameDataService {
  // Cache for game data from ALL enabled compendiums
  Compendium? _mergedCompendium;

  // SharedPreferences key for storing enabled compendiums
  static const String _enabledCompendiumsKey = 'enabled_compendiums';

  // List of "built-in" compendiums that should be automatically
  // imported and enabled. The files should exist in assets/data/
  final List<String> _builtinCompendiumIds = [
    'com.daggerheart.srd.may_20_2025',
    'app.heartcraft.homebrew.demo',
  ];

  /// Check if a compendium is enabled in SharedPreferences
  Future<bool> isCompendiumEnabled(String compendiumId) async {
    final prefs = await SharedPreferences.getInstance();
    final enabledList = prefs.getStringList(_enabledCompendiumsKey);

    return enabledList?.contains(compendiumId) ?? false;
  }

  /// Enable or disable a compendium in SharedPreferences
  Future<void> setCompendiumEnabled(String compendiumId, bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> enabledList =
        prefs.getStringList(_enabledCompendiumsKey) ?? [];

    if (enable) {
      if (!enabledList.contains(compendiumId)) {
        enabledList.add(compendiumId);
      }
    } else {
      enabledList.remove(compendiumId);
    }

    await prefs.setStringList(_enabledCompendiumsKey, enabledList);
  }

  /// Get all enabled compendium IDs from SharedPreferences
  Future<Set<String>> getEnabledCompendiumIds() async {
    final prefs = await SharedPreferences.getInstance();
    final enabledList = prefs.getStringList(_enabledCompendiumsKey);

    return enabledList?.toSet() ?? {};
  }

  /// Ensure all game data files exist and are up to date
  Future<void> bootstrapBuiltinGameData() async {
    final directory = await _getGameDataDirectory();

    for (final compendiumId in _builtinCompendiumIds) {
      try {
        final compendiumFilename = '$compendiumId.xml';
        if (await _ensureXmlFileUpToDate(directory, compendiumFilename,
            await _getBuiltinCompendiumXml(compendiumFilename))) {
          // Only enable if the file was created or updated
          await setCompendiumEnabled(compendiumId, true);
        }
      } on FlutterError {
        // Ignore errors during bootstrap
        continue;
      }
    }
  }

  /// Check if a file exists and has the correct version, update if needed
  Future<bool> _ensureXmlFileUpToDate(
      Directory directory, String filename, String defaultContent) async {
    final file = File('${directory.path}/$filename');

    bool needsUpdate = false;

    if (!await file.exists()) {
      needsUpdate = true;
    } else {
      // Check version
      try {
        final existingContent = await file.readAsString();
        final existingVersion = _extractVersion(existingContent);
        final defaultVersion = _extractVersion(defaultContent);

        if (existingVersion < defaultVersion) {
          needsUpdate = true;
        }
      } catch (e) {
        // If we can't parse the existing file, update it
        needsUpdate = true;
      }
    }

    if (needsUpdate) {
      await file.writeAsString(defaultContent);
    }

    return needsUpdate;
  }

  /// Extract version number from XML content
  int _extractVersion(String xmlContent) {
    try {
      final document = XmlDocument.parse(xmlContent);
      final versionStr = document.rootElement.getAttribute('version');
      return int.tryParse(versionStr ?? '1') ?? 1;
    } catch (e) {
      return 1; // Default to version 1 if can't parse
    }
  }

  Future<Map<String, Compendium>> loadAllCompendiums() async {
    _mergedCompendium = Compendium();

    // load all compendiums in the game data directory
    final directory = await _getGameDataDirectory();
    final compendiums = <String, Compendium>{};

    // Get the set of enabled compendium IDs
    final enabledIds = await getEnabledCompendiumIds();

    for (final file in directory.listSync()) {
      if (file is File && file.path.endsWith('.xml')) {
        try {
          final compendium = await loadCompendium(file);
          compendiums[compendium.id!] = compendium;

          // Only merge enabled compendiums into the merged compendium
          if (enabledIds.contains(compendium.id)) {
            _mergedCompendium?.merge(compendium);
          }
        } catch (e) {
          continue;
        }
      }
    }

    _mergedCompendium?.id = 'merged';
    _mergedCompendium?.version = -1;

    return compendiums;
  }

  Future<Compendium> loadCompendium(File compendiumFile) async {
    final compendiumXml = await compendiumFile.readAsString();
    return parseCompendiumFromXml(compendiumXml);
  }

  void loadFromXmlStrings(List<String> xmlStrings) {
    _mergedCompendium = Compendium();

    for (final xmlString in xmlStrings) {
      final compendium = parseCompendiumFromXml(xmlString);
      _mergedCompendium?.merge(compendium);
    }

    _mergedCompendium?.id = 'merged';
    _mergedCompendium?.version = -1;
  }

  Compendium parseCompendiumFromXml(String compendiumXml) {
    final compendiumDocument = XmlDocument.parse(compendiumXml);

    final compendium = Compendium();

    // Compendium *must* have an id and version
    compendium.id = compendiumDocument.rootElement.getAttribute('id');
    if (compendium.id == null) {
      throw Exception('Compendium is missing ID attribute');
    }

    final versionStr = compendiumDocument.rootElement.getAttribute('version');
    if (versionStr == null) {
      throw Exception('Compendium is missing version attribute');
    }
    compendium.version = int.parse(versionStr);

    // Load optional metadata fields
    compendium.name = compendiumDocument.rootElement.getAttribute('name');
    compendium.description =
        compendiumDocument.rootElement.getAttribute('description');
    compendium.author = compendiumDocument.rootElement.getAttribute('author');
    compendium.url = compendiumDocument.rootElement.getAttribute('url');
    compendium.license = compendiumDocument.rootElement.getAttribute('license');
    compendium.licenseUrl =
        compendiumDocument.rootElement.getAttribute('licenseUrl');

    loadClasses(compendiumDocument, compendium);
    loadAncestries(compendiumDocument, compendium);
    loadCommunities(compendiumDocument, compendium);
    loadDomains(compendiumDocument, compendium);
    loadEquipment(compendiumDocument, compendium);
    loadAllExperiences(compendiumDocument, compendium);

    return compendium;
  }

  Future<String> _getBuiltinCompendiumXml(String compendiumFilename) async {
    return await rootBundle.loadString('assets/data/$compendiumFilename');
  }

  /// Delete a compendium file from the game data directory
  Future<void> deleteCompendium(String compendiumId) async {
    final directory = await _getGameDataDirectory();
    final file = File('${directory.path}/$compendiumId.xml');

    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Import a compendium from an XML file
  Future<void> importCompendium() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import Compendium',
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath != null) {
        await importCompendiumFromFile(filePath);
      }
    }
  }

  /// Import and validate a compendium XML file
  Future<void> importCompendiumFromFile(String filePath) async {
    final compendiumFile = File(filePath);

    if (!await compendiumFile.exists()) {
      throw FileSystemException('Compendium file not found', filePath);
    }

    // Try to load and validate the compendium
    final compendium = await loadCompendium(compendiumFile);

    if (compendium.id == null || compendium.id!.isEmpty) {
      throw Exception('Invalid compendium: missing ID');
    }

    // Copy to game data directory
    final directory = await _getGameDataDirectory();
    final destFile = File('${directory.path}/${compendium.id}.xml');
    await compendiumFile.copy(destFile.path);
  }

  /// Get the directory where game data files are stored
  Future<Directory> _getGameDataDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final dataDir = Directory('${appDir.path}/data');

    // Create directory if it doesn't exist
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    return dataDir;
  }

  /// Load all character classes from XML
  List<CharacterClass> loadClasses(
      XmlDocument compendiumDocument, Compendium compendium) {
    if (compendium.classes.isNotEmpty) return compendium.classes;

    try {
      final classesElement =
          compendiumDocument.rootElement.getElement("classes");
      for (var classElement in classesElement!.findElements('class')) {
        final hopeFeatures = _parseClassFeatures(
            classElement.getElement('hopeFeature'), compendium);
        final classFeatures = _parseClassFeatures(
            classElement.getElement('classFeatures'), compendium);
        final allFeatures = [...hopeFeatures, ...classFeatures];

        final cls = CharacterClass(
          id: compendium.fullyQualifiedId(classElement.getAttribute('id')!),
          name: classElement.getAttribute('name') ?? '',
          description: classElement.getElement('description')?.innerText,
          startingEvasion:
              int.parse(classElement.getElement('startingEvasion')!.innerText),
          startingHitPoints: int.parse(
              classElement.getElement('startingHitPoints')!.innerText),
          domains: classElement
                  .getElement('domains')
                  ?.findElements('domain')
                  .map(
                      (e) => compendium.fullyQualifiedId(e.getAttribute('id')!))
                  .toList() ??
              [],
          classFeatures: allFeatures,
        );

        compendium.classes.add(cls);

        // Get subclasses
        final subclassesElement = classElement.getElement('subclasses');
        if (subclassesElement == null) {
          continue;
        }

        List<SubClass> subclasses = [];
        for (var subclassElement
            in subclassesElement.findElements('subclass')) {
          final id =
              compendium.fullyQualifiedId(subclassElement.getAttribute('id')!);
          final name = subclassElement.getAttribute('name')!;
          final description = subclassElement.getAttribute('description');

          // Parse spellcast trait
          Trait? spellcastTrait;
          final spellcastTraitElement =
              subclassElement.getElement('spellcastTrait');
          if (spellcastTraitElement != null) {
            final traitString = spellcastTraitElement.innerText.toLowerCase();
            try {
              spellcastTrait = Trait.values.firstWhere(
                (trait) => trait.displayName.toLowerCase() == traitString,
              );
            } catch (e) {
              continue;
            }
          }

          // Parse companion if present
          CompanionTemplate? companion;
          final companionElement = subclassElement.getElement('companion');
          if (companionElement != null) {
            final companionId = companionElement.getAttribute('id');
            final companionType = companionElement.getAttribute('type');
            final companionName =
                companionElement.getElement('name')?.innerText ?? '';
            final companionDescription =
                companionElement.getElement('description')?.innerText ?? '';
            final startingEvasion = int.tryParse(
                    companionElement.getElement('startingEvasion')?.innerText ??
                        '0') ??
                0;

            // Parse available experiences
            final availableExperiences = <String>[];
            final experiencesElement =
                companionElement.getElement('experiences');
            if (experiencesElement != null) {
              for (final expElement
                  in experiencesElement.findElements('experience')) {
                final expText = expElement.innerText.trim();
                if (expText.isNotEmpty) {
                  availableExperiences.add(expText);
                }
              }
            }

            companion = CompanionTemplate(
              id: companionId!,
              type: companionType!,
              name: companionName,
              description: companionDescription,
              startingEvasion: startingEvasion,
              availableExperiences: availableExperiences,
            );
            compendium.companionTemplates[companion.id] = companion;
          }

          final foundationFeatures = _parseClassFeatures(
              subclassElement.getElement('foundationFeatures'), compendium);
          final specializationFeatures = _parseClassFeatures(
              subclassElement.getElement('specializationFeatures'), compendium);
          final masteryFeatures = _parseClassFeatures(
              subclassElement.getElement('masteryFeatures'), compendium);

          subclasses.add(SubClass(
            characterClass: cls,
            id: id,
            name: name,
            description: description,
            spellcastTrait: spellcastTrait,
            companion: companion,
            foundationFeatures: foundationFeatures,
            specializationFeatures: specializationFeatures,
            masteryFeatures: masteryFeatures,
          ));
        }

        compendium.subclasses[cls.id] = subclasses;

        // Load class items
        final classItems = <String>[];
        final classItemsElement = classElement.getElement('classItems');
        if (classItemsElement != null) {
          for (final itemElement in classItemsElement.findElements('item')) {
            final itemText = itemElement.innerText.trim();
            if (itemText.isNotEmpty) {
              classItems.add(itemText);
            }
          }
        }

        compendium.classItems[cls.id] = classItems;

        // Background questions
        final backgroundQuestions = <String, BackgroundQuestion>{};
        final backgroundQuestionsElement =
            classElement.getElement('backgroundQuestions');
        if (backgroundQuestionsElement != null) {
          for (final questionElement
              in backgroundQuestionsElement.findElements('question')) {
            final questionText = questionElement.innerText.trim();
            final questionId = compendium
                .fullyQualifiedId(questionElement.getAttribute('id')!);
            if (questionText.isNotEmpty && questionId.isNotEmpty) {
              backgroundQuestions[questionId] =
                  BackgroundQuestion(id: questionId, text: questionText);
            }
          }
        }

        compendium.backgroundQuestions[cls.id] = backgroundQuestions;
      }

      return compendium.classes;
    } catch (e) {
      return [];
    }
  }

  List<Feature> _parseClassFeatures(
      XmlElement? featuresElement, Compendium compendium) {
    final features = <Feature>[];
    if (featuresElement != null) {
      for (final featureElement in featuresElement.findElements('feature')) {
        final id =
            compendium.fullyQualifiedId(featureElement.getAttribute('id')!);
        final name = featureElement.getElement('name')?.innerText ?? '';
        final description =
            featureElement.getElement('description')?.innerText ?? '';
        features.add(Feature(id: id, name: name, description: description));
      }
    }
    return features;
  }

  /// Load all character ancestries from XML
  List<Ancestry> loadAncestries(
      XmlDocument compendiumDocument, Compendium? compendium) {
    if (compendium == null) return [];
    if (compendium.ancestries.isNotEmpty) return compendium.ancestries;

    try {
      final ancestriesElement =
          compendiumDocument.rootElement.getElement("ancestries");
      for (var ancestryElement in ancestriesElement!.findElements('ancestry')) {
        compendium.ancestries.add(Ancestry(
          id: compendium.fullyQualifiedId(ancestryElement.getAttribute('id')!),
          name: ancestryElement.getAttribute('name') ?? '',
          description: ancestryElement.getElement('description')?.innerText,
          features: ancestryElement
              .findElements('ancestryFeature')
              .map((e) => Feature(
                    id: compendium.fullyQualifiedId(e.getAttribute('id')!),
                    name: e.getAttribute('name') ?? '',
                    description: e.getAttribute('description') ?? '',
                  ))
              .toList(),
        ));
      }

      return compendium.ancestries;
    } catch (e) {
      return [];
    }
  }

  /// Load all character communities from XML
  List<Community> loadCommunities(
      XmlDocument compendiumDocument, Compendium? compendium) {
    if (compendium == null) return [];
    if (compendium.communities.isNotEmpty) return compendium.communities;

    try {
      final communitiesElement =
          compendiumDocument.rootElement.getElement("communities");
      for (var communityElement
          in communitiesElement!.findElements('community')) {
        final featureElement = communityElement.getElement('communityFeature');
        compendium.communities.add(Community(
          id: compendium.fullyQualifiedId(communityElement.getAttribute('id')!),
          name: communityElement.getAttribute('name') ?? '',
          description: communityElement.getElement('description')?.innerText,
          feature: Feature(
            id: compendium
                .fullyQualifiedId(featureElement!.getAttribute('id')!),
            name: featureElement.getAttribute('name') ?? '',
            description: featureElement.getAttribute("description") ?? "",
          ),
        ));
      }

      return compendium.communities;
    } catch (e) {
      return [];
    }
  }

  /// Load all domains from XML
  List<Domain> loadDomains(
      XmlDocument compendiumDocument, Compendium? compendium) {
    if (compendium == null) return [];
    if (compendium.domains.isNotEmpty) return compendium.domains;

    try {
      final domainsElement =
          compendiumDocument.rootElement.getElement("domains");
      for (var domainElement in domainsElement!.findElements('domain')) {
        final domain = Domain(
          id: compendium.fullyQualifiedId(domainElement.getAttribute('id')!),
          name: domainElement.getAttribute('name') ?? '',
          description: domainElement.getElement('description')?.innerText,
        );
        compendium.domains.add(domain);

        final domainAbilityElement =
            domainElement.getElement('domainAbilities');

        for (final abilityElement
            in domainAbilityElement!.findElements('ability')) {
          final abilityId =
              compendium.fullyQualifiedId(abilityElement.getAttribute('id')!);
          final name = abilityElement.getElement('name')?.innerText ?? '';
          final level = int.tryParse(
                  abilityElement.getElement('level')?.innerText ?? '1') ??
              1;
          final recallCost = int.tryParse(
                  abilityElement.getElement('recallCost')?.innerText ?? '0') ??
              0;
          final description =
              abilityElement.getElement('description')?.innerText ?? '';
          if (name.isNotEmpty) {
            compendium.domainAbilities.add(DomainAbility(
              id: abilityId,
              domain: domain.id,
              name: name,
              level: level,
              recallCost: recallCost,
              description: description,
            ));
          }
        }
      }

      return compendium.domains;
    } catch (e) {
      return [];
    }
  }

  void loadEquipment(XmlDocument compendiumDocument, Compendium? compendium) {
    if (compendium == null) return;

    try {
      final equipmentElement =
          compendiumDocument.rootElement.getElement("equipment")!;

      loadWeapons(equipmentElement, compendium);
      loadArmor(equipmentElement, compendium);
      loadStartingEquipment(equipmentElement, compendium);
      loadStartingGold(equipmentElement, compendium);
      loadEquipmentOptionGroups(equipmentElement, compendium);
    } catch (e) {
      return;
    }
  }

  /// Load all weapons from XML
  void loadWeapons(XmlElement equipmentElement, Compendium? compendium) {
    if (compendium == null) return;
    if (compendium.primaryWeapons.isNotEmpty) return;

    try {
      final weaponsElement = equipmentElement.getElement("weapons");

      // Load primary weapons (physical and magic)
      for (final primary in weaponsElement!.findAllElements('primary')) {
        final damageType = primary.getAttribute('type') ?? 'physical';
        final tier = int.tryParse(primary.getAttribute('tier') ?? '1') ?? 1;
        for (final weapon in primary.findElements('weapon')) {
          compendium.primaryWeapons.add(
              Weapon.fromXml(weapon, damageType, 'primary', tier, compendium));
        }
      }

      // Load secondary weapons
      for (final secondary in weaponsElement.findAllElements('secondary')) {
        final damageType = secondary.getAttribute('type') ?? 'physical';
        final tier = int.tryParse(secondary.getAttribute('tier') ?? '1') ?? 1;
        for (final weapon in secondary.findElements('weapon')) {
          compendium.secondaryWeapons.add(Weapon.fromXml(
              weapon, damageType, 'secondary', tier, compendium));
        }
      }
    } catch (e) {
      return;
    }
  }

  /// Load all armor from XML
  List<Armor> loadArmor(XmlElement equipmentElement, Compendium? compendium) {
    if (compendium == null) return [];
    if (compendium.armor.isNotEmpty) return compendium.armor;

    try {
      final armorsElement = equipmentElement.getElement("armors");

      for (final armorElement in armorsElement!.findAllElements('armor')) {
        final tier =
            int.tryParse(armorElement.getAttribute('tier') ?? '1') ?? 1;
        for (final item in armorElement.findElements('armorItem')) {
          compendium.armor.add(Armor.fromXml(item, tier, compendium));
        }
      }

      return compendium.armor;
    } catch (e) {
      return [];
    }
  }

  /// Load starting equipment items
  List<String> loadStartingEquipment(
      XmlElement equipmentElement, Compendium? compendium) {
    if (compendium == null) return [];
    if (compendium.startingItems.isNotEmpty) return compendium.startingItems;

    try {
      final startingEquipment =
          equipmentElement.getElement('startingEquipment');
      if (startingEquipment != null) {
        final itemsElement = startingEquipment.getElement('items');
        if (itemsElement != null) {
          for (final itemElement in itemsElement.findElements('item')) {
            final itemText = itemElement.innerText.trim();
            if (itemText.isNotEmpty) {
              compendium.startingItems.add(itemText);
            }
          }
        }
      }
      return compendium.startingItems;
    } catch (e) {
      return [];
    }
  }

  /// Load starting gold
  Gold loadStartingGold(XmlElement equipmentElement, Compendium? compendium) {
    if (compendium == null) return Gold.empty();
    if (compendium.startingGold != null) return compendium.startingGold!;

    compendium.startingGold = Gold.empty();

    try {
      final startingEquipment =
          equipmentElement.getElement("startingEquipment");
      if (startingEquipment != null) {
        final goldElement = startingEquipment.getElement('gold');
        if (goldElement != null) {
          int chests =
              int.tryParse(goldElement.getElement('chest')?.innerText ?? '0') ??
                  0;
          int bags =
              int.tryParse(goldElement.getElement('bag')?.innerText ?? '0') ??
                  0;
          int handfuls = int.tryParse(
                  goldElement.getElement('handful')?.innerText ?? '0') ??
              0;
          int coins =
              int.tryParse(goldElement.getElement('coin')?.innerText ?? '0') ??
                  0;
          compendium.startingGold = Gold(
              chests: chests, bags: bags, handfuls: handfuls, coins: coins);
        }
      }
    } catch (e) {
      // Ignore
    }
    return compendium.startingGold!;
  }

  /// Load option groups for starting equipment
  List<OptionGroup> loadEquipmentOptionGroups(
      XmlElement equipmentElement, Compendium? compendium) {
    if (compendium == null) return [];
    if (compendium.startingOptionGroups.isNotEmpty) {
      return compendium.startingOptionGroups;
    }

    try {
      final startingEquipment =
          equipmentElement.getElement("startingEquipment");

      if (startingEquipment != null) {
        for (final optionGroupElement
            in startingEquipment.findElements('optionGroup')) {
          compendium.startingOptionGroups
              .add(OptionGroup.fromXml(optionGroupElement, compendium));
        }
      }

      return compendium.startingOptionGroups;
    } catch (e) {
      return [];
    }
  }

  List<Map<String, String>> loadAllExperiences(
      XmlDocument compendiumDocument, Compendium? compendium) {
    if (compendium == null) return [];
    if (compendium.experiences.isNotEmpty) return compendium.experiences;

    try {
      final experiencesElement =
          compendiumDocument.rootElement.getElement("experiences");
      for (var categoryElement
          in experiencesElement!.findElements('category')) {
        final categoryName = categoryElement.getAttribute('name') ?? '';
        for (var expElement in categoryElement.findElements('experience')) {
          final expName = expElement.innerText.trim();
          if (expName.isNotEmpty) {
            compendium.experiences
                .add({'name': expName, 'category': categoryName});
          }
        }
      }
      return compendium.experiences;
    } catch (e) {
      return [];
    }
  }

  List<CharacterClass> get characterClasses => _mergedCompendium?.classes ?? [];
  List<Ancestry> get ancestries => _mergedCompendium?.ancestries ?? [];
  List<Community> get communities => _mergedCompendium?.communities ?? [];
  List<Domain> get domains => _mergedCompendium?.domains ?? [];
  List<DomainAbility> get domainAbilities =>
      _mergedCompendium?.domainAbilities ?? [];
  List<Weapon> get primaryWeapons => _mergedCompendium?.primaryWeapons ?? [];
  List<Weapon> get secondaryWeapons =>
      _mergedCompendium?.secondaryWeapons ?? [];
  List<Armor> get armor => _mergedCompendium?.armor ?? [];
  Map<String, List<SubClass>> get subclasses =>
      _mergedCompendium?.subclasses ?? {};
  Map<String, List<String>> get classItems =>
      _mergedCompendium?.classItems ?? {};
  List<String> get startingItems => _mergedCompendium?.startingItems ?? [];
  Gold? get startingGold => _mergedCompendium?.startingGold;
  List<OptionGroup> get startingOptionGroups =>
      _mergedCompendium?.startingOptionGroups ?? [];
  Map<String, Map<String, BackgroundQuestion>> get backgroundQuestions =>
      _mergedCompendium?.backgroundQuestions ?? {};
  List<Map<String, String>> get experiences =>
      _mergedCompendium?.experiences ?? [];
  Map<String, CompanionTemplate> get companionTemplates =>
      _mergedCompendium?.companionTemplates ?? {};
}
