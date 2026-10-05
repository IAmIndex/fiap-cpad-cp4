import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../data/repositories/academya_repository.dart';
import '../../../data/models/publication.dart';
import '../../../shared/widgets/page_container.dart';
import '../../../shared/widgets/theme_mode_button.dart';

class CreatePublicationScreen extends StatefulWidget {
  const CreatePublicationScreen({required this.classId, super.key});

  final String classId;

  @override
  State<CreatePublicationScreen> createState() =>
      _CreatePublicationScreenState();
}

class _CreatePublicationScreenState extends State<CreatePublicationScreen> {
  static const _descriptionLimit = 900;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  PublicationType _selectedType = PublicationType.notice;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nova publicação',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [ThemeModeButton()],
      ),
      body: PageContainer(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  enabled: !_isSubmitting,
                  controller: _titleController,
                  maxLength: 50,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Título da publicação',
                    prefixIcon: Icon(Icons.title_rounded),
                    counterText: '',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Informe o título.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                FormField<String>(
                  initialValue: '',
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Informe a descrição.'
                      : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        children: [
                          TextField(
                            enabled: !_isSubmitting,
                            controller: _descriptionController,
                            maxLength: _descriptionLimit,
                            maxLines: 8,
                            minLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Descrição da publicação',
                              alignLabelWithHint: true,
                              counterText: '',
                              contentPadding: EdgeInsets.fromLTRB(
                                16,
                                18,
                                16,
                                44,
                              ),
                            ),
                            onChanged: (value) {
                              field.didChange(value);
                              setState(() {});
                            },
                          ),
                          Positioned(
                            right: 14,
                            bottom: 14,
                            child: Text(
                              '${_descriptionController.text.characters.length}/$_descriptionLimit',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Text(
                            field.errorText!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<PublicationType>(
                  initialValue: _selectedType,
                  isExpanded: true,
                  itemHeight: null,
                  decoration: const InputDecoration(
                    labelText: 'Tipo da publicação',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: PublicationType.creationOptions.map((type) {
                    return DropdownMenuItem<PublicationType>(
                      value: type,
                      child: Text(type.label),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (type) {
                          if (type != null) {
                            setState(() => _selectedType = type);
                          }
                        },
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Publicar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    final repository = AcademyaScope.repositoryOf(context);
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await repository.addPublication(
        classId: widget.classId,
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
      );

      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _error = AcademyaRepository.describeDataError(error));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
