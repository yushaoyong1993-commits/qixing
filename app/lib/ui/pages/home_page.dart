import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/periods.dart';
import '../../data/providers.dart';
import '../../domain/stats/aggregate.dart' as k;
import '../../theme/app_theme.dart';
import 'activity_detail_page.dart';
import 'activity_list_page.dart';
import 'stats_page.dart';

/// 首页（M1）：真实数据驱动——概览卡(今日/本周/本月) + 最近活动 + 空态。
/// 数据源：AggregateService.watchRides()（Drift watch，保存后自动刷新）。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _period = 0; // 0今日 1本周 2本月

  @override
  Widget build(BuildContext context) {
    final rides = ref.watch(ridesProvider).valueOrNull ?? const <k.RideLite>[];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _HeroStartButton(onPressed: () => _coming(context)),
          const SizedBox(height: 12),
          _cardLink(context,_overviewCard(rides)),
          const SizedBox(height: 18),
          _recent(rides),
        ],
      ),
    );
  }

  Widget _cardLink(BuildContext context, Widget child) => GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsPage())),
        child: child,
      );

  Widget _overviewCard(List<k.RideLite> rides) {
    final u = ref.watch(unitPrefsProvider);
    final now = DateTime.now();
    final kinds = [PeriodKind.today, PeriodKind.week, PeriodKind.month];
    final s = k.sumPeriod(rides, now, kinds[_period]);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _period = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _period == i ? AppTheme.card : AppTheme.card2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ['今日', '本周', '本月'][i],
                        style: TextStyle(
                          fontWeight: _period == i ? FontWeight.w600 : FontWeight.w400,
                          color: _period == i ? AppTheme.txt : AppTheme.txt2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ovItem('距离 ${u.distUnit}', u.distValue(s.km)),
              _ovItem('时长 min', '${s.min.round()}'),
              _ovItem('爬升 m', '${s.elev.round()}'),
            ],
          ),
          const SizedBox(height: 10),
          Text('骑行 ${s.count} 次',
              style: const TextStyle(fontSize: 12, color: AppTheme.txt3)),
        ],
      ),
    );
  }

  Widget _ovItem(String label, String value) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w700, color: AppTheme.txt)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.txt3)),
          ],
        ),
      );

  Widget _recent(List<k.RideLite> rides) {
    if (rides.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 26),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.line),
        ),
        child: const Text('还没有骑行记录，去「记录」开始第一次骑行吧',
            style: TextStyle(fontSize: 12.5, color: AppTheme.txt3)),
      );
    }
    final top = rides.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Row(
            children: [
              const Text('最近活动', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ActivityListPage()),
                ),
                child: const Text('全部'),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.line),
          ),
          child: Column(
            children: [for (final r in top) _row(context, r)],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, k.RideLite r) {
    final u = ref.watch(unitPrefsProvider);
    final date =
        '${r.startAt.month}月${r.startAt.day}日 ${r.startAt.hour}:${r.startAt.minute.toString().padLeft(2, '0')}';
    final avgSpeed = r.durationMin > 0 ? (r.distanceKm / (r.durationMin / 60)) : 0.0;
    return ListTile(
      leading: const Icon(Icons.directions_bike, color: AppTheme.accent),
      title: Text('骑行 · $date', style: const TextStyle(fontSize: 14)),
      subtitle: Text('${u.dist(r.distanceKm)} · 爬升 ${u.elev(r.elevGainM)}'),
      trailing: Text(u.speed(avgSpeed),
          style: const TextStyle(fontSize: 13, color: AppTheme.txt2)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ActivityDetailPage(rideId: r.id)),
      ),
    );
  }

  void _coming(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('记录/详情正在接入（M1 进行中）', textAlign: TextAlign.center)),
    );
  }
}

class _HeroStartButton extends StatelessWidget {
  const _HeroStartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6A1A), AppTheme.accent, Color(0xFFE23D00)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .18),
                    border: Border.all(color: Colors.white.withValues(alpha: .55)),
                  ),
                  child: const Icon(Icons.directions_bike, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('开始骑行',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                      SizedBox(height: 3),
                      Text('GPS 轨迹 · 数据保存在本地（M1）',
                          style: TextStyle(color: Colors.white, fontSize: 12.5)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
