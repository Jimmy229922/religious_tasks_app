class DhikrItem {
  String text;
  String reward;
  int count;
  int current;

  DhikrItem({
    required this.text,
    required this.reward,
    required this.count,
    this.current = 0,
  });
}
