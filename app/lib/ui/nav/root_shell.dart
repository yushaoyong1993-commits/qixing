import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

import '../pages/home_page.dart';
import '../pages/map_page.dart';
import '../pages/me_page.dart';
import '../pages/record_page.dart';
import '../../theme/app_theme.dart';

/// App 主壳：纯文字底部四 Tab（首页 / 地图 / 记录 / 我的）。
/// 规范来源：首页 PRD v1.1 §10 —— 无图标、等宽分布、选中深橙加粗 + 短横线。
///
/// 采用 **懒加载 + 保活** 的 IndexedStack：访问过的页面保留 State，
/// 这样从其它页面切回「地图」时 WebView 不会被重建（瓦片不会变白）。
class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  late final List<bool> _visited = [true, false, false, false];

  static const List<String> _tabs = ['首页', '地图', '记录', '我的'];

  static const List<Widget> _pages = [
    HomePage(),
    MapPage(),
    RecordPage(),
    MePage(),
  ];

  void _go(int i) {
    setState(() => _visited[i] = true);
    ref.read(tabIndexProvider.notifier).state = i;
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(tabIndexProvider);
    // 跨页跳转（如统计页"回到记录"）时，确保目标页已被构建过
    if (!_visited[index]) _visited[index] = true;
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [
          for (var i = 0; i < _pages.length; i++)
            _visited[i] ? _pages[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bg,
          border: const Border(top: BorderSide(color: AppTheme.line)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                    child: _TextTab(
                        label: _tabs[i], selected: index == i, onTap: () => _go(i))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextTab extends StatelessWidget {
  const _TextTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 9),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 3,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? AppTheme.accentInk : AppTheme.txt3,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 3,
            width: selected ? 20 : 0,
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
