class TaskItem {
  String name;
  String description;
  bool isCompleted;
  int targetCount;
  int currentCount;
  bool isCustom;

  TaskItem({
    required this.name,
    required this.description,
    this.isCompleted = false,
    this.targetCount = 0,
    this.currentCount = 0,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'isCompleted': isCompleted,
        'targetCount': targetCount,
        'currentCount': currentCount,
        'isCustom': isCustom,
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      name: json['name'],
      description: json['description'],
      isCompleted: json['isCompleted'],
      targetCount: json['targetCount'] ?? 0,
      currentCount: json['currentCount'] ?? 0,
      isCustom: json['isCustom'] ?? false,
    );
  }
}
