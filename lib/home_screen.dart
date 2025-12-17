import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:global_currency_converter_and_tracker/tracker_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import 'currency_names.dart';
import 'widgets/dropdown_currecy.dart';
import 'onlineCheck.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // source currency
  String fromCurrency = "USD";
  // target currency
  String toCurrency = "PHP";
  // Current exchange rate
  double rate = 0.0;
  // conversion result
  double total = 0.0;
  // Controller for the amount input field
  TextEditingController amountController = TextEditingController();
  // List of available currencies fetched from API
  List<String> currencies = [];
  // online/offline status
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    // Load the list of currencies (and an initial rate) when the widget is created.
    // This populates the dropdowns and sets `isOnline` depending on the network.
    _getCurrencies();
  }

  // Fetch currencies
  Future<void> _getCurrencies() async {
    final online = await Onlinecheck.isOnline();
    if (!mounted) return;

    setState(() => isOnline = online);

    if (!online) {
      setState(() {
        if (currencies.isEmpty) currencies = [fromCurrency, toCurrency];
        if (rate == 0.0) rate = 1.0;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/PHP'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          currencies = (data['rates'] as Map<String, dynamic>).keys.toList();
          rate = (data['rates'][toCurrency] as num?)?.toDouble() ?? 1.0;
        });
      }
    } catch (e) {
      setState(() => isOnline = false);
    }
  }

  // Fetch exchange rate
  Future<void> _getRate() async {
    try {
      var response = await http.get(Uri.parse(
          'https://api.exchangerate-api.com/v4/latest/$fromCurrency'));
      if (response.statusCode == 200) {
        // Got a fresh rates payload for the selected `fromCurrency`.
        if (!isOnline) setState(() => isOnline = true);
        var data = jsonDecode(response.body);

        setState(() {
          // Update `rate` for conversion and recompute `total` if user entered amount.
          var raw = data['rates'][toCurrency];
          rate = raw is num ? raw.toDouble() : 1.0;
          if (amountController.text.isNotEmpty) {
            total = double.parse(amountController.text) * rate;
          }
        });
      } else {
        // HTTP error while fetching rate: keep offline indicator and fallback rate.
        if (isOnline) setState(() => isOnline = false);
        setState(() {
          if (rate == 0.0) rate = 1.0;
          if (amountController.text.isNotEmpty) {
            total = double.parse(amountController.text) * rate;
          }
        });
      }
    } catch (e) {
      // On exception (network/parsing), mark offline and keep using fallback rate.
      if (isOnline) setState(() => isOnline = false);
      setState(() {
        if (rate == 0.0) rate = 1.0;
        if (amountController.text.isNotEmpty) {
          total = double.parse(amountController.text) * rate;
        }
      });
      print("Failed to fetch rate: $e");
    }
  }

  // Swap currencies
  void _swapCurrencies() {
    setState(() {
      // Swap the two selected currency codes and refresh the exchange rate.
      String temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
      _getRate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 41, 41, 41),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text("Currency Converter"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Tooltip(
              message: isOnline ? 'Online' : 'Offline',
              child: Icon(
                isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: isOnline ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _getCurrencies,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Amount Input
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                // para 0-9 lang input
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]')),
                                ],
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Amount",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: Colors.white),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: Colors.white),
                                  ),
                                ),
                                // Recompute `total` live as the user types an amount.
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      total = double.parse(value) * rate;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // From Currency Dropdown
                      DropdownButtonHideUnderline(
                        child: CurrencyDropdown(
                          // Select the source currency; changing it triggers a new rate fetch.
                          value: fromCurrency,
                          currencies: currencies,
                          currencyNames: currencyNames,
                          onChanged: (newValue) {
                            setState(() {
                              fromCurrency = newValue!;
                              _getRate();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Swap Button - swaps `from` and `to` and refreshes rate
                      IconButton(
                        onPressed: _swapCurrencies,
                        icon: const Icon(Icons.swap_vert,
                            size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      // To Currency Dropdown - select the target currency
                      CurrencyDropdown(
                        value: toCurrency,
                        currencies: currencies,
                        currencyNames: currencyNames,
                        onChanged: (newValue) {
                          setState(() {
                            toCurrency = newValue!;
                            _getRate();
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      // Current Rate
                      Text(
                        "Rate ${rate.toStringAsFixed(2)}",
                        style:
                            const TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      // Converted Amount Display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 41, 41, 41),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Converted Amount',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              total.toStringAsFixed(2),
                              style: const TextStyle(
                                  color: Colors.greenAccent, fontSize: 40),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Button for next page
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CurrencyTracker()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 50, 50, 50),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  "Global Rates Tracker",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
