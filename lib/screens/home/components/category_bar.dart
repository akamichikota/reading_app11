import 'package:flutter/material.dart';

class CategoryBar extends StatelessWidget {
  final List<String> categories;
  final Function(String) onCategorySelected;
  final String? selectedCategory;

  CategoryBar({
    required this.categories,
    required this.onCategorySelected,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.0,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                onCategorySelected(category);
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.lightBlue[100],
              shape: StadiumBorder(
                side: BorderSide(
                  color: Colors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
