import 'package:flutter/foundation.dart';

class HomepageReloadNotifier extends ChangeNotifier {
  void notifySave() {
    notifyListeners();
  }
}
