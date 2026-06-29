/// A single product line item in an EPS order.
class EpsProduct {
  const EpsProduct({
    required this.name,
    required this.quantity,
    required this.price,
    this.profile = '',
    this.category = '',
  });

  final String name;
  final int quantity;
  final double price;
  final String profile;
  final String category;

  Map<String, String> toJson() => {
        'ProductName': name,
        'NoOfItem': quantity.toString(),
        'ProductPrice': price.toStringAsFixed(2),
        'ProductProfile': profile,
        'ProductCategory': category,
      };
}
