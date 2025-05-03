import 'package:flutter/material.dart';

class ColourSyncState extends ChangeNotifier {
  bool _coloursReady = false;

  bool get coloursReady => _coloursReady;

  void setColoursReady(bool ready) {
    _coloursReady = ready;
    notifyListeners();
  }
}