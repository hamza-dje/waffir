import 'package:flutter/material.dart';
import '../design/design.dart';

class AppNavigation extends StatelessWidget {
  const AppNavigation(
      {super.key, required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned.fill(
            top: sectionRadius, child: ColoredBox(color: background)),
        SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    pageInset, 0, pageInset, spaceRelated),
                child: Material(
                    color: navigationSurface,
                    borderRadius: BorderRadius.circular(sectionRadius),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 10),
                        child: Row(children: [
                          for (var i = 0; i < 5; i++)
                            Expanded(
                                child: Semantics(
                                    selected: selected == i,
                                    button: true,
                                    child: InkWell(
                                        onTap: () => onSelect(i),
                                        borderRadius: BorderRadius.circular(
                                            controlRadius),
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SourceIcon(
                                                      [
                                                        'home',
                                                        'list',
                                                        'banknote',
                                                        'clipboard',
                                                        'calendar'
                                                      ][i],
                                                      size: 22,
                                                      color: selected == i
                                                          ? mint
                                                          : tertiaryText),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                      [
                                                        'Home',
                                                        'History',
                                                        'Loans',
                                                        'Plan',
                                                        'Budget'
                                                      ][i],
                                                      style: type(10,
                                                          weight:
                                                              FontWeight.w500,
                                                          color: selected == i
                                                              ? mint
                                                              : tertiaryText)),
                                                ])))))
                        ]))))),
      ]);
}
