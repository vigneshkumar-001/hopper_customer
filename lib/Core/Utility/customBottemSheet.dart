import 'package:flutter/material.dart';
import 'package:hopper/Core/Consents/app_colors.dart';

class CustomBottomSheet {
  static void showOptionsBottomSheet({
    required BuildContext context,
    required TextEditingController controller,
    required String title,
    required List<String> options,
  }) {
    TextEditingController searchController = TextEditingController();
    List<String> filteredOptions = List.from(options);
    FocusNode searchFocusNode = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setState) {
                // Set focus after the widget builds
                Future.delayed(Duration(milliseconds: 300), () {
                  if (!searchFocusNode.hasFocus) {
                    searchFocusNode.requestFocus();
                  }
                });

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '$title',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        cursorColor: AppColors.commonBlack,
                        focusNode: searchFocusNode,
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: Icon(Icons.search),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          border: OutlineInputBorder(), // fallback
                        ),
                        onChanged: (query) {
                          setState(() {
                            filteredOptions =
                                options
                                    .where(
                                      (option) => option.toLowerCase().contains(
                                    query.toLowerCase(),
                                  ),
                                )
                                    .toList();
                          });
                        },
                      ),

                      const SizedBox(height: 16),
                      Expanded(
                        child:
                        filteredOptions.isEmpty
                            ? const Center(child: Text('No results found'))
                            : ListView.builder(
                          controller: scrollController,
                          itemCount: filteredOptions.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(filteredOptions[index]),
                              onTap: () {
                                controller.text =
                                filteredOptions[index];
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}