import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/category_provider.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  int? _selectedCategoryId;
  DateTime? _dueDateTime;
  bool _completed = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _selectedCategoryId = widget.task?.categoryId;
    _dueDateTime = widget.task?.dueDateTime;
    _completed = widget.task?.completed ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initialDate = _dueDateTime ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null || !mounted) return;

    final initialTime = TimeOfDay.fromDateTime(_dueDateTime ?? now);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _dueDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _clearDateTime() {
    setState(() {
      _dueDateTime = null;
    });
  }

  Future<void> _saveTask() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
    });

    final taskProvider = context.read<TaskProvider>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final descriptionValue = description.isEmpty ? null : description;

    try {
      if (widget.task == null) {
        final newTask = Task(
          title: title,
          description: descriptionValue,
          completed: _completed,
          createdAt: DateTime.now(),
          categoryId: _selectedCategoryId,
          dueDateTime: _dueDateTime,
        );
        await taskProvider.createTask(newTask);
      } else {
        final updatedTask = widget.task!.copyWith(
          title: title,
          description: descriptionValue,
          clearDescription: descriptionValue == null,
          completed: _completed,
          categoryId: _selectedCategoryId,
          clearCategoryId: _selectedCategoryId == null,
          dueDateTime: _dueDateTime,
          clearDueDateTime: _dueDateTime == null,
        );
        await taskProvider.updateTask(updatedTask);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar tarefa: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Tarefa' : 'Nova Tarefa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  hintText: 'Digite o título da tarefa',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o título da tarefa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Digite detalhes adicionais da tarefa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Sem categoria'),
                  ),
                  ...categoryProvider.categories.map((cat) {
                    return DropdownMenuItem<int?>(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.event),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Data e hora de vencimento',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _dueDateTime != null
                                  ? _formatDateTime(_dueDateTime!)
                                  : 'Nenhum vencimento definido',
                              style: TextStyle(
                                color: _dueDateTime != null ? Colors.black87 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_dueDateTime != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          tooltip: 'Remover Vencimento',
                          onPressed: _clearDateTime,
                        ),
                      TextButton(
                        onPressed: _pickDateTime,
                        child: Text(_dueDateTime == null ? 'Selecionar' : 'Alterar'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Concluída'),
                value: _completed,
                onChanged: (value) {
                  setState(() {
                    _completed = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Salvar Alterações' : 'Criar Tarefa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
