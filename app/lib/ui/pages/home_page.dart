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
          if (ref.watch(sessionStatusProvider) != null) _liveBanner(),
          _HeroStartButton(onPressed: () => _coming(context)),
          const SizedBox(height: 12),
          _cardLink(context,_overviewCard(rides)),
          if (rides.isNotEmpty) ...[
            const SizedBox(height: 12),
            _lastRideCard(rides.first),
          ],
          const SizedBox(height: 18),
          _recent(rides),
        ],
      ),
    );
  }

  /// 骑行进行中横幅（与记录会话联动）
  Widget _liveBanner() {
    final st = ref.watch(sessionStatusProvider)!;
    final u = ref.watch(unitPrefsProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEBDD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(st.paused ? Icons.pause_circle_outline : Icons.fiber_manual_record,
              size: 14, color: AppTheme.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${st.paused ? '已暂停' : '骑行进行中'} ${st.clock}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('${u.dist(st.distanceKm)} · ${st.type} · L${st.lap}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.txt2)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ref.read(tabIndexProvider.notifier).state = 2,
            child: const Text('回到记录', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// 上次骑行卡（原型 lastCard）：名称/时间/距离/时长/爬升 + 轨迹缩略图
  Widget _lastRideCard(k.RideLite r) {
    final u = ref.watch(unitPrefsProvider);
    final d = r.startAt;
    final date =
        '${d.month}-${d.day} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 62,
            decoration: BoxDecoration(
              color: AppTheme.card2,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text('轨迹缩略图\n（未完成）',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9.5, color: AppTheme.txt3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('上次骑行',
                    style: TextStyle(fontSize: 11, color: AppTheme.txt3)),
                const SizedBox(height: 2),
                Text(r.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
                const SizedBox(height: 4),
                Text('${u.dist(r.distanceKm)} · ${_fmtSec(r.durationMin * 60)} · '
                    '${u.elev(r.elevGainM)} ↑',
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.txt2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtSec(double seconds) {
    final t = seconds.round();
    final h = t ~/ 3600, m = (t % 3600) ~/ 60, sec = t % 60;
    String p(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '${p(h)}:${p(m)}:${p(sec)}' : '${p(m)}:${p(sec)}';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_deltaText(rides, now, s),
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
              Text('累计骑行 ${u.dist(_totalKm(rides))}',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.txt3)),
            ],
          ),
          const SizedBox(height: 4),
          Text('骑行 ${s.count} 次',
              style: const TextStyle(fontSize: 12, color: AppTheme.txt3)),
        ],
      ),
    );
  }

  /// 较上一周期同期的距离变化（今日→昨日，本周→上周，本月→上月）
  String _deltaText(List<k.RideLite> rides, DateTime now, k.PeriodStats cur) {
    final kind = [PeriodKind.today, PeriodKind.week, PeriodKind.month][_period];
    final prev = _prevPeriod(now, kind);
    final prevStats = k.sumPeriod(rides, prev, kind);
    if (prevStats.km <= 0) return '较上期无可比数据';
    final d = (cur.km - prevStats.km) / prevStats.km * 100;
    final sign = d >= 0 ? '+' : '';
    return '较上期同期 $sign${d.round()}% 距离';
  }

  DateTime _prevPeriod(DateTime now, PeriodKind kind) => switch (kind) {
        PeriodKind.today => now.subtract(const Duration(days: 1)),
        PeriodKind.week => now.subtract(const Duration(days: 7)),
        PeriodKind.month => DateTime(now.year, now.month - 1, now.day),
      };

  double _totalKm(List<k.RideLite> rides) {
    var km = 0.0;
    for (final r in rides) {
      km += r.distanceKm;
    }
    return km;
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
