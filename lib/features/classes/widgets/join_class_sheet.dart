import 'package:flutter/material.dart';

import '../../../data/models/school_class.dart';
import '../../../data/repositories/academya_repository.dart';
import '../../../shared/widgets/responsive_sheet.dart';

class JoinClassSheet extends StatefulWidget {
  const JoinClassSheet({
    required this.onJoin,
    required this.onCreate,
    super.key,
  });

  final Future<bool> Function(String code) onJoin;
  final Future<void> Function({
    required String name,
    required SchoolClassType type,
  })
  onCreate;

  @override
  State<JoinClassSheet> createState() => _JoinClassSheetState();
}

class _JoinClassSheetState extends State<JoinClassSheet> {
  final _joinFormKey = GlobalKey<FormState>();
  final _createFormKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  SchoolClassType _selectedType = SchoolClassType.classroom;
  bool _isCreating = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _isCreating ? _buildCreateForm(context) : _buildJoinForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinForm() {
    return Form(
      key: _joinFormKey,
      child: Column(
        key: const ValueKey('join-form'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Entrar em turma',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextFormField(
            enabled: !_busy,
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _joinClass(),
            decoration: const InputDecoration(
              labelText: 'Código da turma',
              prefixIcon: Icon(Icons.qr_code_2_rounded),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Informe o código.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _busy ? null : _joinClass,
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('Participar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _isCreating = true;
                    _error = null;
                  }),
            child: const Text('Criar turma'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm(BuildContext context) {
    return Form(
      key: _createFormKey,
      child: Column(
        key: const ValueKey('create-form'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Criar turma',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextFormField(
            enabled: !_busy,
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (value) {
              if ((value ?? '').trim().length < 3) {
                return 'Informe um nome com pelo menos 3 caracteres.';
              }

              return null;
            },
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) => SegmentedButton<SchoolClassType>(
              direction:
                  constraints.maxWidth < 420 ||
                      MediaQuery.textScalerOf(context).scale(14) > 18
                  ? Axis.vertical
                  : Axis.horizontal,
              segments: SchoolClassType.values
                  .map(
                    (type) => ButtonSegment<SchoolClassType>(
                      value: type,
                      label: Text(type.label),
                    ),
                  )
                  .toList(),
              selected: {_selectedType},
              onSelectionChanged: _busy
                  ? null
                  : (selection) {
                      setState(() => _selectedType = selection.first);
                    },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _busy ? null : _createClass,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Salvar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _isCreating = false;
                    _error = null;
                  }),
            child: const Text('Usar código'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinClass() async {
    if (_busy || !_joinFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final joined = await widget.onJoin(_codeController.text);
      if (mounted && joined) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _error = AcademyaRepository.describeDataError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createClass() async {
    if (_busy || !_createFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onCreate(name: _nameController.text, type: _selectedType);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _error = AcademyaRepository.describeDataError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
