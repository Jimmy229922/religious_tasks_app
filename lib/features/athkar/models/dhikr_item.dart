class DhikrItem {
  String text;
  String reward;
  int count;
  int current;
  final bool isOptional;
  final bool isCustom;

  DhikrItem({
    required this.text,
    required this.reward,
    required this.count,
    this.current = 0,
    this.isOptional = false,
    this.isCustom = false,
  });
}
