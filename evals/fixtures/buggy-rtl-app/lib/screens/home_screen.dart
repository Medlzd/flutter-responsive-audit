import 'package:flutter/material.dart';

class Product {
  const Product(this.name, this.price);
  final String name;
  final String price;
}

const products = [
  Product('ساعة ذكية', '199 ر.س'),
  Product('سماعات لاسلكية', '149 ر.س'),
  Product('حقيبة ظهر', '89 ر.س'),
  Product('نظارة شمسية', '120 ر.س'),
  Product('محفظة جلدية', '75 ر.س'),
  Product('قارورة ماء', '35 ر.س'),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Text(
              'أحدث المنتجات',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 140,
                childAspectRatio: 0.75,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) =>
                  ProductCard(product: products[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 4, top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Center(child: Icon(Icons.shopping_bag, size: 48)),
            ),
            Text(product.name, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(product.price),
          ],
        ),
      ),
    );
  }
}
