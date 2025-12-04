import 'package:flutter/foundation.dart';
import '../models/team_response.dart';

class CurrentProjectNotifier extends ChangeNotifier {
  TeamResponse? _currentProject;

  TeamResponse? get currentProject => _currentProject;

  void setProject(TeamResponse project) {
    if (_currentProject != project) {
      _currentProject = project;
      notifyListeners();
    }
  }

  void clearProject() {
    if (_currentProject != null) {
      _currentProject = null;
      notifyListeners();
    }
  }
}
