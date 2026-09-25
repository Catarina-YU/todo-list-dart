import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/category_dialog.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  Future<void> _openCategoryDialog([Category? category]) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => CategoryDialog(category: category),
    );

    if (name != null && mounted) {
      final categoryProvider = context.read<CategoryProvider>();
      if (category == null) {
        await categoryProvider.createCategory(Category(name: name));
      } else {
        await categoryProvider.updateCategory(category.copyWith(name: name));
      }
    }
  }

  Future<void> _confirmDelete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Text(
          'Deseja excluir a categoria "${category.name}"?\n\n'
          'As tarefas associadas a esta categoria não serão excluídas, mas ficarão sem categoria.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && category.id != null && mounted) {
      final taskProvider = context.read<TaskProvider>();
      await context.read<CategoryProvider>().deleteCategory(
        category.id!,
        onCategoryDeleted: taskProvider.onCategoryDeleted,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Categorias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nova Categoria',
            onPressed: () => _openCategoryDialog(),
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          if (categoryProvider.isLoading && categoryProvider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categoryProvider.errorMessage != null && categoryProvider.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro: ${categoryProvider.errorMessage}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => categoryProvider.loadCategories(),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (categoryProvider.categories.isEmpty) {
            return const Center(
              child: Text('Nenhuma categoria cadastrada.'),
            );
          }

          return ListView.builder(
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];
              return ListTile(
                title: Text(category.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _openCategoryDialog(category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(category),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCategoryDialog(),
        tooltip: 'Nova Categoria',
        child: const Icon(Icons.add),
      ),
    );
  }
}
