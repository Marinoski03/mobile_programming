class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Mappa per contare i viaggi per categoria
  Map<String, int> _categoryCounts = {};
  final TextEditingController _newCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateCategoryCounts();
  }

  void _updateCategoryCounts() {
    _categoryCounts = {};
    for (var trip in dummyTrips) {
      _categoryCounts.update(trip.category, (value) => value + 1, ifAbsent: () => 1);
    }
    setState(() {}); // Aggiorna l'UI
  }

  void _addNewCategory() {
    final newCategory = _newCategoryController.text.trim();
    if (newCategory.isNotEmpty && !_categoryCounts.containsKey(newCategory)) {
      setState(() {
        // Aggiungi la nuova categoria alla lista delle categorie disponibili in AddEditTripScreen
        // Questo è un esempio semplificato, in un'app reale avresti un servizio per gestire le categorie
        // Per ora, possiamo aggiungere una voce fittizia alla mappa dei conteggi per visualizzarla
        _categoryCounts[newCategory] = 0;
        _newCategoryController.clear();
      });
      Navigator.of(context).pop(); // Chiudi il dialogo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorie Viaggi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riepilogo per categoria:',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _categoryCounts.isEmpty
                ? const Center(child: Text('Nessuna categoria trovata.'))
                : Expanded(
                    child: ListView.builder(
                      itemCount: _categoryCounts.length,
                      itemBuilder: (context, index) {
                        final category = _categoryCounts.keys.elementAt(index);
                        final count = _categoryCounts[category];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: const Icon(Icons.folder_open),
                            title: Text(category),
                            trailing: Text('$count viaggi'),
                            onTap: () {
                              // Potresti navigare a una schermata di ricerca filtrata per questa categoria
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchScreen(initialCategory: category),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Aggiungi Nuova Categoria'),
                      content: TextField(
                        controller: _newCategoryController,
                        decoration: const InputDecoration(hintText: 'Nome categoria'),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Annulla'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Aggiungi'),
                          onPressed: _addNewCategory,
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Crea Nuova Categoria'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40), // Rende il pulsante più largo
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}