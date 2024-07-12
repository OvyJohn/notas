import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notes/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notas Sastre',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NotesHomePage(),
    );
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({Key? key}) : super(key: key);

  @override
  _NotesHomePageState createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  final String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medidas Sastre'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              showSearch(context: context, delegate: NotesSearchDelegate());
            },
          ),
        ],
      ),
      body: const NotesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNotePage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NotesList extends StatelessWidget {
  const NotesList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('Medidas').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No hay notas disponibles'));
        }
        var notes = snapshot.data!.docs;
        return ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            var note = notes[index];
            return NoteCard(
              name: note['name'],
              details: note['details'],
              medidas: note['medidas'],
              precio: note['precio'],
              createdAt: note['createdAt'],
              onDelete: () {
                deleteNote(note.id, context);
              },
            );
          },
        );
      },
    );
  }

  Future<void> deleteNote(String noteId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('Medidas').doc(noteId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota eliminada')),
      );
    } catch (e) {
      print('Error deleting note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la nota: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class NoteCard extends StatelessWidget {
  final String name;
  final String details;
  final String medidas;
  final String precio;
  final Timestamp createdAt;
  final VoidCallback onDelete;

  const NoteCard({
    Key? key,
    required this.name,
    required this.details,
    required this.medidas,
    required this.precio,
    required this.createdAt,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        children: [
          ListTile(
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(details),
                Text(medidas),
                Text('Precio: $precio'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ),
          const Divider(thickness: 1.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Creado el ${createdAt.toDate().toString()}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddNotePage extends StatefulWidget {
  const AddNotePage({Key? key}) : super(key: key);

  @override
  _AddNotePageState createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _medidasController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();

  void _saveNote() async {
    if (_nameController.text.isNotEmpty &&
        _detailsController.text.isNotEmpty &&
        _medidasController.text.isNotEmpty &&
        _precioController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('Medidas').add({
          'name': _nameController.text,
          'details': _detailsController.text,
          'medidas': _medidasController.text,
          'precio': _precioController.text,
          'createdAt': Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota guardada')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error saving note: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la nota: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Nota'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _detailsController,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: 'Detalles',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _medidasController,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: 'Medidas',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _saveNote,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class NotesSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text('Resultados para "$query"'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Buscar notas'),
    );
  }
}
