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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/compendium.dart';
import '../services/game_data_service.dart';
import '../theme/heartcraft_theme.dart';

/// Screen for managing game data compendiums
class CompendiumManagementScreen extends StatefulWidget {
  const CompendiumManagementScreen({super.key});

  @override
  CompendiumManagementScreenState createState() =>
      CompendiumManagementScreenState();
}

class CompendiumManagementScreenState
    extends State<CompendiumManagementScreen> {
  late final GameDataService _gameDataService;
  Map<String, Compendium>? _compendiums;
  Map<String, bool> _enabledStates = {};
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _gameDataService = context.read<GameDataService>();
    _loadCompendiums();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          // Intercept back navigation to return whether changes were made
          if (!didPop) {
            Navigator.of(context).pop(_hasChanges);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Manage Compendiums'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(_hasChanges),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Import Compendium',
                onPressed: _importCompendium,
              ),
            ],
          ),
          body: _buildBody(),
        ));
  }

  Future<void> _loadCompendiums() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final compendiums = await _gameDataService.loadAllCompendiums();

      // Load enabled states for each compendium
      final enabledStates = <String, bool>{};
      for (final compendiumId in compendiums.keys) {
        enabledStates[compendiumId] =
            await _gameDataService.isCompendiumEnabled(compendiumId);
      }

      setState(() {
        _compendiums = compendiums;
        _enabledStates = enabledStates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importCompendium() async {
    await _gameDataService.importCompendium();
    await _loadCompendiums();
    _hasChanges = true;
  }

  Future<void> _deleteCompendium(Compendium compendium) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Compendium'),
        content: Text(
            'Are you sure you want to delete "${compendium.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
                foregroundColor: HeartcraftTheme.secondaryTextColor),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _gameDataService.deleteCompendium(compendium.id!);
        await _loadCompendiums();
        _hasChanges = true;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Deleted "${compendium.displayName}"'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete compendium: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleEnabled(
      Compendium compendium, bool currentEnabled) async {
    await _gameDataService.setCompendiumEnabled(
        compendium.id!, !currentEnabled);
    setState(() {
      _enabledStates[compendium.id!] = !currentEnabled;
    });
    _hasChanges = true;
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_compendiums == null || _compendiums!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.storage,
              size: 64,
              color: HeartcraftTheme.gold,
            ),
            const SizedBox(height: 16),
            Text(
              'No Compendiums',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Import a Compendium to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HeartcraftTheme.secondaryTextColor,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _importCompendium,
              icon: const Icon(Icons.add),
              label: const Text('Import Compendium'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _compendiums!.length,
      itemBuilder: (context, index) {
        final entry = _compendiums!.entries.elementAt(index);
        final compendium = entry.value;
        return _buildCompendiumCard(compendium);
      },
    );
  }

  Widget _buildCompendiumCard(Compendium compendium) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compendium.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: HeartcraftTheme.gold,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${compendium.id!} • Version: ${compendium.version!}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: HeartcraftTheme.secondaryTextColor,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _enabledStates[compendium.id!] ?? true,
                  onChanged: (value) => _toggleEnabled(
                      compendium, _enabledStates[compendium.id!] ?? true),
                  activeThumbColor: HeartcraftTheme.gold,
                ),
              ],
            ),
            if (compendium.description != null &&
                compendium.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                compendium.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (compendium.author != null && compendium.author!.isNotEmpty)
                  _buildInfoChip(Icons.person, compendium.author!),
                if (compendium.license != null &&
                    compendium.license!.isNotEmpty)
                  _buildInfoChip(Icons.gavel, compendium.license!),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showCompendiumDetails(compendium),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: HeartcraftTheme.lightPurple,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteCompendium(compendium),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: HeartcraftTheme.secondaryTextColor,
      ),
      label: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      backgroundColor: HeartcraftTheme.surfaceColor,
    );
  }

  void _showCompendiumDetails(Compendium compendium) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.storage, color: HeartcraftTheme.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(compendium.name ?? compendium.id!),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', compendium.name ?? '<unknown>'),
              _buildDetailRow('ID', compendium.id!),
              _buildDetailRow('Version', compendium.version!.toString()),
              _buildDetailRow('Author', compendium.author ?? '<unknown>'),
              _buildDetailRow('URL', compendium.url ?? '<unknown>'),
              _buildDetailRow('License', compendium.license ?? '<unknown>'),
              _buildDetailRow(
                  'License URL', compendium.licenseUrl ?? '<unknown>'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
                foregroundColor: HeartcraftTheme.lightPurple),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HeartcraftTheme.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
