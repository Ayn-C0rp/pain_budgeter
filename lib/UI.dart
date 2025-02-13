import 'dart:ui';
import 'package:flutter/material.dart';
import 'sql.dart';
import 'currency.dart';
import 'helper.dart';
import 'EntryScreen.dart';

class UI extends StatefulWidget {
  const UI({super.key});
  @override
  State<UI> createState() => _UIState();
}

class _UIState extends State<UI> {
  // Drop-down values for filtering entries.
  final List<int> timePeriods = [7, 30, 60, 365];
  int numberDays = 7;
  // Display currency selection.
  String selectedCurrency = 'United States Dollar';
  // List to hold entries loaded from the database.
  List<Entry> _entries = [];
  // Total sum converted to the selected display currency.
  double _convertedSum = 0.0;
  // Conversion rate computed as (convertedSum / totalSum) to apply to individual rows.
  double _conversionRate = 1.0;
  // Future for the Database instance.
  late Future db;

  @override
  void initState() {
    super.initState();
    db = setupDatabase();
    db.then((_) {_fetchEntries();});
  }


  /// Fetch entries from the database for the selected date range.
  Future _fetchEntries() async {
    final dbInstance = await db;
    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(Duration(days: numberDays));     
    var entries = await getEntryFromRange(dbInstance, formatDate(startDate), formatDate(now));
    setState(() {
      _entries = entries;
    });
    updateConversion();
  }

  /// Computes the total sum (in USD, which is how entries are stored) from the loaded entries.
  double get _totalSum {
    return _entries.fold(0.0, (sum, entry) => sum + entry.price);
  }

  /// Update the conversion values for the main display and table.
  Future<void> updateConversion() async {
    double totalUSD = _totalSum;
    if (selectedCurrency == 'United States Dollar') {
      setState(() {
        _convertedSum = totalUSD;
        _conversionRate = 1.0;
      });
    } else {
      // Convert the total from USD to the selected display currency.
      double converted = await convert('United States Dollar', selectedCurrency, totalUSD);
      setState(() {
        _convertedSum = converted;
        _conversionRate = (totalUSD != 0) ? converted / totalUSD : 1.0;
      });
    }
  }

  /// Delete an entry from the database using its id.
  Future<void> _deleteEntry(String id) async {
    final dbInstance = await db;
    await deleteEntry(id, dbInstance);
    _fetchEntries();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pain Budgeter',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 167, 204, 125),
          title: const Text("Pain Budgeter", style: TextStyle.new(color: Colors.white, fontWeight: FontWeight.bold),),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Sum display box aligned to the right.
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Sum: ${_convertedSum.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Row with two drop-down menus: time period and display currency.
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: numberDays,
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            numberDays = newValue;
                          });
                          _fetchEntries();
                        }
                      },
                      items: timePeriods.map<DropdownMenuItem<int>>((int days) {
                        return DropdownMenuItem<int>(
                          value: days,
                          child: Text("$days days"),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCurrency,
                      onChanged: (String? newCurrency) {
                        if (newCurrency != null) {
                          setState(() {
                            selectedCurrency = newCurrency;
                          });
                          updateConversion();
                        }
                      },
                      items: availableCurrencies.map<DropdownMenuItem<String>>((String currency) {
                        return DropdownMenuItem<String>(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Table with entries (prices are converted for display).
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Date")),
                      DataColumn(label: Text("Description")),
                      DataColumn(label: Text("Price")),
                      DataColumn(label: Text("Actions")),
                    ],
                    rows: _entries.map((entry) {
                      double displayPrice = entry.price * _conversionRate;
                      return DataRow(
                        cells: [
                          DataCell(Text(entry.date)),
                          DataCell(Text(entry.name)),
                          DataCell(Text(displayPrice.toStringAsFixed(2))),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteEntry(entry.id),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEntryScreen(db: db),
                  ),
                );
                if (result == true) {
                  _fetchEntries();
                }
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }
}



void main() {
  runApp(const UI());
}
