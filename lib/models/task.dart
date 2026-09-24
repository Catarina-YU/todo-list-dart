class Task {
  final int? id;
  final String title;
  final String? description;
  final bool completed;
  final DateTime? dueDateTime;
  final DateTime createdAt;
  final int? categoryId;

  const Task({
    this.id,
    required this.title,
    this.description,
    this.completed = false,
    this.dueDateTime,
    required this.createdAt,
    this.categoryId,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    bool? completed,
    DateTime? dueDateTime,
    DateTime? createdAt,
    int? categoryId,
    bool clearDescription = false,
    bool clearDueDateTime = false,
    bool clearCategoryId = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      completed: completed ?? this.completed,
      dueDateTime: clearDueDateTime ? null : (dueDateTime ?? this.dueDateTime),
      createdAt: createdAt ?? this.createdAt,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          completed == other.completed &&
          dueDateTime == other.dueDateTime &&
          createdAt == other.createdAt &&
          categoryId == other.categoryId;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      completed.hashCode ^
      dueDateTime.hashCode ^
      createdAt.hashCode ^
      categoryId.hashCode;

  @override
  String toString() =>
      'Task(id: $id, title: $title, description: $description, completed: $completed, dueDateTime: $dueDateTime, createdAt: $createdAt, categoryId: $categoryId)';
}
