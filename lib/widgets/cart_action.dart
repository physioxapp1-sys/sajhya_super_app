import 'package:flutter/material.dart';

/// App-bar cart icon with a live item-count badge. Takes the count and
/// listenable directly rather than importing ShopCartState/PharmacyCartState
/// itself, so it works for either cart without caring which one.
class CartAction extends StatelessWidget {
  final Listenable listenable;
  final int Function() count;
  final VoidCallback onTap;

  const CartAction({
    super.key,
    required this.listenable,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final n = count();
        return IconButton(
          onPressed: onTap,
          icon: Badge(
            label: Text('$n'),
            isLabelVisible: n > 0,
            child: const Icon(Icons.shopping_cart_outlined, color: Colors.teal),
          ),
        );
      },
    );
  }
}
