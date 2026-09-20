import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/units.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import 'offline_map_page.dart';

/// 设置页：显示单位 / 记录默认值 / 数据 / 关于。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _types = ['公路', '山地', '通勤', '训练'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const <String, String>{};
    final u = ref.watch(unitPrefsProvider);
    final repo = ref.read(settingsRepositoryProvider);

    final defaultType = settings['default_ride_type'] ?? '公路';
    final autoPause = (settings['auto_pause'] ?? 'true') == 'true';
    final autoLap = (settings['auto_lap'] ?? 'false') == 'true';
    final voiceOn = (settings['voice_announce'] ?? 'false') == 'true';

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('显示单位'),
          Card(
            elevation: 0,
            shape: _cardShape,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<UnitSystem>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: UnitSystem.metric, label: Text('公制 km/m')),
                        ButtonSegment(value: UnitSystem.imperial, label: Text('英制 mi/ft')),
                      ],
                      selected: {u.system},
                      onSelectionChanged: (v) => repo.set(
                          UnitPrefs.keyUnitSystem,
                          v.first == UnitSystem.imperial ? 'imperial' : 'metric'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          _section('记录默认值'),
          Card(
            elevation: 0,
            shape: _cardShape,
            child: Column(
              children: [
                ListTile(
                  title: const Text('默认骑行类型', style: TextStyle(fontSize: 14)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        for (final t in _types)
                          ChoiceChip(
                            label: Text(t, style: const TextStyle(fontSize: 12)),
                            selected: defaultType == t,
                            onSelected: (_) => repo.set('default_ride_type', t),
                          ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('默认开启自动暂停', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('速度≈0 时自动暂停计时',
                      style: TextStyle(fontSize: 11, color: AppTheme.txt3)),
                  value: autoPause,
                  onChanged: (v) => repo.set('auto_pause', '$v'),
                ),
                SwitchListTile(
                  title: const Text('默认开启自动计圈（5km）',
                      style: TextStyle(fontSize: 14)),
                  value: autoLap,
                  onChanged: (v) => repo.set('auto_lap', '$v'),
                ),
                SwitchListTile(
                  title: const Text('语音播报（每公里）', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('骑行中每满 1 公里播报距离/用时/均速，结束时总结',
                      style: TextStyle(fontSize: 11, color: AppTheme.txt3)),
                  value: voiceOn,
                  onChanged: (v) => repo.set('voice_announce', '$v'),
                ),
              ],
            ),
          ),

          _section('地图与离线'),
          Card(
            elevation: 0,
            shape: _cardShape,
            child: ListTile(
              leading: const Icon(Icons.download_for_offline_outlined, size: 20),
              title: const Text('离线地图', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                '下载城市地图包，无网络时也能查看路网（由高德 SDK 提供）',
                style: TextStyle(fontSize: 11.5, color: AppTheme.txt3),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OfflineMapPage()),
              ),
            ),
          ),

          _section('后台记录'),
          Card(
            elevation: 0,
            shape: _cardShape,
            child: const Column(
              children: [
                ListTile(
                  title: Text('锁屏 / 切后台继续记录', style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    '记录开始时系统会显示"跋涉 · 正在记录骑行"常驻通知（Android 前台服务）。'
                    '请勿在通知栏手动划掉它，否则记录可能中断。',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.txt3),
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('省电优化提示', style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    '部分手机会限制后台定位：请在 系统设置 → 电池 → 应用启动管理 中，'
                    '把"跋涉"设为"允许后台活动/不优化"。',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.txt3),
                  ),
                ),
              ],
            ),
          ),

          _section('数据'),
          Card(
            elevation: 0,
            shape: _cardShape,
            child: FutureBuilder<Map<String, int>>(
              future: repo.counts(),
              builder: (context, snap) {
                final c = snap.data;
                return Column(
                  children: [
                    ListTile(
                      title: const Text('本地数据', style: TextStyle(fontSize: 14)),
                      subtitle: Text(
                        c == null
                            ? '统计中…'
                            : '活动 ${c['activities']} 条 · 轨迹点 ${c['tracks']} 个 · 路线 ${c['routes']} 条',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.txt3),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('清空未完成草稿', style: TextStyle(fontSize: 14)),
                      subtitle: const Text('仅删除草稿，已保存的骑行不受影响',
                          style: TextStyle(fontSize: 11, color: AppTheme.txt3)),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.txt3),
                      onTap: () async {
                        await repo.clearDrafts();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已清空草稿')));
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('清除全部本地数据',
                          style: TextStyle(fontSize: 14, color: AppTheme.warn)),
                      subtitle: const Text('删除所有活动、轨迹、路线与草稿，不可恢复',
                          style: TextStyle(fontSize: 11, color: AppTheme.txt3)),
                      onTap: () => _confirmClearAll(context, ref),
                    ),
                  ],
                );
              },
            ),
          ),

          _section('关于'),
          Card(
            elevation: 0,
            shape: _cardShape,
            child: const Column(
              children: [
                ListTile(
                  title: Text('跋涉', style: TextStyle(fontSize: 14)),
                  subtitle: Text('版本 0.1.0 · M1（记录 / 统计 / 地图路线）',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('数据存储', style: TextStyle(fontSize: 14)),
                  subtitle: Text('全部数据保存在本机（SQLite），无需登录、不上传',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('地图与路线规划', style: TextStyle(fontSize: 14)),
                  subtitle: Text('地图由高德提供；骑行路线规划使用高德骑行路径规划',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('清除全部本地数据？'),
        content: const Text('将删除所有骑行活动、轨迹点、路线与草稿，且不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.warn),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(settingsRepositoryProvider).clearAll();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清除全部本地数据')));
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6, left: 2),
        child: Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.txt2)),
      );

  static final _cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: const BorderSide(color: AppTheme.line),
  );
}
