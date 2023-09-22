import 'package:get/get.dart';

import '../models/university_model.dart';

class UniversityProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.defaultDecoder = (map) {
      if (map is Map<String, dynamic>) return University.fromJson(map);
      if (map is List)
        return map.map((item) => University.fromJson(item)).toList();
    };
    httpClient.baseUrl = 'YOUR-API-URL';
  }

  Future<University?> getUniversity(int id) async {
    final response = await get('university/$id');
    return response.body;
  }

  Future<Response<University>> postUniversity(University university) async =>
      await post('university', university);
  Future<Response> deleteUniversity(int id) async =>
      await delete('university/$id');
}
