import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:religious_tasks_app/core/constants/strings.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/services/backup_service.dart';
import 'package:religious_tasks_app/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';
import 'package:religious_tasks_app/shared/services/notifications/app_notification_service.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences_service.dart';
import 'package:religious_tasks_app/shared/services/updates/app_update_service.dart';
import 'package:religious_tasks_app/shared/services/updates/update_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationPreferencesService _prefsService =
      NotificationPreferencesService();

  Map<String, bool> adhanSettings = {
    'fajr': true,
    'sunrise': true,
    'dhuhr': true,
    'asr': true,
    'maghrib': true,
    'isha': true,
  };
  Map<String, int> prayerOffsets = {
    'fajr': 0,
    'sunrise': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };
  AdhanSoundType _soundType = AdhanSoundType.full;

  bool _isLoading = true;
  bool _isRefreshingLocation = false;
  String _appVersion = "";
  bool _isCheckingUpdate = false;

  String? _linkedGoogleEmail;
  String? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefsService.load();
    final packageInfo = await PackageInfo.fromPlatform();
    final email = await BackupService.getSavedGoogleAccount();
    final syncTime = await BackupService.getLastBackupFormattedTime();

    if (!mounted) return;

    setState(() {
      adhanSettings = Map.from(prefs.adhanEnabled);
      prayerOffsets = Map.from(prefs.prayerOffsets);
      _soundType = prefs.adhanSoundType;
      _appVersion = packageInfo.version;
      _linkedGoogleEmail = email;
      _lastSyncTime = syncTime;
      _isLoading = false;
    });
  }

  void _updateSoundType(AdhanSoundType type) async {
    setState(() {
      _soundType = type;
    });
    await _prefsService.setAdhanSoundType(type);
    _reschedulePrayers();
  }

  void _reschedulePrayers() async {
    final tasksViewModel = Provider.of<TasksViewModel>(context, listen: false);
    if (tasksViewModel.prayerTimes != null &&
        tasksViewModel.tomorrowPrayerTimes != null) {
      await AppNotificationService().schedulePrayerNotifications(
        today: tasksViewModel.prayerTimes!,
        tomorrow: tasksViewModel.tomorrowPrayerTimes!,
      );
    }
  }

  void _updateSetting(String key, bool value) async {
    setState(() {
      adhanSettings[key] = value;
    });

    await _prefsService.setAdhanEnabled(key, value);
    _reschedulePrayers();
  }

  void _updateOffset(String key, int value) async {
    setState(() {
      prayerOffsets[key] = value;
    });

    await _prefsService.setPrayerOffset(key, value);

    if (mounted) {
      final tasksViewModel =
          Provider.of<TasksViewModel>(context, listen: false);
      await tasksViewModel.refreshLocation();
    }
    _reschedulePrayers();
  }

  void _checkUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
    });

    final updateInfo = await AppUpdateService.checkForUpdate();
    if (!mounted) return;
    final updateVM = Provider.of<UpdateViewModel>(context, listen: false);

    setState(() {
      _isCheckingUpdate = false;
    });

    if (updateInfo != null) {
      updateVM.setUpdateInfo(updateInfo);
      if (!mounted) return;
      _showUpdateDialog(updateInfo);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("أنت تستخدم أحدث إصدار بالفعل")),
        );
      }
    }
  }

  void _showUpdateDialog(Map<String, dynamic> updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Consumer<UpdateViewModel>(
        builder: (context, vm, _) {
          return AlertDialog(
            title: const Text("تحديث جديد متاح"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "إصدار: ${updateInfo['version']}+${updateInfo['buildNumber']}"),
                  const SizedBox(height: 10),
                  const Text("ما الجديد:"),
                  Text(updateInfo['releaseNotes'] ?? "تحسينات عامة"),
                  if (vm.isDownloading) ...[
                    const SizedBox(height: 20),
                    LinearProgressIndicator(value: vm.downloadProgress / 100),
                    const SizedBox(height: 8),
                    Center(
                        child: Text(
                            "جاري التحميل في الخلفية: ${vm.downloadProgress.toInt()}%")),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("لاحقاً"),
              ),
              if (vm.isDownloadFinished)
                ElevatedButton(
                  onPressed: () => vm.startUpdate(),
                  child: const Text("تثبيت الآن"),
                )
              else if (!vm.isDownloading)
                ElevatedButton(
                  onPressed: () => vm.startUpdate(),
                  child: const Text("تحديث الآن"),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showRestoreDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("استعادة نسخة احتياطية"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("الصق نص النسخة الاحتياطية هنا لاستعادة كافة بياناتك:"),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "الصق البيانات هنا...",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              final success =
                  await BackupService.restoreBackupData(controller.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? "تمت استعادة البيانات بنجاح 🎉"
                        : "عذراً، نص النسخة الاحتياطية غير صالح"),
                  ),
                );
              }
            },
            child: const Text("استعادة"),
          ),
        ],
      ),
    );
  }

  void _showGoogleCloudBackupDialog() async {
    final currentEmail = await BackupService.getSavedGoogleAccount() ?? '';
    final controller = TextEditingController(text: currentEmail);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text("ربط واستعادة حساب الجيميل (Google) ☁️"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "اختر حساب الجيميل من هاتفك لربطه وتوثيقه ومزامنة كافة أوسمتك وإنجازاتك سحابياً:",
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 14),

                  // Native Google Account Picker
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final email =
                            await BackupService.selectGoogleAccount();
                        if (email != null && email.isNotEmpty) {
                          setDialogState(() {
                            controller.text = email;
                          });
                          await BackupService.saveGoogleAccount(email);
                          await _loadSettings();
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text("تم ربط الحساب ($email) بنجاح ✓"),
                              ),
                            );
                          }
                        } else {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text("يمكنك كتابة البريد الإلكتروني أدناه يدوياً"),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.account_circle_rounded,
                          color: Colors.white, size: 22),
                      label: const Text(
                        "اختيار حساب جوجل من الهاتف 👤",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "عنوان البريد الإلكتروني (Gmail)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.mark_email_read_rounded,
                          color: Colors.teal),
                      hintText: "example@gmail.com",
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
              ElevatedButton.icon(
                onPressed: () async {
                  final email = controller.text.trim();
                  if (email.isEmpty || !email.contains('@')) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                          content: Text("يرجى إدخال بريد إلكتروني صحيح")),
                    );
                    return;
                  }

                  final success = await BackupService.uploadToCloud(email);
                  await _loadSettings();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? "تم رفع ومزامنة البيانات بحساب ($email) بنجاح ☁️🎉"
                            : "حدثت مشكلة أثناء رفع البيانات السحابية"),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.cloud_upload_rounded,
                    color: Colors.white, size: 18),
                label: const Text("رفع ومزامنة"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final email = controller.text.trim();
                  if (email.isEmpty || !email.contains('@')) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                          content: Text("يرجى إدخال بريد إلكتروني صحيح")),
                    );
                    return;
                  }

                  final metadata =
                      await BackupService.getCloudBackupMetadata(email);
                  if (ctx.mounted) {
                    if (metadata == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                            content: Text(
                                "لم نجد أي نسخة احتياطية سحابية مسجلة بحساب ($email)")),
                      );
                      return;
                    }

                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        title: const Text("تأكيد استعادة النسخة السحابية"),
                        content: Text(
                          "وجدت نسخة احتياطية سحابية بتاريخ (${metadata['formattedDate']}).\nهل تريد استبدال بياناتك الحالية بهذه النسخة؟",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text("إلغاء"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(c, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal),
                            child: const Text("تأكيد الاستعادة"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && ctx.mounted) {
                      final success =
                          await BackupService.restoreFromCloud(email);
                      await _loadSettings();
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? "تم استرجاع بياناتك بنجاح من حساب ($email) ☁️🎉"
                                : "حدث خطأ أثناء استعادة النسخة الاحتياطية"),
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.cloud_download_rounded, size: 18),
                label: const Text("استعادة سحابية"),
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

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.settings),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.teal,
            labelColor: Colors.teal,
            unselectedLabelColor: isDark ? Colors.white60 : Colors.grey[700],
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(
                icon: Icon(Icons.mosque_rounded, size: 20),
                text: "الصلاة والمواقيت",
              ),
              Tab(
                icon: Icon(Icons.notifications_active_rounded, size: 20),
                text: "الأذكار والتنبيهات",
              ),
              Tab(
                icon: Icon(Icons.palette_rounded, size: 20),
                text: "المظهر والسمات",
              ),
              Tab(
                icon: Icon(Icons.cloud_sync_rounded, size: 20),
                text: "الحساب والمزامنة",
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Directionality(
                textDirection: TextDirection.rtl,
                child: TabBarView(
                  children: [
                    _buildPrayerTab(),
                    _buildAthkarTab(),
                    _buildThemeTab(),
                    _buildAccountTab(isDark),
                  ],
                ),
              ),
      ),
    );
  }

  // TAB 1: Prayer & Location
  Widget _buildPrayerTab() {
    final tasksViewModel = Provider.of<TasksViewModel>(context, listen: false);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader(Icons.my_location_rounded, "الموقع الجغرافي ومواقيت الصلاة"),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: _isRefreshingLocation
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location_rounded,
                    color: Colors.orange),
            title: const Text("تحديث الموقع الحالي"),
            subtitle: Text(tasksViewModel.locationName,
                style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.refresh_rounded, size: 20),
            onTap: _isRefreshingLocation
                ? null
                : () async {
                    setState(() {
                      _isRefreshingLocation = true;
                    });

                    await tasksViewModel.refreshLocation();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("تم تحديث الموقع بنجاح")));
                      setState(() {
                        _isRefreshingLocation = false;
                      });
                    }
                  },
          ),
        ),

        const SizedBox(height: 20),

        _buildSectionHeader(Icons.volume_up_rounded, "تنبيهات الأذان والتعديل اليدوي"),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("نوع صوت التنبيه:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<AdhanSoundType>(
                  initialValue: _soundType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: AdhanSoundType.full,
                      child: Text("أذان كامل (صوت المؤذن)"),
                    ),
                    DropdownMenuItem(
                      value: AdhanSoundType.short,
                      child: Text("تنبيه قصير"),
                    ),
                    DropdownMenuItem(
                      value: AdhanSoundType.none,
                      child: Text("صامت (إشعار فقط)"),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) _updateSoundType(val);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildSwitchTile('fajr', AppStrings.fajr),
        _buildSwitchTile('sunrise', AppStrings.sunrise),
        _buildSwitchTile('dhuhr', AppStrings.dhuhr),
        _buildSwitchTile('asr', AppStrings.asr),
        _buildSwitchTile('maghrib', AppStrings.maghrib),
        _buildSwitchTile('isha', AppStrings.isha),
        const SizedBox(height: 20),
      ],
    );
  }

  // TAB 2: Athkar & Notifications
  Widget _buildAthkarTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader(Icons.notifications_active_rounded, "إشعار ومتابعة الأذكار اليومية"),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const Icon(Icons.notifications_active_rounded,
                color: Colors.teal),
            title: const Text("متابعة الإشعارات وتخصيص المؤذن"),
            subtitle: const Text(
                "أذكار الصباح والمساء، الصلاة على النبي، الأذكار العائمة، والأذكار المخصصة"),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              ).then((_) => _loadSettings());
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // TAB 3: Appearance & Themes
  Widget _buildThemeTab() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader(Icons.palette_rounded, "المظهر العام والسمات"),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: const Text(
              "نمط السمة",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: Icon(
              themeProvider.appThemeMode == AppThemeMode.dark
                  ? Icons.dark_mode_rounded
                  : themeProvider.appThemeMode == AppThemeMode.light
                      ? Icons.light_mode_rounded
                      : Icons.auto_awesome_rounded,
              color: Colors.indigo,
            ),
            subtitle: DropdownButton<AppThemeMode>(
              value: themeProvider.appThemeMode,
              isExpanded: true,
              isDense: true,
              underline: const SizedBox(),
              onChanged: (AppThemeMode? newValue) {
                if (newValue != null) {
                  themeProvider.setThemeMode(newValue);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: AppThemeMode.light,
                  child: Text("فاتح ☀️"),
                ),
                DropdownMenuItem(
                  value: AppThemeMode.dark,
                  child: Text("داكن 🌙"),
                ),
                DropdownMenuItem(
                  value: AppThemeMode.system,
                  child: Text("تلقائي (النظام) 📱"),
                ),
                DropdownMenuItem(
                  value: AppThemeMode.dynamic,
                  child: Text("تفاعلي (مع الصلاة) 🕌"),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // TAB 4: Account, Sync, Support & Updates
  Widget _buildAccountTab(bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader(Icons.cloud_sync_rounded, "النسخ الاحتياطي والمزامنة السحابية ☁️"),
        _buildGoogleAccountCard(isDark),

        const SizedBox(height: 20),

        _buildSectionHeader(Icons.support_agent_rounded, "تواصل معنا والدعم"),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined,
                    color: Colors.blue),
                title: const Text("أرسل اقتراحاتك"),
                subtitle: const Text("ahmed9ahmed779@gmail.com"),
                trailing:
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'ahmed9ahmed779@gmail.com',
                    query: 'subject=اقتراح لتطبيق المهام الدينية',
                  );
                  try {
                    await launchUrl(emailUri);
                  } catch (_) {}
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded,
                    color: Colors.green),
                title: const Text("تواصل عبر واتساب"),
                subtitle: const Text("+201096304673"),
                trailing:
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () async {
                  final Uri whatsappUri =
                      Uri.parse('https://wa.me/201096304673');
                  try {
                    await launchUrl(whatsappUri,
                        mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.groups_2_rounded,
                    color: Colors.teal),
                title: const Text("قناة التطبيق علي واتساب"),
                subtitle:
                    const Text("تابع أحدث التحديثات والورد اليومي"),
                trailing:
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () async {
                  final Uri url = Uri.parse(
                      'https://whatsapp.com/channel/0029VaNwp3YDzgT3fxWoGx2z');
                  if (!await launchUrl(url,
                      mode: LaunchMode.externalApplication)) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "عذراً، لا يمكن فتح الرابط حالياً")));
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.share_rounded,
                    color: Colors.blueAccent),
                title: const Text("مشاركة التطبيق"),
                subtitle: const Text("الدال على الخير كفاعله"),
                trailing:
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          'السلام عليكم، أنصحك بتحميل هذا التطبيق الرائع للمهام الدينية والأذكار:\n\n'
                          'https://whatsapp.com/channel/0029VaNwp3YDzgT3fxWoGx2z\n\n'
                          'نسألكم الدعاء',
                      subject: 'تطبيق المهام الدينية',
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.star_rate_rounded,
                    color: Colors.amber),
                title: const Text("قيم تطبيق رفيق المسلم"),
                trailing:
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {},
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        _buildSectionHeader(Icons.info_outline_rounded, "عن التطبيق والتحديثات"),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded,
                    color: Colors.blueGrey),
                title: const Text("إصدار تطبيق رفيق المسلم"),
                trailing: Text(_appVersion,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: _isCheckingUpdate
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.system_update_rounded,
                        color: Colors.blue),
                title: const Text("التحقق من التحديثات"),
                subtitle:
                    const Text("تحميل وتثبيت أحدث نسخة تلقائياً"),
                trailing:
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: _isCheckingUpdate ? null : _checkUpdate,
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildGoogleAccountCard(bool isDark) {
    final bool isLinked = _linkedGoogleEmail != null && _linkedGoogleEmail!.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isLinked
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.teal.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLinked ? Icons.check_circle_rounded : Icons.mark_email_read_rounded,
                    color: isLinked ? Colors.green.shade700 : Colors.teal,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isLinked ? "مرتبط بحساب الجيميل" : "غير مرتبط بحساب",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isLinked
                                    ? (isDark ? Colors.greenAccent : Colors.green.shade900)
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ),
                          if (isLinked) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle,
                                size: 18, color: Colors.green),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLinked
                            ? _linkedGoogleEmail!
                            : "ربط حسابك لمزامنة الأوسمة والختمة محلياً وسحابياً",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isLinked && _lastSyncTime != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded,
                        size: 14, color: Colors.teal),
                    const SizedBox(width: 6),
                    Text(
                      "آخر مزامنة ناجحة: $_lastSyncTime",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (!isLinked) {
                        _showGoogleCloudBackupDialog();
                        return;
                      }
                      final success =
                          await BackupService.uploadToCloud(_linkedGoogleEmail!);
                      await _loadSettings();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? "تمت المزامنة ورفع البيانات بنجاح ☁️🎉"
                                : "حدث خطأ أثناء المزامنة السحابية"),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      isLinked ? Icons.cloud_upload_rounded : Icons.add_link_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      isLinked ? "رفع ومزامنة الآن" : "ربط حساب الجيميل",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (isLinked) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final metadata = await BackupService.getCloudBackupMetadata(
                          _linkedGoogleEmail!);
                      if (!mounted) return;

                      if (metadata == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("لم نجد أي نسخة احتياطية سحابية لهذا الحساب")),
                        );
                        return;
                      }

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("تأكيد استعادة النسخة السحابية"),
                          content: Text(
                            "وجدت نسخة احتياطية سحابية بتاريخ (${metadata['formattedDate']}).\nهل تريد استبدال بياناتك الحالية بهذه النسخة؟",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text("إلغاء"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(c, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal),
                              child: const Text("تأكيد الاستعادة"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        final success = await BackupService.restoreFromCloud(
                            _linkedGoogleEmail!);
                        await _loadSettings();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? "تم استرجاع بياناتك بنجاح من حساب الجيميل ☁️🎉"
                                  : "حدث خطأ أثناء استعادة النسخة"),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cloud_download_rounded, size: 18),
                    label: const Text("استعادة", style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: Icon(Icons.no_accounts_rounded, color: Colors.red.shade600),
                    tooltip: "إلغاء ربط الحساب",
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("تأكيد إلغاء ربط الحساب"),
                          content: Text(
                            "هل أنت تأكد من إلغاء ربط حساب الجيميل ($_linkedGoogleEmail)؟\n\nتنبيه: لن تُحذف بياناتك المحلية، لكن ستتوقف المزامنة السحابية لهذا الحساب.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("تراجع"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                              ),
                              child: const Text("إلغاء الربط",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        await BackupService.unlinkGoogleAccount();
                        await _loadSettings();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("تم إلغاء ربط الحساب بنجاح")),
                          );
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      await BackupService.shareBackupFile();
                    },
                    icon: const Icon(Icons.folder_zip_rounded, size: 18, color: Colors.blue),
                    label: const Text("تصدير ملف (جوجل درايف / الملفات 📁)",
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showRestoreDialog,
                  icon: const Icon(Icons.text_snippet_rounded, size: 18, color: Colors.amber),
                  label: const Text("نص 📝", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String key, String title) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              adhanSettings[key] == true ? "مفعل" : "معطل",
              style: TextStyle(
                color: adhanSettings[key] == true ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
            value: adhanSettings[key] ?? true,
            onChanged: (val) => _updateSetting(key, val),
            secondary: IconButton(
              icon: Icon(
                Icons.volume_up_rounded,
                color: adhanSettings[key] == true ? Colors.teal : Colors.grey,
              ),
              tooltip: "تجربة الصوت",
              onPressed: () {
                AppNotificationService().testAdhanNotification(key, title);
              },
            ),
            activeTrackColor: Colors.teal,
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 320;
                final offsetControls = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildOffsetButton(key, -1),
                    Container(
                      constraints: const BoxConstraints(minWidth: 40),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "${prayerOffsets[key] ?? 0}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ),
                    _buildOffsetButton(key, 1),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "تعديل يدوي (بالدقائق):",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: offsetControls,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "تعديل يدوي (بالدقائق):",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    offsetControls,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffsetButton(String key, int delta) {
    return InkWell(
      onTap: () {
        final current = prayerOffsets[key] ?? 0;
        _updateOffset(key, current + delta);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          delta > 0 ? Icons.add : Icons.remove,
          size: 16,
          color: Colors.teal,
        ),
      ),
    );
  }
}
