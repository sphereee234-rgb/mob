import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class CurrencyDropdown extends StatelessWidget {
  final String value;
  final Map<String, String> currencyNames;
  final List<String> currencies;
  final Function(String?) onChanged;

  const CurrencyDropdown({
    super.key,
    required this.value,
    required this.currencyNames,
    required this.currencies,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton2<String>(
      value: value,
      isExpanded: true,
      buttonStyleData: ButtonStyleData(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 48,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 41, 41, 41),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
      ),
      dropdownStyleData: DropdownStyleData(
        maxHeight: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF1d2630),
          borderRadius: BorderRadius.circular(8),
        ),
        isOverButton: false,
      ),
      underline: const SizedBox(),
      iconStyleData: const IconStyleData(
        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      items: currencies.map((String currency) {
        return DropdownMenuItem<String>(
          value: currency,
          child: Text(
            "$currency - ${currencyNames[currency] ?? 'Unknown'}",
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
