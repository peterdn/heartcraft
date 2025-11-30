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

class Gold {
  int _chests;
  int _bags;
  int _handfuls;
  int _coins;

  int get chests => _chests;
  int get bags => _bags;
  int get handfuls => _handfuls;
  int get coins => _coins;

  Gold({
    int chests = 0,
    int bags = 0,
    int handfuls = 0,
    int coins = 0,
  })  : _chests = chests,
        _bags = bags,
        _handfuls = handfuls,
        _coins = coins {
    _normalize();
  }

  factory Gold.empty() {
    return Gold();
  }

  /// Get the total value in coins
  int get totalCoins {
    return _coins + (_handfuls * 10) + (_bags * 100) + (_chests * 1000);
  }

  /// Normalize by converting lower tiers to higher tiers
  void _normalize() {
    // Coins to handfuls
    while (_coins >= 10) {
      _handfuls += _coins ~/ 10;
      _coins = _coins % 10;
    }

    // Handfuls to bags
    while (_handfuls >= 10) {
      _bags += _handfuls ~/ 10;
      _handfuls = _handfuls % 10;
    }

    // Bags to chests
    while (_bags >= 10) {
      _chests += _bags ~/ 10;
      _bags = _bags % 10;
    }
  }

  void add(Gold other) {
    _coins += other._coins;
    _handfuls += other._handfuls;
    _bags += other._bags;
    _chests += other._chests;
    _normalize();
  }

  void addCoins(int coins) {
    _coins += coins;
    _normalize();
  }

  void addHandfuls(int handfuls) {
    _handfuls += handfuls;
    _normalize();
  }

  void addBags(int bags) {
    _bags += bags;
    _normalize();
  }

  void addChests(int chests) {
    _chests += chests;
    _normalize();
  }

  bool canAfford(Gold cost) {
    return totalCoins >= cost.totalCoins;
  }

  /// Subtract gold from this amount
  /// Returns true if successful, false if insufficient funds
  bool subtract(Gold other) {
    if (!canAfford(other)) {
      return false;
    }

    _coins = totalCoins - other.totalCoins;
    _chests = 0;
    _bags = 0;
    _handfuls = 0;
    _normalize();

    return true;
  }

  /// Get a human-readable string representation
  @override
  String toString() {
    List<String> parts = [];

    String pluralize(int count, String singular) {
      return '$count $singular${count == 1 ? '' : 's'}';
    }

    if (_chests > 0) {
      parts.add(pluralize(_chests, 'chest'));
    }
    if (_bags > 0) {
      parts.add(pluralize(_bags, 'bag'));
    }
    if (_handfuls > 0) {
      parts.add(pluralize(_handfuls, 'handful'));
    }
    if (_coins > 0) {
      parts.add(pluralize(_coins, 'coin'));
    }

    if (parts.isEmpty) {
      return '0 coins';
    }

    if (parts.length == 1) {
      return parts.first;
    }

    final oxfordComma = parts.length > 2 ? ',' : '';
    return '${parts.sublist(0, parts.length - 1).join(', ')}$oxfordComma and ${parts.last}';
  }
}
