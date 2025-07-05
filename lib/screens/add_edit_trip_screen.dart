import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trip.dart';

class AddEditTripScreen extends StatefulWidget {
  final Trip? trip; // Se null, è una nuova aggiunta; altrimenti, è una modifica

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

  final List<String> _categories = ['Generale', 'Cultura', 'Natura', 'Relax', 'Avventura', 'Lavoro'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.trip?.title ?? '');
    _locationController = TextEditingController(text: widget.trip?.location ?? '');
    _descriptionController = TextEditingController(text: widget.trip?.description ?? '');
    _imageUrlsController = TextEditingController(text: widget.trip?.imageUrls.join(', ') ?? '');
    _startDate = widget.trip?.startDate ?? DateTime.now();
    _endDate = widget.trip?.endDate ?? DateTime.now().add(const Duration(days: 7));
    _isFavorite = widget.trip?.isFavorite ?? false;
    _toRepeat = widget.trip?.toRepeat ?? false;
    _selectedCategory = widget.trip?.category ?? _categories.first;

    // Assicurati che la categoria esista, altrimenti usa la prima
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = _categories.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _imageUrlsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isStartDate ? _startDate : _endDate)) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(days: 7)); // Assicura che la data di fine sia dopo l'inizio
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(days: 7)); // Assicura che la data di inizio sia prima della fine
          }
        }
      });
    }
  }

  void _saveTrip() {
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
          id: DateTime.now().millisecondsSinceEpoch.toString(), // ID univoco
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
        dummyTrips.add(newTrip);
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
        final index = dummyTrips.indexWhere((t) => t.id == updatedTrip.id);
        if (index != -1) {
          dummyTrips[index] = updatedTrip;
        }
        Navigator.pop(context, updatedTrip); // Ritorna il viaggio modificato
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip == null ? 'Aggiungi Nuovo Viaggio' : 'Modifica Viaggio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titolo del Viaggio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Località',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci una località';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data Inizio',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data Fine',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Note personali',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlsController,
                decoration: const InputDecoration(
                  labelText: 'URL Immagini (separate da virgola)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Preferito'),
                secondary: const Icon(Icons.star),
                value: _isFavorite,
                onChanged: (bool value) {
                  setState(() {
                    _isFavorite = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Da ripetere'),
                secondary: const Icon(Icons.repeat),
                value: _toRepeat,
                onChanged: (bool value) {
                  setState(() {
                    _toRepeat = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveTrip,
                icon: const Icon(Icons.save),
                label: Text(widget.trip == null ? 'Salva Viaggio' : 'Aggiorna Viaggio'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
