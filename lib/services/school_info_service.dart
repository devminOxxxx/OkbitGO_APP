import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SchoolInfoService {
  static const String baseUrl = 'https://open.neis.go.kr/hub';

  Future<void> searchSchool(String schoolName) async {
    try {
      final url = Uri.parse('$baseUrl/schoolInfo'
          '?KEY=${ApiConfig.neisApiKey}'
          '&Type=json'
          '&ATPT_OFCDC_SC_CODE=J10' // 경기도교육청 코드
          '&SCHUL_NM=${Uri.encodeComponent("옥빛")}' // 학교 이름으로 검색
          '&pSize=100');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final schoolInfo = data['schoolInfo'];

        if (schoolInfo != null && schoolInfo[1]['row'] != null) {
          final List<dynamic> rows = schoolInfo[1]['row'];
          for (var row in rows) {}
        } else {}
      }
    } catch (e) {}
  }
}
