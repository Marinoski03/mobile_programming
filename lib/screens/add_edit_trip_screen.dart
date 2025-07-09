import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';

class AddEditTripScreen extends StatefulWidget {
  final Trip? trip;

  const AddEditTripScreen({super.key, this.trip});

  @override
  State<AddEditTripScreen> createState() => _AddEditTripScreenState();
}

class _AddEditTripScreenState extends State<AddEditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlsController;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isFavorite;
  late bool _toRepeat;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.trip?.title ?? '');
    _locationController = TextEditingController(
      text: widget.trip?.location ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.trip?.description ?? '',
    );
    _imageUrlsController = TextEditingController(
      text: widget.trip?.imageUrls.join(',') ?? '',
    );
    _startDate = widget.trip?.startDate ?? DateTime.now();
    _endDate = widget.trip?.endDate ?? DateTime.now();
    _isFavorite = widget.trip?.isFavorite ?? false;
    _toRepeat = widget.trip?.toRepeat ?? false;
    _selectedCategory = widget.trip?.category ?? 'Generale';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _imageUrlsController.dispose();
    super.dispose();
  }

  void _saveTrip() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final List<String> imageUrls = _imageUrlsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (widget.trip == null) {
        // Nuova aggiunta
        final newTrip = Trip(
          title: _titleController.text,
          location: _locationController.text,
          startDate: _startDate,
          endDate: _endDate,
          description: _descriptionController.text,
          imageUrls: imageUrls,
          isFavorite: _isFavorite,
          toRepeat: _toRepeat,
          category: _selectedCategory,
        );

        await TripDatabaseHelper.instance.insertTrip(newTrip);
        Navigator.pop(context, newTrip); // Ritorna il nuovo viaggio
      } else {
        // Modifica di un viaggio esistente
        final updatedTrip = widget.trip!.copyWith(
          title: _titleController.text,
          location: _locationController.text,
          startDate: _startDate,
          endDate: _endDate,
          description: _descriptionController.text,
          imageUrls: imageUrls,
          isFavorite: _isFavorite,
          toRepeat: _toRepeat,
          category: _selectedCategory,
        );

        await TripDatabaseHelper.instance.updateTrip(updatedTrip);
        Navigator.pop(context, updatedTrip); // Ritorna il viaggio modificato
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.trip == null ? 'Aggiungi Viaggio' : 'Modifica Viaggio',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titolo'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci un titolo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Località'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci una località';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _saveTrip, child: const Text('Salva')),
            ],
          ),
        ),
      ),
    );
  }
}
