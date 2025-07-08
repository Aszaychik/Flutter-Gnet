import 'package:gnet_app/models/activity_model.dart';
import 'package:gnet_app/services/api_service.dart';

class ActivityService {
  final ApiService _apiService = ApiService();

  Future<List<Activity>> getActivities({int page = 1}) async {
    return await _apiService.getActivities(page: page);
  }
}