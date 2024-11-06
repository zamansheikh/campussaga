// ignore_for_file: unused_local_variable, unused_element

// http://result.nu.ac.bd/results_latest/result_show.php?reg_no=17211085864&exm_code=Bachelor%20Degree%20(Honours)%203rd%20Year&sub_code=1&exm_year=2022

import 'dart:convert';

class UrlModel {
  String base;
  String sbase1;
  String sbase2;
  String sbase3;
  String tag1;
  String tag2;
  String tag3;
  String gem1;
  String tag4;
  String tag5;
  String tag6;
  String gem2;
  String tag7;
  String tag8;
  String tag9;
  String gem3;
  String tag10;
  List<String> sortBy;

  UrlModel({
    required this.base,
    required this.sbase1,
    required this.sbase2,
    required this.sbase3,
    required this.tag1,
    required this.tag2,
    required this.tag3,
    required this.gem1,
    required this.tag4,
    required this.tag5,
    required this.tag6,
    required this.gem2,
    required this.tag7,
    required this.tag8,
    required this.tag9,
    required this.gem3,
    required this.tag10,
    required this.sortBy,
  });

  factory UrlModel.fromJson(Map<String, dynamic> json) {
    return UrlModel(
      base: json['base'],
      sbase1: json['sbase1'],
      sbase2: json['sbase2'],
      sbase3: json['sbase3'],
      tag1: json['tag1'],
      tag2: json['tag2'],
      tag3: json['tag3'],
      gem1: json['gem1'],
      tag4: json['tag4'],
      tag5: json['tag5'],
      tag6: json['tag6'],
      gem2: json['gem2'],
      tag7: json['tag7'],
      tag8: json['tag8'],
      tag9: json['tag9'],
      gem3: json['gem3'],
      tag10: json['tag10'],
      sortBy: List<String>.from(json['sortBy']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base': base,
      'sbase1': sbase1,
      'sbase2': sbase2,
      'sbase3': sbase3,
      'tag1': tag1,
      'tag2': tag2,
      'tag3': tag3,
      'gem1': gem1,
      'tag4': tag4,
      'tag5': tag5,
      'tag6': tag6,
      'gem2': gem2,
      'tag7': tag7,
      'tag8': tag8,
      'tag9': tag9,
      'gem3': gem3,
      'tag10': tag10,
      'sortBy': sortBy,
    };
  }
}

void main(List<String> args) {
  Map<String, dynamic> url = {
    'base': "http://result.nu.ac.bd/results_latest/result_show.php?",
    'sbase1': '',
    'sbase2': '',
    'sbase3': '',
    'tag1': 'reg_no=',
    'tag2': '',
    'tag3': '',
    'gem1': '123',
    'tag4': '&exm_code=',
    'tag5': 'Bachelor%20Degree%20(Honours)%203rd%20Year',
    'tag6': '&sub_code=',
    'gem2': '1',
    'tag7': '&exm_year=',
    'tag8': '',
    'tag9': '',
    'gem3': '2022',
    'tag10': '',
    'sortBy': ['gem3', 'gem2', 'gem1'],
  };

  String dynamicUrl(
    Map url, {
    required String regNo,
    required String examType,
    required String examYear,
    required String rollNo,
  }) {
    // Extract sortBy list
    List<String> sortBy = url['sortBy'];

    // Create a map to hold sorted gem values
    Map<String, String> sortedGems = {
      'gem1': '',
      'gem2': '',
      'gem3': '',
    };

    // Assign values based on sortBy order
    for (String gem in sortBy) {
      if (gem == 'gem1') {
        sortedGems['gem1'] = regNo.isEmpty ? url['gem1'] : regNo;
      } else if (gem == 'gem2') {
        sortedGems['gem2'] = rollNo.isEmpty ? url['gem2'] : rollNo;
      } else if (gem == 'gem3') {
        sortedGems['gem3'] = examYear.isEmpty ? url['gem3'] : examYear;
      }
    }

    // Construct the URL using sorted gem values
    return url['base'] +
        url['sbase1'] +
        url['sbase2'] +
        url['sbase3'] +
        url['tag1'] +
        url['tag2'] +
        url['tag3'] +
        sortedGems['gem1'] +
        url['tag4'] +
        url['tag5'] +
        url['tag6'] +
        sortedGems['gem2'] +
        url['tag7'] +
        url['tag8'] +
        url['tag9'] +
        sortedGems['gem3'] +
        url['tag10'];
  }

  print(dynamicUrl(url,
      regNo: '17211085864',
      examType: 'Bachelor Degree (Honours) 3rd Year',
      examYear: '2022',
      rollNo: '1'));

  // Convert Map to UrlModel
  UrlModel urlModel = UrlModel.fromJson(url);
  print('UrlModel: ${urlModel.base}');

  // Convert UrlModel to JSON
  Map<String, dynamic> json = urlModel.toJson();
  print('JSON: ${jsonEncode(json)}');
}
