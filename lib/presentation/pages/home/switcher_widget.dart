import 'package:flutter/material.dart';
import 'package:campus_saga/presentation/pages/home/switch_campus_page.dart';

class SwitcherWidget extends StatefulWidget {
  @override
  _SwitcherWidgetState createState() => _SwitcherWidgetState();
}

class _SwitcherWidgetState extends State<SwitcherWidget> {
  final List<String> universities = [
    'North South University @nsu',
    'Daffodil International University @diu',
    'American International University-Bangladesh @aiub',
    'East West University @ewu',
    'Independent University, Bangladesh @iub',
    'United International University @uiu',
    'BRAC University @bracu',
    'Bangladesh University of Professionals @bup',
  ];

  String? selectedUniversity;
  String? universityId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select University'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text('Select University'),
                value: selectedUniversity,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedUniversity = newValue;
                    // Properly extract universityId from the selected value
                    universityId = newValue?.split('@').last;
                  });
                },
                items:
                    universities.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: selectedUniversity == null || universityId == null
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SwitchCampusPage(
                          universityId: universityId!.toUpperCase()),
                    ),
                  );
                },
          child: Text('Visit Campus'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}

// Function to show the SwitcherWidget as a popup
void showSwitcherWidget(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SwitcherWidget();
    },
  );
}
