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

import 'package:test/test.dart';
import 'package:heartcraft/models/gold.dart';

void main() {
  group('Gold normalization', () {
    test('Normalizes coins to handfuls', () {
      final gold = Gold(coins: 25);
      expect(gold.coins, 5);
      expect(gold.handfuls, 2);
      expect(gold.bags, 0);
      expect(gold.chests, 0);
    });

    test('Normalizes handfuls to bags', () {
      final gold = Gold(handfuls: 23);
      expect(gold.coins, 0);
      expect(gold.handfuls, 3);
      expect(gold.bags, 2);
      expect(gold.chests, 0);
    });

    test('Normalizes bags to chests', () {
      final gold = Gold(bags: 15);
      expect(gold.coins, 0);
      expect(gold.handfuls, 0);
      expect(gold.bags, 5);
      expect(gold.chests, 1);
    });

    test('Normalizes all tiers', () {
      final gold = Gold(coins: 1234);
      expect(gold.chests, 1);
      expect(gold.bags, 2);
      expect(gold.handfuls, 3);
      expect(gold.coins, 4);
    });
  });

  group('Gold addition', () {
    test('Add coins', () {
      final gold = Gold(coins: 5);
      gold.addCoins(7);
      expect(gold.handfuls, 1);
      expect(gold.coins, 2);
    });

    test('Add handfuls', () {
      final gold = Gold(handfuls: 8);
      gold.addHandfuls(5);
      expect(gold.bags, 1);
      expect(gold.handfuls, 3);
    });

    test('Add bags', () {
      final gold = Gold(bags: 7);
      gold.addBags(6);
      expect(gold.chests, 1);
      expect(gold.bags, 3);
    });

    test('Add chests', () {
      final gold = Gold(chests: 2);
      gold.addChests(3);
      expect(gold.chests, 5);
    });

    test('Add another Gold', () {
      final a = Gold(coins: 9, handfuls: 9, bags: 9, chests: 9);
      final b = Gold(coins: 5, handfuls: 5, bags: 5, chests: 5);
      a.add(b);
      expect(a.chests, 15);
      expect(a.bags, 5);
      expect(a.handfuls, 5);
      expect(a.coins, 4);
    });
  });

  group('Gold subtraction and affordance', () {
    test('Subtract less than total', () {
      final gold = Gold(coins: 1234);
      final cost = Gold(coins: 234);
      final result = gold.subtract(cost);
      expect(result, true);
      expect(gold.chests, 1);
      expect(gold.bags, 0);
      expect(gold.handfuls, 0);
      expect(gold.coins, 0);
    });

    test('Subtract more than total', () {
      final gold = Gold(coins: 10);
      final cost = Gold(coins: 100);
      final result = gold.subtract(cost);
      expect(result, false);
    });

    test('canAfford returns true if enough', () {
      final gold = Gold(coins: 100);
      final cost = Gold(coins: 99);
      expect(gold.canAfford(cost), true);
    });

    test('canAfford returns false if not enough', () {
      final gold = Gold(coins: 5);
      final cost = Gold(coins: 6);
      expect(gold.canAfford(cost), false);
    });
  });

  group('Gold string representation', () {
    test('toString for 0 coins', () {
      final gold = Gold.empty();
      expect(gold.toString(), '0 coins');
    });
    test('toString for 1 chest, 2 bags, 3 handfuls and 4 coins', () {
      final gold = Gold(coins: 1234);
      expect(gold.toString(), '1 chest, 2 bags, 3 handfuls, and 4 coins');
    });
  });
}
