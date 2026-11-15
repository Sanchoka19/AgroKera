import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AgroTagItem {
  final String label;
  final IconData icon;

  const AgroTagItem(this.label, this.icon);

  static const List<AgroTagItem> all = [
    AgroTagItem('ბიო / ორგანული', LucideIcons.leaf),
    AgroTagItem('ახალი მოსავალი', LucideIcons.sprout),
    AgroTagItem('სათბურის', LucideIcons.warehouse),
    AgroTagItem('ღია გრუნტის', LucideIcons.sun),
    AgroTagItem('უწამლი / ნატურალური', LucideIcons.shieldCheck),
    AgroTagItem('ქართული წარმოება', LucideIcons.mapPin),
  ];

  static IconData iconFor(String label) {
    for (final tag in all) {
      if (tag.label == label) return tag.icon;
    }
    return LucideIcons.tag;
  }
}

