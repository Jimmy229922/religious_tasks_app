import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import 'package:religious_tasks_app/shared/services/updates/app_update_service.dart';

import 'package:religious_tasks_app/core/constants/strings.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';
import 'package:religious_tasks_app/shared/services/notifications/app_notification_service.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences_service.dart';

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
  double _downloadProgress = 0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefsService.load();
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      adhanSettings = Map.from(prefs.adhanEnabled);
      prayerOffsets = Map.from(prefs.prayerOffsets);
      _soundType = prefs.adhanSoundType;
      _appVersion = packageInfo.version;
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
    final tasksViewModel =
        Provider.of<TasksViewModel>(context, listen: false);
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

    // Refresh ViewModel to apply offsets immediately
    if (mounted) {
      final tasksViewModel = Provider.of<TasksViewModel>(context, listen: false);
      await tasksViewModel.refreshLocation(); // This will recalculate everything with new offsets
    }
    _reschedulePrayers();
  }

  void _checkUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
    });

    final updateInfo = await AppUpdateService.checkForUpdate();

    setState(() {
      _isCheckingUpdate = false;
    });

    if (updateInfo != null) {
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
      barrierDismissible: !_isDownloading,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("تحديث جديد متاح"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("إصدار: ${updateInfo['version']}+${updateInfo['buildNumber']}"),
                const SizedBox(height: 10),
                const Text("ما الجديد:"),
                Text(updateInfo['releaseNotes'] ?? "تحسينات عامة"),
                if (_isDownloading) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(value: _downloadProgress / 100),
                  const SizedBox(height: 8),
                  Center(child: Text("جاري التحميل: ${_downloadProgress.toInt()}%")),
                ],
              ],
            ),
            actions: [
              if (!_isDownloading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("لاحقاً"),
                ),
              if (!_isDownloading)
                ElevatedButton(
                  onPressed: () async {
                    setDialogState(() {
                      _isDownloading = true;
                    });
                    
                    AppUpdateService.downloadAndInstall(updateInfo['downloadUrl']).listen(
                      (event) {
                        setDialogState(() {
                          _downloadProgress = double.tryParse(event.value ?? "0") ?? 0;
                        });
                        if (event.status == OtaStatus.INSTALLING) {
                          if (context.mounted) Navigator.pop(context);
                          setState(() {
                            _isDownloading = false;
                            _downloadProgress = 0;
                          });
                        }
                      },
                      onError: (e) {
                        setDialogState(() {
                          _isDownloading = false;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("حدث خطأ أثناء التحديث: $e")),
                          );
                        }
                      },
                    );
                  },
                  child: const Text("تحديث الآن"),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final tasksViewModel = Provider.of<TasksViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Directionality(
              textDirection: TextDirection.rtl,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Section: Appearance
                  _buildSectionHeader("المظهر العام"),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text("نمط السمة", style: TextStyle(fontWeight: FontWeight.bold)),
                          leading: Icon(
                            themeProvider.appThemeMode == AppThemeMode.dark 
                              ? Icons.dark_mode 
                              : themeProvider.appThemeMode == AppThemeMode.light 
                                ? Icons.light_mode 
                                : Icons.auto_awesome, 
                            color: Colors.indigo
                          ),
                          trailing: DropdownButton<AppThemeMode>(
                            value: themeProvider.appThemeMode,
                            underline: const SizedBox(),
                            onChanged: (AppThemeMode? newValue) {
                              if (newValue != null) {
                                themeProvider.setThemeMode(newValue);
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: AppThemeMode.light, child: Text("فاتح")),
                              DropdownMenuItem(value: AppThemeMode.dark, child: Text("داكن")),
                              DropdownMenuItem(value: AppThemeMode.system, child: Text("تلقائي (النظام)")),
                              DropdownMenuItem(value: AppThemeMode.dynamic, child: Text("تفاعلي (مع الصلاة)")),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section: Location & Date
                  _buildSectionHeader("الموقع والتاريخ"),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: _isRefreshingLocation
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location,
                                  color: Colors.orange),
                          title: const Text("تحديث الموقع الحالي"),
                          subtitle: Text(tasksViewModel.locationName,
                              style: const TextStyle(fontSize: 12)),
                          onTap: _isRefreshingLocation
                              ? null
                              : () async {
                                  setState(() {
                                    _isRefreshingLocation = true;
                                  });

                                  // Artificial delay or actual process duration
                                  await tasksViewModel.refreshLocation();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text("تم تحديث الموقع بنجاح")));
                                    setState(() {
                                      _isRefreshingLocation = false;
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildSectionHeader("تنبيهات الأذان"),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("نوع صوت التنبيه:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<AdhanSoundType>(
                            initialValue: _soundType,
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
                  _buildSectionHeader("إشعارات الأذكار والدعاء"),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.notifications_active,
                          color: Colors.teal),
                      title: const Text("متابعة الإشعارات"),
                      subtitle: const Text(
                          "تفعيل أذكار الصباح والمساء والتذكير المتكرر بالأذكار والأدعية"),
                      trailing:
                          const Icon(Icons.arrow_forward_ios, size: 16),
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

                  // Section: Support
                  _buildSectionHeader("تواصل معنا"),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.email_outlined,
                              color: Colors.blue),
                          title: const Text("أرسل اقتراحاتك"),
                          subtitle: const Text("ahmed9ahmed779@gmail.com"),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                            final Uri emailUri = Uri(
                              scheme: 'mailto',
                              path: 'ahmed9ahmed779@gmail.com',
                              query: 'subject=اقتراح لتطبيق المهام الدينية',
                            );
                            try {
                              await launchUrl(emailUri);
                            } catch (e) {
                              // Ignore
                            }
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.chat_bubble_outline,
                              color: Colors.green),
                          title: const Text("تواصل عبر واتساب"),
                          subtitle: const Text("+201096304673"),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                            final Uri whatsappUri =
                                Uri.parse('https://wa.me/201096304673');
                            try {
                              await launchUrl(whatsappUri,
                                  mode: LaunchMode.externalApplication);
                            } catch (e) {
                              // Ignore
                            }
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
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                            final Uri url = Uri.parse(
                                'https://whatsapp.com/channel/0029VaNwp3YDzgT3fxWoGx2z');
                            if (!await launchUrl(url,
                                mode: LaunchMode.externalApplication)) {
                              if (context.mounted) {
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
                              const Icon(Icons.arrow_forward_ios, size: 16),
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
                          title: const Text("قيم التطبيق"),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Link to store
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section: About
                  _buildSectionHeader("عن التطبيق"),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info_outline, color: Colors.blueGrey),
                          title: const Text("إصدار تطبيق رفيق المسلم"),
                          trailing: Text(_appVersion, 
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: _isCheckingUpdate 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.system_update_rounded, color: Colors.blue),
                          title: const Text("التحقق من التحديثات"),
                          subtitle: const Text("تحميل وتثبيت أحدث نسخة تلقائياً"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _isCheckingUpdate ? null : _checkUpdate,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String key, String title) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("تعديل يدوي (بالدقائق):",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Row(
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
                ),
              ],
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
