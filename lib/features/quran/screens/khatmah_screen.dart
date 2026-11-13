import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:religious_tasks_app/features/quran/services/khatmah_planner_service.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';

class KhatmahScreen extends StatefulWidget {
  const KhatmahScreen({super.key});

  @override
  State<KhatmahScreen> createState() => _KhatmahScreenState();
}

class _KhatmahScreenState extends State<KhatmahScreen> {
  late TextEditingController _ayahController;
  Timer? _debounceTimer;
  late String _selectedSurah;
  KhatmahPlan? _plan;

  final List<String> _surahs = [
    "الفاتحة",
    "البقرة",
    "آل عمران",
    "النساء",
    "المائدة",
    "الأنعام",
    "الأعراف",
    "الأنفال",
    "التوبة",
    "يونس",
    "هود",
    "يوسف",
    "الرعد",
    "إبراهيم",
    "الحجر",
    "النحل",
    "الإسراء",
    "الكهف",
    "مريم",
    "طه",
    "الأنبياء",
    "الحج",
    "المؤمنون",
    "النور",
    "الفرقان",
    "الشعراء",
    "النمل",
    "القصص",
    "العنكبوت",
    "الروم",
    "لقمان",
    "السجدة",
    "الأحزاب",
    "سبأ",
    "فاطر",
    "يس",
    "الصافات",
    "ص",
    "الزمر",
    "غافر",
    "فصلت",
    "الشورى",
    "الزخرف",
    "الدخان",
    "الجاثية",
    "الأحقاف",
    "محمد",
    "الفتح",
    "الحجرات",
    "ق",
    "الذاريات",
    "الطور",
    "النجم",
    "القمر",
    "الرحمن",
    "الواقعة",
    "الحديد",
    "المجادلة",
    "الحشر",
    "الممتحنة",
    "الصف",
    "الجمعة",
    "المنافقون",
    "التغابن",
    "الطلاق",
    "التحريم",
    "الملك",
    "القلم",
    "الحاقة",
    "المعارج",
    "نوح",
    "الجن",
    "المزمل",
    "المدثر",
    "القيامة",
    "الإنسان",
    "المرسلات",
    "النبأ",
    "النازعات",
    "عبس",
    "التكوير",
    "الانفطار",
    "المطففين",
    "الانشقاق",
    "البروج",
    "الطارق",
    "الأعلى",
    "الغاشية",
    "الفجر",
    "البلد",
    "الشمس",
    "الليل",
    "الضحى",
    "الشرح",
    "التين",
    "العلق",
    "القدر",
    "البينة",
    "الزلزلة",
    "العاديات",
    "القارعة",
    "التكاثر",
    "العصر",
    "الهمزة",
    "الفيل",
    "قريش",
    "الماعون",
    "الكوثر",
    "الكافرون",
    "النصر",
    "المسد",
    "الإخلاص",
    "الفلق",
    "الناس"
  ];

  @override
  void initState() {
    super.initState();
    final vm = Provider.of<TasksViewModel>(context, listen: false);
    _selectedSurah = _surahs.contains(vm.lastSurah) ? vm.lastSurah : _surahs[0];
    _ayahController = TextEditingController(text: vm.lastAyah.toString());
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final plan = await KhatmahPlannerService.loadPlan();
    if (mounted) {
      setState(() {
        _plan = plan;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _ayahController.dispose();
    super.dispose();
  }

  void _onAyahChanged(String val, TasksViewModel vm) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final ayah = int.tryParse(val);
      if (ayah != null && mounted) {
        vm.updateQuranProgress(_selectedSurah, ayah);
      }
    });
  }

  void _saveProgress(TasksViewModel vm) {
    final ayah = int.tryParse(_ayahController.text) ?? 1;
    vm.updateQuranProgress(_selectedSurah, ayah);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم حفظ تقدم الختمة بنجاح"),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPlannerDialog() {
    double targetDays = (_plan?.targetDays ?? 30).toDouble();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dailyPages = (604 / targetDays).ceil();
          final pagesPerPrayer = (dailyPages / 5).ceil();

          return AlertDialog(
            title: const Text("المنظم الذكي لختمة القرآن 📜"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "حدد عدد الأيام التي تريد ختم القرآن الكريم فيها، وسيقوم التطبيق بحساب الورد اليومي التلقائي لك:",
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("مدة الختمة المطلوب:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        "${targetDays.toInt()} يوماً",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                            fontSize: 16),
                      ),
                    ],
                  ),

                  Slider(
                    value: targetDays,
                    min: 5,
                    max: 60,
                    divisions: 11,
                    activeColor: Colors.teal,
                    label: "${targetDays.toInt()} يوماً",
                    onChanged: (val) {
                      setDialogState(() {
                        targetDays = val;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_stories_rounded,
                                color: Colors.teal, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "الورد اليومي المطلوب: $dailyPages صفحة / يومياً",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.mosque_rounded,
                                color: Colors.teal, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "تقسيم الصلوات: $pagesPerPrayer صفحات بعد كل صلاة",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await KhatmahPlannerService.savePlan(targetDays.toInt());
                  await _loadPlan();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                          content: Text("تم حفظ خطة الختمة الذكية بنجاح 🎉")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text("اعتماد الخطة"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = Provider.of<TasksViewModel>(context, listen: false);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "متابع ومخطط الختمة",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: "المنظم الذكي للختمة",
            onPressed: _showPlannerDialog,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F2027), const Color(0xFF2C5364)]
                : [const Color(0xFFE0F7FA), const Color(0xFF80DEEA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Smart Khatmah Planner Banner Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded,
                                    color: Colors.amber, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  "خطة الختمة الذكية",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.teal.shade900,
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              onPressed: _showPlannerDialog,
                              icon: const Icon(Icons.edit_calendar_rounded,
                                  size: 16),
                              label: Text(
                                _plan == null ? "تحديد خطة" : "تعديل",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        if (_plan != null) ...[
                          const Divider(height: 20),
                          Text(
                            _plan!.getTodayRequirement(vm.lastAyah),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          const SizedBox(height: 10),
                          const Text(
                            "اضغط 'تحديد خطة' لتحديد مدة الختمة وحساب وردك اليومي تلقائياً",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Icon(
                  Icons.menu_book_rounded,
                  size: 70,
                  color: isDark ? Colors.amberAccent : Colors.teal,
                ),
                const SizedBox(height: 20),
                Text(
                  "أين وصلت في قراءتك؟",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // Dropdown for Surah
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.teal.withValues(alpha: 0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedSurah,
                      dropdownColor:
                          isDark ? const Color(0xFF2C3E50) : Colors.white,
                      items: _surahs
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSurah = val;
                          });
                          final ayah = int.tryParse(_ayahController.text) ?? 1;
                          vm.updateQuranProgress(val, ayah);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Input for Ayah
                TextField(
                  controller: _ayahController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: 'IBMPlexMono'),
                  decoration: InputDecoration(
                    labelText: "رقم الآية",
                    labelStyle: const TextStyle(color: Colors.teal),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) => _onAyahChanged(val, vm),
                  onSubmitted: (_) => _saveProgress(vm),
                ),

                const SizedBox(height: 24),

                // Save Button
                ElevatedButton.icon(
                  onPressed: () => _saveProgress(vm),
                  icon: const Icon(Icons.bookmark_added_rounded, color: Colors.white),
                  label: const Text(
                    "حفظ التقدم",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // Display Current Status
                const SizedBox(height: 24),
                Consumer<TasksViewModel>(
                  builder: (context, tasksVm, _) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              "آخر حفظ: سورة ${tasksVm.lastSurah} - آية ${tasksVm.lastAyah}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
