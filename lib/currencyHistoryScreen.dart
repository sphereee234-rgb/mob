import 'dart:async';
import 'package:flutter/material.dart';
import 'model/history_tracker.dart';
import 'package:intl/intl.dart';
import 'onlineCheck.dart';

// Screen that displays the historical exchange rates
// for a single currency.
// The `history` list is passed from the previous screen
// (usually read from the local database).

class CurrencyHistoryScreen extends StatefulWidget {
  // Currency code being displayed (e.g., USD, EUR)
  final String currency;

  // List of historical rate snapshots for this currency
  final List<HistoryTracker> history;

  const CurrencyHistoryScreen({
    super.key,
    required this.currency,
    required this.history,
  });

  @override
  State<CurrencyHistoryScreen> createState() => _CurrencyHistoryScreenState();
}

class _CurrencyHistoryScreenState extends State<CurrencyHistoryScreen> {
  // Tracks whether the app currently has internet access
  bool isOnline = true;

  // Used to indicate when an online check is in progress
  bool checking = false;

  @override
  void initState() {
    super.initState();

    // Run the online check after the first frame is rendered.
    // This avoids calling setState during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkOnline();
    });
  }

  Future<void> checkOnline() async {
    final online = await Onlinecheck.isOnline();

    // Ensure the widget is still mounted before updating state
    if (!mounted) return;

    // Update the UI based on online/offline status
    setState(() => isOnline = online);
  }

  @override
  Widget build(BuildContext context) {
    // Create a copy of the history list and sort it
    // so the most recent entries appear first.
    final sortedHistory = List.of(widget.history)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      // Dark background for the screen
      backgroundColor: const Color(0xFF292929),

      appBar: AppBar(
        // Title shows the selected currency and "History"
        title: Text('${widget.currency} History'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,

        // Online/offline indicator icon in the AppBar
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              // Cloud icon changes based on internet status
              isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: isOnline ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      ),

      // Allows pull-to-refresh even when the list is short
      body: RefreshIndicator(
        // Triggered when the user pulls down the list
        onRefresh: () async {
          if (mounted) setState(() => checking = true);

          // Re-check online status
          await checkOnline();

          if (mounted) setState(() => checking = false);
        },

        child: ListView.builder(
          // Ensures pull-to-refresh works even if list is small
          physics: const AlwaysScrollableScrollPhysics(),

          // Number of historical records
          itemCount: sortedHistory.length,

          itemBuilder: (context, index) {
            final item = sortedHistory[index];

            return ListTile(
              // Displays the exchange rate value
              title: Text(
                item.rate.toStringAsFixed(4),
                style: const TextStyle(
                  color: Colors.greenAccent,
                ),
              ),

              // Displays the date and time of the snapshot
              subtitle: Text(
                DateFormat('yyyy-MM-dd hh:mm a').format(item.date),
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
