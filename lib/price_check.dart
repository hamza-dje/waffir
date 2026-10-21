import 'package:flutter/material.dart';
import 'design.dart';

typedef ReferencePrice = ({
  String name,
  String unit,
  int price,
  List<String> alternatives
});
const referencePrices = <ReferencePrice>[
  (
    name: 'Chicken',
    unit: '1 kg',
    price: 630,
    alternatives: ['Eggs', 'Lentils']
  ),
  (name: 'Eggs', unit: '12 pcs', price: 320, alternatives: ['Lentils']),
  (name: 'Lentils', unit: '1 kg', price: 180, alternatives: []),
];

class PriceCheck extends StatefulWidget {
  const PriceCheck(
      {super.key, required this.allowance, required this.expired, this.onBack});
  final int allowance;
  final bool expired;
  final VoidCallback? onBack;
  @override
  State<PriceCheck> createState() => _PriceCheckState();
}

class _PriceCheckState extends State<PriceCheck> {
  final query = TextEditingController(text: 'chicken');
  final quote = TextEditingController();
  ReferencePrice? selected = referencePrices.first;
  @override
  void dispose() {
    query.dispose();
    quote.dispose();
    super.dispose();
  }

  void select(ReferencePrice price) => setState(() {
        selected = price;
        quote.clear();
      });

  @override
  Widget build(BuildContext context) {
    final matches = referencePrices
        .where((p) =>
            p.name.toLowerCase().contains(query.text.trim().toLowerCase()))
        .toList();
    final item = selected;
    final quoted = quote.text.trim().isNotEmpty;
    final cost = quoted ? int.tryParse(quote.text) : item?.price;
    final valid = cost != null && cost > 0;
    final alternatives = item == null
        ? <ReferencePrice>[]
        : referencePrices
            .where((p) =>
                item.alternatives.contains(p.name) && p.price < item.price)
            .toList();

    Widget priceRow(ReferencePrice price) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
                onTap: () => select(price),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 14),
                    child: Row(children: [
                      Container(
                          width: 36,
                          height: 36,
                          decoration: panel(radius: 12, color: surfaceHigh),
                          child: Center(
                              child: SourceIcon(
                                  price.name == 'Eggs'
                                      ? 'egg'
                                      : price.name == 'Lentils'
                                          ? 'leaf'
                                          : 'utensils',
                                  size: 18,
                                  color: secondaryText))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('${price.name} · ${price.unit}',
                                style: type(13, weight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text('≈ ${price.price} DZD',
                                style: type(11, color: tertiaryText))
                          ])),
                      const SourceIcon('chevron-right',
                          size: 16, color: tertiaryText)
                    ])))));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
          child: Row(children: [
            if (widget.onBack != null) ...[
              SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                      onPressed: widget.onBack,
                      tooltip: 'Back to Today',
                      style: IconButton.styleFrom(
                          backgroundColor: surface,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      icon: const SourceIcon('arrow-left', size: 18))),
              const SizedBox(width: 12)
            ],
            Text('Check a purchase', style: type(15, weight: FontWeight.w600))
          ])),
      TextField(
          key: const ValueKey('purchase-search'),
          controller: query,
          style: type(15, weight: FontWeight.w500),
          decoration: InputDecoration(
              hintText: 'Search purchases',
              floatingLabelBehavior: FloatingLabelBehavior.never,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: SourceIcon('search', size: 18, color: tertiaryText)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none)),
          onChanged: (_) => setState(() {
                final found = referencePrices
                    .where((p) => p.name
                        .toLowerCase()
                        .contains(query.text.trim().toLowerCase()))
                    .toList();
                selected = found.length == 1 ? found.single : null;
                quote.clear();
              })),
      const SizedBox(height: 24),
      if (matches.isEmpty)
        Text('No matching purchase. Try chicken, eggs or lentils.',
            style: type(13, color: secondaryText)),
      if (item == null) ...[for (final price in matches) priceRow(price)],
      if (item != null) ...[
        Container(
            padding: const EdgeInsets.all(22),
            decoration: panel(radius: 22),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${item.name} · ${item.unit}',
                  style:
                      type(13, color: secondaryText, weight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text.rich(TextSpan(children: [
                TextSpan(
                    text: '${valid ? cost : item.price}',
                    style: type(36, weight: FontWeight.w600, spacing: -1.26)),
                TextSpan(text: ' DZD', style: type(13, color: tertiaryText))
              ])),
              const SizedBox(height: 6),
              Text('Reference example · Oran · not live',
                  style: type(11, color: tertiaryText)),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Divider(color: hairline, height: 1)),
              if (valid && !widget.expired && widget.allowance > 0) ...[
                Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: "That's "),
                      TextSpan(
                          text:
                              '${(cost / widget.allowance).toStringAsFixed(1)} days',
                          style: TextStyle(
                              color: cost > widget.allowance ? caution : mint,
                              fontWeight: FontWeight.w600)),
                      const TextSpan(text: ' of your allowance.'),
                    ]),
                    key: const ValueKey('price-days'),
                    style: type(15, height: 1.5)),
                const SizedBox(height: 16),
                Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: panel(
                        radius: 99,
                        color: cost > widget.allowance
                            ? const Color(0x24F5B84A)
                            : const Color(0x1F34D399)),
                    child: Text(
                        cost > widget.allowance
                            ? '●  CAUTION'
                            : '●  WITHIN BUDGET',
                        style: TextStyle(
                            fontFamily: 'GeistMono',
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                            color: cost > widget.allowance ? caution : mint))),
                if (quoted)
                  Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Comparison uses your quoted price.',
                          style: type(11, color: tertiaryText))),
              ] else if (widget.expired)
                Text('Start a new budget period to compare this price.',
                    style: type(15))
              else if (widget.allowance <= 0)
                Text(
                    'No daily allowance is available. Review your budget before this purchase.',
                    style: type(15)),
            ])),
        const SizedBox(height: 24),
        sectionLabel('Cheaper alternatives'),
        if (alternatives.isEmpty)
          Text('No cheaper reference alternatives are available.',
              style: type(13, color: secondaryText)),
        for (final price in alternatives) priceRow(price),
        const SizedBox(height: 16),
        ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text('Check your price', style: type(13)),
            trailing: const SourceIcon('chevron-right',
                size: 16, color: tertiaryText),
            children: [
              TextField(
                  controller: quote,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'Your quoted price (optional)',
                      suffixText: 'DZD',
                      errorText: quoted && !valid
                          ? 'Enter a positive whole amount.'
                          : null),
                  onChanged: (_) => setState(() {})),
              const SizedBox(height: 16)
            ]),
        ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text('Price source', style: type(13)),
            trailing: const SourceIcon('chevron-right',
                size: 16, color: tertiaryText),
            children: [
              Text('Oran · Reference date: 20 Oct 2026 · Not live',
                  style: type(11, color: secondaryText)),
              Text(
                  'Source: user-provided Waffir mockup. Illustrative prices; not verified market prices.',
                  style: type(11, color: secondaryText)),
              Text(
                  'Quantities and products differ. Compare portions and your needs before choosing.',
                  style: type(11, color: secondaryText))
            ]),
      ],
    ]);
  }
}
