import 'package:shared_preferences/shared_preferences.dart';

class ProjectSelectionService {
  final SharedPreferences _sharedPreferences;

  ProjectSelectionService(this._sharedPreferences);

  String? get selectedSite => _sharedPreferences.getString('last_selected_site');
  String? get selectedProject => _sharedPreferences.getString('last_selected_project_name');

  Future<void> saveSelection({required String site, required String project}) async {
    await _sharedPreferences.setString('last_selected_site', site);
    await _sharedPreferences.setString('last_selected_project_name', project);
  }
}
