import 'package:flutter/material.dart';

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
  const PriceCheck({super.key, required this.allowance, required this.expired});
  final int allowance;
  final bool expired;
  @override
  State<PriceCheck> createState() => _PriceCheckState();
}

class _PriceCheckState extends State<PriceCheck> {
  final query = TextEditingController();
  final quote = TextEditingController();
  ReferencePrice? selected;
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 32),
      const Text('Check a purchase',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      const Text('Compare a price with your daily allowance.'),
      const SizedBox(height: 24),
      TextField(
          controller: query,
          decoration: const InputDecoration(
              labelText: 'Search purchases', prefixIcon: Icon(Icons.search)),
          onChanged: (_) => setState(() {
                selected = null;
                quote.clear();
              })),
      const SizedBox(height: 12),
      if (matches.isEmpty)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No matching purchase. Try chicken, eggs or lentils.')),
      for (final price in matches)
        ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${price.name} · ${price.unit}'),
            subtitle: Text('${price.price} DZD · reference example'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => select(price)),
      if (item != null) ...[
        const SizedBox(height: 16),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.name} · ${item.unit}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Text('${item.price} DZD',
                          style: const TextStyle(fontSize: 36)),
                      const Text(
                          'Oran · Reference date: 20 Oct 2026 · Not live'),
                      const SizedBox(height: 8),
                      const Text(
                          'Source: user-provided Wafir mockup. Illustrative prices; not verified market prices.',
                          style: TextStyle(color: Colors.white60)),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 16),
                      if (valid && !widget.expired && widget.allowance > 0) ...[
                        Text(
                            'That is ${(cost / widget.allowance).toStringAsFixed(1)} days of your allowance.',
                            key: const ValueKey('price-days'),
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(
                            cost > widget.allowance
                                ? 'Caution: exceeds one day of allowance.'
                                : 'Within one day of allowance.',
                            style: TextStyle(
                                color: cost > widget.allowance
                                    ? const Color(0xFFF5B84A)
                                    : const Color(0xFF34D399))),
                        if (quoted)
                          const Text('Comparison uses your quoted price.'),
                      ] else if (widget.expired)
                        const Text(
                            'Start a new budget period to compare this price.')
                      else if (widget.allowance <= 0)
                        const Text(
                            'No daily allowance is available. Review your budget before this purchase.'),
                    ]))),
        const SizedBox(height: 24),
        const Text('Cheaper reference alternatives',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        if (alternatives.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No cheaper reference alternatives are available.')),
        for (final price in alternatives)
          ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${price.name} · ${price.unit}'),
              subtitle: Text('${price.price} DZD · example, not live'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => select(price)),
        const Text(
            'Quantities and products differ. Compare portions and your needs before choosing.',
            style: TextStyle(color: Colors.white60)),
      ],
    ]);
  }
}
