import 'package:flutter/material.dart';
import 'sql.dart';
import 'currency.dart';
import 'package:uuid/uuid.dart';

// Define a list of available currencies.
const List<String> availableCurrencies = [
  'United States Dollar',
  'South Korean Won'
];

class UI extends StatefulWidget {
  const UI({super.key});

  @override
  State<UI> createState() => _UIState();
}

class _UIState extends State<UI> {
  // Drop-down values for filtering entries.
  final List<int> _timePeriods = [7, 30, 60, 365];
  int _selectedDays = 7;
  // Display currency selection.
  String _selectedCurrency = 'United States Dollar';

  // List to hold entries loaded from the database.
  List<Entry> _entries = [];

  // Total sum converted to the selected display currency.
  double _convertedSum = 0.0;
  // Conversion rate computed as (convertedSum / totalSum) to apply to individual rows.
  double _conversionRate = 1.0;

  // Future for the Database instance.
  late Future databaseFuture;

  @override
  void initState() {
    super.initState();
    databaseFuture = setupDatabase();
    // Once the database is ready, load entries.
    databaseFuture.then((_) {
      _fetchEntries();
    });
  }

  /// Returns a date string in the format "YYYY-MM-DD".
  String _formatDate(DateTime date) {
    return date.toIso8601String().substring(0, 10);
  }

  /// Fetch entries from the database for the selected date range.
  Future<void> _fetchEntries() async {
    final db = await databaseFuture;
    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(Duration(days: _selectedDays));
    // Use the same ISO date format.
    List<Entry> entries =
        await getEntryFromRange(db, _formatDate(startDate), _formatDate(now));
    setState(() {
      _entries = entries;
    });
    _updateConversion();
  }

  /// Computes the total sum (in USD, which is how entries are stored) from the loaded entries.
  double get _totalSum {
    return _entries.fold(0.0, (sum, entry) => sum + entry.price);
  }

  /// Update the conversion values for the main display and table.
  Future<void> _updateConversion() async {
    double totalUSD = _totalSum;
    if (_selectedCurrency == 'United States Dollar') {
      setState(() {
        _convertedSum = totalUSD;
        _conversionRate = 1.0;
      });
    } else {
      // Convert the total from USD to the selected display currency.
      double converted = await convert('United States Dollar', _selectedCurrency, totalUSD);
      setState(() {
        _convertedSum = converted;
        _conversionRate = (totalUSD != 0) ? converted / totalUSD : 1.0;
      });
    }
  }

  /// Delete an entry from the database using its id.
  Future<void> _deleteEntry(String id) async {
    final db = await databaseFuture;
    await deleteEntry(id, db);
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
          title: const Text("Pain Budgeter"),
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
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                      value: _selectedDays,
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedDays = newValue;
                          });
                          _fetchEntries();
                        }
                      },
                      items: _timePeriods.map<DropdownMenuItem<int>>((int days) {
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
                      value: _selectedCurrency,
                      onChanged: (String? newCurrency) {
                        if (newCurrency != null) {
                          setState(() {
                            _selectedCurrency = newCurrency;
                          });
                          _updateConversion();
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
        // Use a Builder so that Navigator context is correct.
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEntryScreen(databaseFuture: databaseFuture),
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

/// A dedicated screen with a form to add a new entry.
class AddEntryScreen extends StatefulWidget {
  final Future databaseFuture;

  const AddEntryScreen({Key? key, required this.databaseFuture}) : super(key: key);

  @override
  _AddEntryScreenState createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Currency selection for the entry.
  String _entryCurrency = 'United States Dollar';

  @override
  void dispose() {
    _dateController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Entry"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: "Date (YYYY-MM-DD)",
                  // Suffix icon to set today's date.
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.today),
                    onPressed: () {
                      _dateController.text = DateTime.now().toIso8601String().substring(0, 10);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a date";
                  }
                  // Optionally: add additional date format validation.
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a description";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a price";
                  }
                  if (double.tryParse(value) == null) {
                    return "Enter a valid number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Dropdown for the entry currency.
              DropdownButtonFormField<String>(
                value: _entryCurrency,
                onChanged: (String? newVal) {
                  if (newVal != null) {
                    setState(() {
                      _entryCurrency = newVal;
                    });
                  }
                },
                items: availableCurrencies.map<DropdownMenuItem<String>>((String curr) {
                  return DropdownMenuItem<String>(
                    value: curr,
                    child: Text(curr),
                  );
                }).toList(),
                decoration: const InputDecoration(labelText: "Entry Currency"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final String date = _dateController.text;
                    final String description = _descriptionController.text;
                    double enteredPrice = double.parse(_priceController.text);
                    double priceInUSD = enteredPrice;
                    // If the entry currency is not USD, convert the entered price to USD.
                    if (_entryCurrency != "United States Dollar") {
                      priceInUSD = await convert(_entryCurrency, "United States Dollar", enteredPrice);
                    }
                    final db = await widget.databaseFuture;
                    var uuid = Uuid();
                    Entry newEntry = Entry(
                      id: uuid.v4(),
                      date: date,
                      name: description,
                      price: priceInUSD,
                    );
                    await insertEntry(newEntry, db);
                    Navigator.pop(context, true); // Signal that a new entry was added.
                  }
                },
                child: const Text("Add Entry"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const UI());
}
