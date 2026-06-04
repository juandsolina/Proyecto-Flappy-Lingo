import 'package:flutter/material.dart';
import '../data/custom_vocabulary_repository.dart';
import '../models/custom_vocabulary_item_model.dart';

class VocabularyCrudScreen extends StatefulWidget {
  const VocabularyCrudScreen({super.key});

  @override
  State<VocabularyCrudScreen> createState() => _VocabularyCrudScreenState();
}

class _VocabularyCrudScreenState extends State<VocabularyCrudScreen> {
  final _repo = CustomVocabularyRepository();
  final List<String> _categories = const [
    'verbs',
    'animals',
    'travel',
    'food',
    'mixed'
  ];

  bool _loading = true;
  String _activeFilter = 'all';
  List<CustomVocabularyItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final result = await _repo.list(
      category: _activeFilter == 'all' ? null : _activeFilter,
    );
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result.success) {
        _items = result.data ?? [];
      }
    });

    if (!result.success) {
      _showSnack(result.message);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openForm({CustomVocabularyItem? item}) async {
    final createdOrUpdated = await showDialog<bool>(
      context: context,
      builder: (_) => _VocabularyFormDialog(
        categories: _categories,
        item: item,
        onSubmit: (payload) async {
          if (item == null) {
            return _repo.create(
              wordInSpanish: payload.wordInSpanish,
              correctAnswer: payload.correctAnswer,
              wrongAnswer: payload.wrongAnswer,
              category: payload.category,
            );
          }
          return _repo.update(
            id: item.id,
            wordInSpanish: payload.wordInSpanish,
            correctAnswer: payload.correctAnswer,
            wrongAnswer: payload.wrongAnswer,
            category: payload.category,
          );
        },
      ),
    );

    if (createdOrUpdated == true) {
      _loadItems();
    }
  }

  Future<void> _delete(CustomVocabularyItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar palabra'),
        content: Text('¿Eliminar "${item.wordInSpanish}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _repo.remove(item.id);
    if (!mounted) return;
    _showSnack(result.message);
    if (result.success) {
      _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD Vocabulario'),
        actions: [
          IconButton(
            onPressed: _loadItems,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        label: const Text('Agregar'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('Filtrar: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _activeFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('all')),
                    DropdownMenuItem(value: 'verbs', child: Text('verbs')),
                    DropdownMenuItem(value: 'animals', child: Text('animals')),
                    DropdownMenuItem(value: 'travel', child: Text('travel')),
                    DropdownMenuItem(value: 'food', child: Text('food')),
                    DropdownMenuItem(value: 'mixed', child: Text('mixed')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _activeFilter = value);
                    _loadItems();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(
                        child: Text('No hay vocabulario personalizado'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          return Card(
                            child: ListTile(
                              title: Text(item.wordInSpanish),
                              subtitle: Text(
                                '${item.correctAnswer} / ${item.wrongAnswer} · ${item.category}',
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: 'Editar',
                                    onPressed: () => _openForm(item: item),
                                    icon: const Icon(Icons.edit),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    onPressed: () => _delete(item),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemCount: _items.length,
                      ),
          ),
        ],
      ),
    );
  }
}

class _VocabularyFormData {
  final String wordInSpanish;
  final String correctAnswer;
  final String wrongAnswer;
  final String category;

  const _VocabularyFormData({
    required this.wordInSpanish,
    required this.correctAnswer,
    required this.wrongAnswer,
    required this.category,
  });
}

class _VocabularyFormDialog extends StatefulWidget {
  final CustomVocabularyItem? item;
  final List<String> categories;
  final Future<CrudResult<dynamic>> Function(_VocabularyFormData payload)
      onSubmit;

  const _VocabularyFormDialog({
    required this.item,
    required this.categories,
    required this.onSubmit,
  });

  @override
  State<_VocabularyFormDialog> createState() => _VocabularyFormDialogState();
}

class _VocabularyFormDialogState extends State<_VocabularyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _wordCtrl;
  late final TextEditingController _correctCtrl;
  late final TextEditingController _wrongCtrl;
  late String _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _wordCtrl = TextEditingController(text: widget.item?.wordInSpanish ?? '');
    _correctCtrl =
        TextEditingController(text: widget.item?.correctAnswer ?? '');
    _wrongCtrl = TextEditingController(text: widget.item?.wrongAnswer ?? '');
    _category = widget.item?.category ?? widget.categories.first;
  }

  @override
  void dispose() {
    _wordCtrl.dispose();
    _correctCtrl.dispose();
    _wrongCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final result = await widget.onSubmit(
      _VocabularyFormData(
        wordInSpanish: _wordCtrl.text.trim(),
        correctAnswer: _correctCtrl.text.trim(),
        wrongAnswer: _wrongCtrl.text.trim(),
        category: _category,
      ),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Agregar palabra' : 'Editar palabra'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _wordCtrl,
                decoration:
                    const InputDecoration(labelText: 'Palabra en español'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _correctCtrl,
                decoration:
                    const InputDecoration(labelText: 'Respuesta correcta'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _wrongCtrl,
                decoration:
                    const InputDecoration(labelText: 'Respuesta incorrecta'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (v.trim().toLowerCase() ==
                      _correctCtrl.text.trim().toLowerCase()) {
                    return 'Debe ser diferente de la correcta';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: widget.categories
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
