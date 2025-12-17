import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'database.dart';
import 'model/history_tracker.dart';
import 'currency_names.dart';
import 'currencyHistoryScreen.dart';
import 'onlineCheck.dart';
import 'widgets/dropdown_currecy.dart';

// Shows a history of exchange rates (relative to a selected base
// currency), caches new data into a local database, and allows viewing
// historical rates for a selected currency.
//
// the tracker checks network connectivity and attempts to
// fetch the latest rates from a public API
// When the API returns, the raw rates map is stored in `allRates` and
// converted to rates expressed relative to `selectedBase` using
// `convertRatesToBase`.
// During conversion the app writes new snapshots into the local DB only
// when the latest saved rate differs by more than a small threshold.
// If the API fails the app marks itself offline and stops loading
// Historical data remains available and can be viewed ondemand by tapping a currency.

class CurrencyTracker extends StatefulWidget {
  const CurrencyTracker({super.key});

  @override
  _CurrencyTrackerState createState() => _CurrencyTrackerState();
}

class _CurrencyTrackerState extends State<CurrencyTracker> {
  // List currently displayed rates
  List<HistoryTracker> currentTrackerRates = [];
  // Loading indicator for async operations
  bool loading = true;

  // Online/offline flag (used to show wifi icon and decide whether to fetch)
  bool isOnline = true;

  // Currently selected base currency (rates are shown relative to this)
  String selectedBase = 'PHP';

  // Available currency codes (populated from API or DB)
  List<String> currencies = [];

  // Helper to access the local SQLite-like database (see database.dart)
  final dbHelper = DatabaseHelper();

  // Raw rates keyed by currency code (originally from USD-based API)
  Map<String, double> allRates = {};

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback so the widget is fully mounted before
    // performing async work (prevents setState called during build errors).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkOnline();
      await fetchAllRates();
    });
  }

  Future<void> checkOnline() async {
    final online = await Onlinecheck.isOnline();
    if (!mounted) return;

    // Update the connectivity flag used for the status icon. if ofline o online
    setState(() => isOnline = online);
  }

  Future<void> fetchAllRates() async {
    setState(() => loading = true);

    try {
      final response = await http
          .get(Uri.parse('https://api.exchangerate-api.com/v4/latest/PHP'));

      if (response.statusCode != 200) throw Exception('API failed');

      final data = jsonDecode(response.body);
      final rates = Map<String, double>.from((data['rates'] as Map)
          .map((k, v) => MapEntry(k, (v as num).toDouble())));

      allRates = rates;
      currencies = rates.keys.toList()..sort();

      convertRatesToBase(selectedBase);
    } catch (e) {
      print('API failed: $e');
      if (!mounted) return;
      setState(() {
        isOnline = false; // used only for status icon and small behavior hints
        loading = false; // stop showing the spinner; keep current UI state
      });
    }
  }

  void convertRatesToBase(String base) {
    if (!allRates.containsKey(base)) {
      print('Selected base $base not found');
      setState(() => loading = false);
      return;
    }

    double baseRate = allRates[base]!;
    DateTime now = DateTime.now();

    List<HistoryTracker> tempRates = [];
    List<Future> dbTasks = [];

    allRates.forEach((currency, rateInPHP) {
      // Convert raw rate (price of 1 <currency> in API anchor) into a value
      // relative to the chosen `base`. Example: if API returned prices in PHP
      // then rateInPHP / baseRate yields price of 1 <currency> in `base`.
      double rate = rateInPHP / baseRate;

      // Create a object capturing the rate and timestamp.
      final rateEntry = HistoryTracker(
        currency: currency,
        rate: rate,
        date: now,
        baseCurrency: base,
      );
      tempRates.add(rateEntry);

      // Queue a DB task to store the meaningfull rate changes
      dbTasks.add(Future(() async {
        final latestSavedRate = await dbHelper.getLatestRate(base, currency);
        final shouldInsert = latestSavedRate == null ||
            (rate - latestSavedRate.rate).abs() > 0.00001;
        if (shouldInsert) {
          await dbHelper.insertRate(rateEntry);
        }
      }));
    });

    // Wait for DB writes to finish (insert only when value changed), then
    // update UI with the list sorted by currency code.
    Future.wait(dbTasks).then((_) {
      tempRates.sort((a, b) => a.currency.compareTo(b.currency));
      if (!mounted) return;
      setState(() {
        currentTrackerRates = tempRates;
        selectedBase = base;
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF292929),
      appBar: AppBar(
        title: const Text('Global Rate Tracker'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: isOnline ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text('Base:',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CurrencyDropdown(
                          value: selectedBase,
                          currencies: currencies,
                          currencyNames: currencyNames,
                          showBorder: false,
                          onChanged: (newValue) {
                            if (newValue != null && newValue != selectedBase) {
                              setState(() => loading = true);
                              convertRatesToBase(newValue);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      // Pull-to-refresh: re-check connectivity then fetch fresh rates
                      await checkOnline();
                      await fetchAllRates();
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: currentTrackerRates.length,
                      itemBuilder: (context, index) {
                        final item = currentTrackerRates[index];
                        // Each ListTile shows currency code, current rate and
                        // the timestamp. Tapping pushes `CurrencyHistoryScreen`.
                        return ListTile(
                          title: Text(
                              "${item.currency} - ${currencyNames[item.currency] ?? 'Unknown'}",
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                              'Rate: ${item.rate.toStringAsFixed(4)}',
                              style: const TextStyle(color: Colors.white70)),
                          onTap: () async {
                            final history = await dbHelper.getCurrencyHistory(
                                item.currency, item.baseCurrency);
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CurrencyHistoryScreen(
                                  currency: item.currency,
                                  history: history,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
