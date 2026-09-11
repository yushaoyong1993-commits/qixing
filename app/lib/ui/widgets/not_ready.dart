import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// 原型里有、但功能尚未实现的入口统一后缀标注。
const String kNotReadyLabel = '（未完成）';

/// 点击未完成项时的统一提示。
void showNotReady(BuildContext context, String name) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$name 未完成（原型占位）', textAlign: TextAlign.center)),
  );
}

/// 通用功能入口行（列表项），支持"未完成"标注。
class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.notReady = false,
    this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool notReady;
  final VoidCallback? onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: notReady ? AppTheme.txt3 : AppTheme.accentInk),
      title: Row(
        children: [
          Flexible(
            child: Text(title,
                style: TextStyle(
                    fontSize: 14, color: notReady ? AppTheme.txt2 : AppTheme.txt)),
          ),
          if (notReady)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Text(kNotReadyLabel,
                  style: TextStyle(fontSize: 11, color: AppTheme.txt3)),
            ),
        ],
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppTheme.txt3)),
      trailing: Text(trailingText ?? '',
          style: const TextStyle(fontSize: 12, color: AppTheme.txt3)),
      onTap: onTap ?? (notReady ? () => showNotReady(context, title) : null),
    );
  }
}
