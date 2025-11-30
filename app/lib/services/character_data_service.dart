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
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:heartcraft/services/game_data_service.dart';
import 'package:heartcraft/services/portrait_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';
import '../models/character_summary.dart';
import '../models/recent_character_info.dart';

/// Service responsible for managing character data persistence
class CharacterDataService {
  final GameDataService gameDataService;

  CharacterDataService({required this.gameDataService});

  static const String _recentCharactersKey = 'recent_characters_v2';

  /// Get the directory where character files are stored
  Future<Directory> _getCharacterDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final characterDir = Directory('${appDir.path}/characters');

    if (!await characterDir.exists()) {
      await characterDir.create(recursive: true);
    }

    return characterDir;
  }

  /// Ensure all necessary data directories exist
  Future<void> ensureDirectoriesExist() async {
    await _getCharacterDirectory();
  }

  /// Save a character to a file
  Future<String> saveCharacter(Character character) async {
    final directory = await _getCharacterDirectory();
    final file = File('${directory.path}/${character.id}.xml');

    await file.writeAsString(character.toXml());

    // Add to recent characters list with current timestamp
    await _updateRecentCharacterList(character.id);

    return file.path;
  }

  /// Load a character from a file via its ID
  Future<Character> loadCharacter(String id) async {
    final directory = await _getCharacterDirectory();
    final file = File('${directory.path}/$id.xml');

    if (!await file.exists()) {
      throw FileSystemException('Character file not found', file.path);
    }

    final xmlString = await file.readAsString();
    final character = Character.fromXml(xmlString, gameDataService);

    // Update recent access time when character is loaded
    await _updateRecentCharacterList(id);

    return character;
  }

  /// Delete a character
  Future<void> deleteCharacter(String id) async {
    final directory = await _getCharacterDirectory();
    final file = File('${directory.path}/$id.xml');

    if (await file.exists()) {
      await file.delete();
    }

    // Remove from recent characters
    await _removeFromRecentCharacters(id);
  }

  /// Export character to a zip file, returning the path
  /// If `outputPath` is provided, creates the zip file at that location
  /// Otherwise, creates it in a temporary directory
  Future<String> exportCharacter(Character character,
      {String? outputPath}) async {
    final archive = Archive();

    // Add character XML to archive
    final xmlString = character.toXml();
    final xmlBytes = utf8.encode(xmlString);
    final xmlFile = ArchiveFile('character.xml', xmlBytes.length, xmlBytes);
    archive.addFile(xmlFile);

    // Add portrait image if it exists
    final portraitPath =
        await PortraitService().getPortraitPath(character.portraitPath);
    if (portraitPath != null && portraitPath.isNotEmpty) {
      final portraitFile = File(portraitPath);
      if (await portraitFile.exists()) {
        final portraitBytes = await portraitFile.readAsBytes();
        final portraitArchiveFile =
            ArchiveFile('portrait.jpg', portraitBytes.length, portraitBytes);
        archive.addFile(portraitArchiveFile);
      }
    }

    // Encode archive to zip
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    // Determine output path
    final String filePath;
    if (outputPath != null) {
      filePath = outputPath;
    } else {
      final tempDir = await getTemporaryDirectory();
      filePath = '${tempDir.path}/${character.id}.zip';
    }

    final zipFile = File(filePath);
    await zipFile.writeAsBytes(zipBytes);

    return zipFile.path;
  }

  // Import a character from a file (XML or zip archive)
  Future<Character?> importCharacter() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import Character',
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath == null) {
        return null;
      }
      if (filePath.toLowerCase().endsWith('.zip')) {
        return await _importCharacterFromArchive(filePath);
      } else if (filePath.toLowerCase().endsWith('.xml')) {
        return await _importCharacterFromXmlFile(filePath);
      }
    }

    return null;
  }

  /// Import a character from an exported XML file
  Future<Character> _importCharacterFromXmlFile(String filePath) async {
    final xmlString = await File(filePath).readAsString();
    final character = Character.fromXml(xmlString, gameDataService);

    // If character with same ID exists, fail the import
    final directory = await _getCharacterDirectory();
    final existingFile = File('${directory.path}/${character.id}.xml');
    if (await existingFile.exists()) {
      throw Exception('Character ${character.name} already exists.');
    }

    await saveCharacter(character);
    return character;
  }

  /// Import a character from an exported zip archive
  Future<Character> _importCharacterFromArchive(String filePath) async {
    final archiveFile = File(filePath);

    if (!await archiveFile.exists()) {
      throw FileSystemException('Character file not found', filePath);
    }

    // Read the zip file
    final zipBytes = await archiveFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes);

    // Find and read character.xml
    final characterXmlFile = archive.findFile('character.xml');
    if (characterXmlFile == null) {
      throw Exception('character.xml not found in archive');
    }

    final xmlString = utf8.decode(characterXmlFile.content as List<int>);
    final character = Character.fromXml(xmlString, gameDataService);

    // If character with same ID exists, fail the import
    final directory = await _getCharacterDirectory();
    final existingFile = File('${directory.path}/${character.id}.xml');
    if (await existingFile.exists()) {
      throw Exception('Character ${character.name} already exists.');
    }

    // Check if portrait exists in archive
    final portraitFile = archive.findFile('portrait.jpg');
    if (portraitFile != null) {
      // Save portrait to portraits directory
      final portraitsDir = await PortraitService().getPortraitsDirectory();
      final portraitFileName = '${character.id}_portrait.jpg';
      final portraitDestFile = File('${portraitsDir.path}/$portraitFileName');

      await portraitDestFile.writeAsBytes(portraitFile.content as List<int>);

      // Update character's portrait path
      character.portraitPath = portraitFileName;
    }

    await saveCharacter(character);
    return character;
  }

  /// Get the list of recent characters, ordered by most recently accessed
  Future<List<CharacterSummary>> getRecentCharacters() async {
    final prefs = await SharedPreferences.getInstance();
    final recentCharactersJson = prefs.getString(_recentCharactersKey);

    if (recentCharactersJson == null) {
      return [];
    }

    List<RecentCharacterInfo> recentInfos =
        await _getRecentCharacterList(prefs);

    // Sort by most recently accessed first
    recentInfos.sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));

    List<CharacterSummary> characters = [];
    final directory = await _getCharacterDirectory();

    for (var info in recentInfos) {
      try {
        final file = File('${directory.path}/${info.characterId}.xml');
        if (!await file.exists()) {
          // Character file doesn't exist anymore, skip it
          continue;
        }

        final xmlString = await file.readAsString();
        final character = Character.fromXml(xmlString, gameDataService);

        characters.add(CharacterSummary(
          id: character.id,
          name: character.name,
          className: character.className,
          level: character.level,
          portraitPath: character.portraitPath,
        ));
      } catch (e) {
        // If there's an issue loading this character, just skip it
        // TODO: sort out error handling just across the board...
        continue;
      }
    }

    return characters;
  }

  Future<List<RecentCharacterInfo>> _getRecentCharacterList(
      SharedPreferences prefs) async {
    // Get existing recent characters
    List<RecentCharacterInfo> recentInfos = [];
    final recentCharactersJson = prefs.getString(_recentCharactersKey);

    if (recentCharactersJson != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(recentCharactersJson);
        recentInfos = jsonList
            .map((json) =>
                RecentCharacterInfo.deserialise(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        recentInfos = [];
      }
    }

    return recentInfos;
  }

  /// Update recent character list with specified character ID
  Future<void> _updateRecentCharacterList(String characterId) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing recent characters
    List<RecentCharacterInfo> recentInfos =
        await _getRecentCharacterList(prefs);

    // Remove existing entry for this character if it exists
    recentInfos.removeWhere((info) => info.characterId == characterId);

    // Add this character at the beginning with current timestamp
    recentInfos.insert(
        0,
        RecentCharacterInfo(
          characterId: characterId,
          lastAccessed: DateTime.now(),
        ));

    // Save updated list
    final updatedJson =
        jsonEncode(recentInfos.map((info) => info.serialise()).toList());
    await prefs.setString(_recentCharactersKey, updatedJson);
  }

  /// Remove a character from the recent characters list
  Future<void> _removeFromRecentCharacters(String id) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing recent characters
    List<RecentCharacterInfo> recentInfos =
        await _getRecentCharacterList(prefs);

    // Remove the character
    recentInfos.removeWhere((info) => info.characterId == id);

    // Save updated list
    final updatedJson =
        jsonEncode(recentInfos.map((info) => info.serialise()).toList());
    await prefs.setString(_recentCharactersKey, updatedJson);
  }
}
