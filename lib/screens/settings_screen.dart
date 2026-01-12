import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/strings.dart';
import '../providers/theme_provider.dart';
import '../providers/tasks_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, bool> adhanSettings = {
    'fajr': true,
    'sunrise': true,
    'dhuhr': true,
    'asr': true,
    'maghrib': true,
    'isha': true,
  };

  bool _isLoading = true;
  bool _isRefreshingLocation = false;
  // int _hijriOffset = 0; // Removed

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      adhanSettings['fajr'] = prefs.getBool('adhan_enabled_fajr') ?? true;
      adhanSettings['sunrise'] = prefs.getBool('adhan_enabled_sunrise') ?? true;
      adhanSettings['dhuhr'] = prefs.getBool('adhan_enabled_dhuhr') ?? true;
      adhanSettings['asr'] = prefs.getBool('adhan_enabled_asr') ?? true;
      adhanSettings['maghrib'] = prefs.getBool('adhan_enabled_maghrib') ?? true;
      adhanSettings['isha'] = prefs.getBool('adhan_enabled_isha') ?? true;
      // _hijriOffset = prefs.getInt('hijri_offset') ?? 0; // Removed
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhan_enabled_$key', value);
    setState(() {
      adhanSettings[key] = value;
    });
  }

  // Offset method removed

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final tasksViewModel = Provider.of<TasksViewModel>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Section: Appearance
                  _buildSectionHeader("المظهر العام"),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: SwitchListTile(
                      title: const Text("الوضع الليلي",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      secondary: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          color: Colors.indigo),
                      value: isDark,
                      activeTrackColor: Colors.indigo,
                      onChanged: (val) {
                        themeProvider.toggleTheme(val);
                      },
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
                  const SizedBox(height: 8),
                  _buildSwitchTile('fajr', AppStrings.fajr),
                  _buildSwitchTile('sunrise', AppStrings.sunrise),
                  _buildSwitchTile('dhuhr', AppStrings.dhuhr),
                  _buildSwitchTile('asr', AppStrings.asr),
                  _buildSwitchTile('maghrib', AppStrings.maghrib),
                  _buildSwitchTile('isha', AppStrings.isha),

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
        style: GoogleFonts.cairo(
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
      child: SwitchListTile(
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
        secondary: Icon(
          Icons.mosque,
          color: adhanSettings[key] == true ? Colors.teal : Colors.grey,
        ),
        activeTrackColor: Colors.teal,
      ),
    );
  }
}
