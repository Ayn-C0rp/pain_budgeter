
import 'package:flutter/material.dart';
import 'sql.dart';
import 'currency.dart';
import 'package:uuid/uuid.dart';





/// A dedicated screen with a form to add a new entry.
class AddEntryScreen extends StatefulWidget {
  final Future db;

  const AddEntryScreen({super.key, required this.db});

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
                decoration: const InputDecoration(labelText: "Choose Currency"),
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
                    final db = await widget.db;
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