import 'package:flutter/material.dart';
import '../../domain/models/budget_data.dart';
import '../design/design.dart';
import 'editor_actions.dart';

class ProductList extends StatelessWidget {
  const ProductList(
      {super.key,
      required this.products,
      required this.onChanged,
      required this.onEdit,
      this.enabled = true});
  final List<UsualProduct> products;
  final ValueChanged<List<UsualProduct>> onChanged;
  final bool enabled;
  final Future<Object?> Function(UsualProduct?) onEdit;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (products.isEmpty)
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CurrencyText(
                  'Add the things you usually spend on. One tap will log the usual price.',
                  style: type(13, color: secondaryText, height: 1.5))),
        for (var i = 0; i < products.length; i++)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      horizontalTitleGap: 20,
                      leading: Opacity(
                          opacity: .55,
                          child: SourceIcon(products[i].icon,
                              color: secondaryText)),
                      title: CurrencyText(products[i].name,
                          style: type(14, weight: FontWeight.w500)),
                      subtitle: CurrencyText('${products[i].price} DA',
                          style: type(12, color: tertiaryText)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Edit',
                            style: type(12,
                                color: secondaryText, weight: FontWeight.w500)),
                        const SizedBox(width: 4),
                        const SourceIcon('chevron-right',
                            size: 16, color: secondaryText),
                      ]),
                      onTap: !enabled
                          ? null
                          : () async {
                              final updated = await onEdit(products[i]);
                              if (updated is UsualProduct) {
                                onChanged([...products]..[i] = updated);
                              } else if (updated == 'delete') {
                                onChanged([...products]..removeAt(i));
                              }
                            },
                      onLongPress: !enabled
                          ? null
                          : () async {
                              final yes = await confirmAction(
                                  context,
                                  'Remove product?',
                                  'Past expenses will stay unchanged.',
                                  'Remove');
                              if (yes) onChanged([...products]..removeAt(i));
                            }))),
        if (products.isNotEmpty) const SizedBox(height: 16),
        FilledButton.icon(
            style: FilledButton.styleFrom(
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                textStyle: const TextStyle(
                    fontFamily: 'RedHatDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -.14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            onPressed: !enabled
                ? null
                : () async {
                    final product = await onEdit(null);
                    if (product is UsualProduct) {
                      onChanged([...products, product]);
                    }
                  },
            icon: const SourceIcon('plus', size: 17, color: Color(0xFF06251A)),
            label: const CurrencyText('Add product')),
        if (products.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CurrencyText(
                  'Tap to edit or remove. Past expenses stay unchanged.',
                  style: type(11, color: tertiaryText))),
      ]);
}
