import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

/// This widget displays a dropdown list of available currencies with their full names.
/// It uses the dropdown_button2 package for enhanced styling and functionality.
class CurrencyDropdown extends StatelessWidget {
  /// Currently selected currency code (e.g., "USD", "EUR")
  final String value;

  /// Map of currency codes to their full names (e.g., {"USD": "United States Dollar"})
  final Map<String, String> currencyNames;

  /// List of all available currency codes to display in the dropdown
  final List<String> currencies;

  /// Callback function triggered when user selects a different currency
  /// Receives the selected currency code as a nullable String parameter
  final Function(String?) onChanged;

  /// Whether to show the border around the dropdown button. Default true.
  final bool showBorder;

  const CurrencyDropdown({
    super.key,
    required this.value,
    required this.currencyNames,
    required this.currencies,
    required this.onChanged,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton2<String>(
      value: value,
      isExpanded: true, // Makes dropdown expand to fill available width

      // Configure the visible button/selection area styling
      buttonStyleData: ButtonStyleData(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height:
            48, // Fixed height for consistent sizing with other input fields
        decoration: BoxDecoration(
          color: const Color.fromARGB(
              255, 41, 41, 41), // Dark gray button background
          borderRadius: BorderRadius.circular(12), // Rounded corners
          // Optionally show a subtle border. When `showBorder` is false the
          // border is omitted to produce a cleaner, borderless appearance.
          border: showBorder ? Border.all(color: Colors.white24) : null,
        ),
      ),

      // Configure the dropdown menu (opened list) styling
      dropdownStyleData: DropdownStyleData(
        maxHeight: 500, // Limit dropdown height with scrolling if needed
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 30, 33, 36), // color theme
          borderRadius: BorderRadius.circular(8),
        ),
        isOverButton: false, // Menu appears below the button
      ),

      underline: const SizedBox(), // Remove default underline decoration

      // Configure the dropdown arrow icon appearance
      iconStyleData: const IconStyleData(
        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
      ),

      // Text styling for the selected item and dropdown items
      style: const TextStyle(color: Colors.white, fontSize: 16),

      // Build the list of dropdown menu items
      // Each item shows currency code followed by full name (e.g., "USD - United States Dollar")
      items: currencies.map((String currency) {
        return DropdownMenuItem<String>(
          value: currency,
          child: Text(
            "$currency - ${currencyNames[currency] ?? 'Unknown'}", // Show code and name
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),

      // Trigger callback when user selects a currency
      onChanged: onChanged,
    );
  }
}
