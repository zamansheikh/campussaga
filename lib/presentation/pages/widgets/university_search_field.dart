// lib/presentation/widgets/university_search_field.dart

import 'package:flutter/material.dart';
import 'package:searchfield/searchfield.dart';

class UniversitySearchField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> universityList;
  final String? Function(String?)? validator;

  const UniversitySearchField({
    Key? key,
    required this.controller,
    required this.universityList,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchField(
          validator: validator,
          maxSuggestionsInViewPort: 5,
          controller: controller,
          suggestions: universityList
              .map((university) => SearchFieldListItem(university))
              .toList(),
          searchInputDecoration: SearchInputDecoration(
            prefixIcon: Icon(
              Icons.school,
              size: 20,
            ),
            hintText: "Search University",
          ),
          onSuggestionTap: (suggestion) {
            controller.text = suggestion.searchKey;
            // Dismiss the dropdown by removing focus from the search field
            FocusScope.of(context).unfocus();
            // Triggering a re-build for the validator to re-evaluate
            (context as Element).markNeedsBuild();
          },
        ),
        if (validator != null)
          Builder(
            builder: (context) {
              final errorText = validator!(controller.text);
              return errorText != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        errorText,
                        style: TextStyle(fontSize: 12),
                      ),
                    )
                  : SizedBox.shrink();
            },
          ),
      ],
    );
  }
}
