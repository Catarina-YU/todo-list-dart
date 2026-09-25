import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_item_tile.dart';
import 'category_list_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  Widget _buildFilterBar(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<TaskStatusFilter>(
              value: taskProvider.statusFilter,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Status',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: TaskStatusFilter.all,
                  child: Text('Todas'),
                ),
                DropdownMenuItem(
                  value: TaskStatusFilter.pending,
                  child: Text('Pendentes'),
                ),
                DropdownMenuItem(
                  value: TaskStatusFilter.completed,
                  child: Text('Concluídas'),
                ),
              ],
              onChanged: (filter) {
                if (filter != null) {
                  taskProvider.setStatusFilter(filter);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: taskProvider.selectedCategoryId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todas categorias'),
                ),
                ...categoryProvider.categories.map((cat) {
                  return DropdownMenuItem<int?>(
                    value: cat.id,
                    child: Text(cat.name, overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: (categoryId) {
                taskProvider.setCategoryFilter(categoryId);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Categorias',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CategoryListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return Column(
            children: [
              _buildFilterBar(context),
              Expanded(
                child: _buildTaskListContent(context, taskProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TaskFormScreen(),
            ),
          );
        },
        tooltip: 'Nova Tarefa',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskListContent(BuildContext context, TaskProvider taskProvider) {
    if (taskProvider.isLoading && taskProvider.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (taskProvider.errorMessage != null && taskProvider.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erro ao carregar tarefas: ${taskProvider.errorMessage}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                taskProvider.loadTasks();
                context.read<CategoryProvider>().loadCategories();
              },
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (taskProvider.tasks.isEmpty) {
      final isFiltered = taskProvider.statusFilter != TaskStatusFilter.all ||
          taskProvider.selectedCategoryId != null;

      if (isFiltered && taskProvider.allTasks.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Nenhuma tarefa encontrada para os filtros selecionados.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => taskProvider.clearFilters(),
                child: const Text('Limpar Filtros'),
              ),
            ],
          ),
        );
      }

      return const Center(
        child: Text(
          'Nenhuma tarefa encontrada.\nClique no botão + para adicionar.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: taskProvider.tasks.length,
      itemBuilder: (context, index) {
        final task = taskProvider.tasks[index];
        return TaskItemTile(task: task);
      },
    );
  }
}
