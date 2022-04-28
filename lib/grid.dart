import 'dart:math';

import 'package:nagasaki/classes.dart';
import 'classes.dart';
import 'iterators.dart';

class Grid {
  late List<FieldData> _grid;
  late GameSettings _sett;

  bool _locked = false;
  int _clickedFields = 0;
  int _flaggedFields = 0;
  int _totalFields = 0;

  // constructor
  Grid({required sett}) {
    _sett = sett;
    _totalFields = _sett.rows * _sett.columns;
    _grid = List.generate(_totalFields, (i) => FieldData());
  }

  int get columns => _sett.columns;
  int get rows => _sett.rows;
  int get fields => _totalFields;
  int get bombs => _sett.bombs;
  int get flagged => _flaggedFields;
  int get flagsLeft => bombs - flagged;
  int get clicked => _clickedFields;
  bool get locked => _locked;
  GameSettings get settings => _sett;

  int ijToIndex(int i, int j) => i * _sett.columns + j;
  FieldPosition indexToij(int index) =>
      FieldPosition(index ~/ columns, index % columns);

  FieldData at(int index) {
    return _grid[index];
  }


  FieldData atij(int i, int j) {
    return _grid[i * _sett.columns + j];
  }

  FieldData atPos(FieldPosition pos) {
    return _grid[pos.i * _sett.columns + pos.j];
  }

  void lock() {
    _locked = true;
  }

  bool flag(int index) {
    var el = at(index);

    // cant put flag when game over
    if (locked) return false;

    // cant put flag when clicked
    if (el.isClicked) return false;

    if (!el.isFlagged) {
      // reached maximum of flags
      if (flagged == bombs) return false;

      // flag
      el.isFlagged = true;
      _flaggedFields++;
    } else {
      // remove flag
      el.isFlagged = false;
      _flaggedFields--;
    }

    return true;
  }

  bool tap(int index) {
    // cannot tap when game is over
    if (locked) return false;

    var el = at(index);

    // cannot tap if field is flagged
    if (el.isFlagged) return false;

    // first click
    if (_clickedFields == 0) generateBombs(index);

    // make visible
    if (!el.isClicked) makeFieldVisible(index);

    // game end checks --> main.dart
    return true;
  }

  int _countBombsAround(int index) {
    // count bombs around a bomb
    var counter = 0;
    for (FieldData f in FieldsAround(grid: this, index: index)) {
      if (f.isBomb) counter++;
    }
    return counter;
  }

  void generateBombs(int tapIndex) {
    // select random coordinates and add bombs
    var rng = Random();
    var bombs = <int>{};
    var tapPos = indexToij(tapIndex);

    while (bombs.length != _sett.bombs) {
      int randomNumber = rng.nextInt(_sett.columns * _sett.rows);
      var randomPos = indexToij(randomNumber);

      // check if i, j != first clicked field
      // to avoid generating a bomb under the user's finger
      if (!(randomPos.i >= tapPos.i - 1 &&
          randomPos.i <= tapPos.i + 1 &&
          randomPos.j >= tapPos.j - 1 &&
          randomPos.j <= tapPos.j + 1)) {
        bombs.add(randomNumber);
      }
    }

    for (int i in bombs) {
      at(i).isBomb = true;
    }

    // set bomb counts
    for (int i = 0; i < _grid.length; i++) {
      at(i).bombsAround = _countBombsAround(i);
    }
  }

  void makeFieldVisible(int index) {
    // make the field visible
    var field = at(index);

    if (field.isFlagged) return;

    field.isClicked = true;
    _clickedFields++;

    if (field.isBomb) return;

    // make fields around visible
    if (field.bombsAround == 0) {
      for (int f in FieldsAroundPosition(grid: this, index: index)) {
        if (!at(f).isClicked) makeFieldVisible(f);
      }
    }
  }
}
