import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/trip.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _database = FirebaseDatabase.instance.ref();

  String title = '';
  String destination = '';
  int days = 1;
  double budget = 0;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Trip Title'),
                onSaved: (val) => title = val ?? '',
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Destination'),
                onSaved: (val) => destination = val ?? '',
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Days'),
                keyboardType: TextInputType.number,
                onSaved: (val) => days = int.tryParse(val ?? '1') ?? 1,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Budget (₱)'),
                keyboardType: TextInputType.number,
                onSaved: (val) => budget = double.tryParse(val ?? '0') ?? 0,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();

                          setState(() => _isSaving = true);

                          try {
                            // Create new trip object
                            final newTrip = Trip(
                              title: title,
                              destination: destination,
                              days: days,
                              budget: budget,
                            );

                            // Generate a unique key for the trip
                            final tripRef = _database.child('trips').push();

                            // Save to database
                            await tripRef.set({
                              'title': title,
                              'destination': destination,
                              'days': days,
                              'budget': budget,
                              'createdAt': DateTime.now().toIso8601String(),
                            });

                            if (!mounted) return;

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Trip saved successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Return the trip to the previous screen
                            Navigator.pop(context, newTrip);
                          } catch (e) {
                            if (!mounted) return;

                            setState(() => _isSaving = false);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save trip: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
