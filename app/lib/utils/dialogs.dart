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
import 'package:heartcraft/theme/heartcraft_theme.dart';

Future<bool?> showExitConfirmation(
    BuildContext context, String itemName) async {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Discard $itemName?'),
        content: const Text(
          'Unsaved changes will be lost. '
          'Are you sure you want to go back?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: HeartcraftTheme.errorRed,
            ),
            child: const Text('Discard'),
          ),
        ],
      );
    },
  );
}
