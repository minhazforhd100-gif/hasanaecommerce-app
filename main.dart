import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'theme.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HasanaEcommerceApp());
}

class HasanaEcommerceApp extends StatelessWidget {
  const HasanaEcommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'hasanaecommerce',
      theme: buildTheme(),
      home: const AppShell(),
    );
  }
}

class CartItem {
  final Product product;
  int quantity;
  CartItem(this.product, {this.quantity = 1});
}

class AppState extends ChangeNotifier {
  final List<CartItem> cart = [];
  final Set<String> wishlist = {};
  List<Product> products = [];
  bool loading = true;
  String? error;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      products = await ApiService.fetchProducts();
      error = null;
    } catch (e) {
      error = 'পণ্য লোড করা যায়নি। আবার চেষ্টা করুন।';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void addToCart(Product p) {
    final found = cart.where((x) => x.product.id == p.id);
    if (found.isEmpty) {
      cart.add(CartItem(p));
    } else {
      found.first.quantity++;
    }
    notifyListeners();
  }

  void changeQty(Product p, int delta) {
    final item = cart.firstWhere((x) => x.product.id == p.id);
    item.quantity += delta;
    if (item.quantity <= 0) cart.remove(item);
    notifyListeners();
  }

  void toggleWishlist(Product p) {
    wishlist.contains(p.id) ? wishlist.remove(p.id) : wishlist.add(p.id);
    notifyListeners();
  }

  double get subtotal => cart.fold(0, (sum, e) => sum + e.product.price * e.quantity);
  int get cartCount => cart.fold(0, (sum, e) => sum + e.quantity);
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final state = AppState();
  int tab = 0;

  @override
  void initState() {
    super.initState();
    state.load();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(state: state),
      CategoriesPage(state: state),
      CartPage(state: state),
      OrdersPage(),
      AccountPage(state: state),
    ];

    return AnimatedBuilder(
      animation: state,
      builder: (_, __) => Scaffold(
        body: SafeArea(child: pages[tab]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            const NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Categories'),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: state.cartCount > 0,
                label: Text('${state.cartCount}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: const Icon(Icons.shopping_bag),
              label: 'Cart',
            ),
            const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
            const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final AppState state;
  const HomePage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: state.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Row(
            children: [
              Image.asset('assets/logo.png', width: 48, height: 48),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('hasanaecommerce', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.navy)),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            readOnly: true,
            onTap: () => showSearch(context: context, delegate: ProductSearchDelegate(state)),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search products...',
              suffixIcon: Icon(Icons.tune_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.navy, Color(0xFF0E3A68)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SHOP SMART', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                SizedBox(height: 8),
                Text('Quality products.\nSimple shopping.', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800, height: 1.15)),
                SizedBox(height: 8),
                Text('Cash on Delivery available', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Categories'),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'New', 'Popular', 'Offers'].map((c) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  width: 86,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                  child: Center(child: Text(c, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy))),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Featured Products'),
          const SizedBox(height: 12),
          if (state.loading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (state.products.isEmpty)
            const EmptyCatalog()
          else
            ProductGrid(state: state, products: state.products),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.text)),
      const Text('View all', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700)),
    ],
  );
}

class EmptyCatalog extends StatelessWidget {
  const EmptyCatalog({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
    child: const Column(
      children: [
        Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.muted),
        SizedBox(height: 12),
        Text('Products will appear here', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        SizedBox(height: 6),
        Text('Connect the verified store API to load live products.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
      ],
    ),
  );
}

class ProductGrid extends StatelessWidget {
  final AppState state;
  final List<Product> products;
  const ProductGrid({super.key, required this.state, required this.products});
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: products.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .67),
    itemBuilder: (_, i) => ProductCard(product: products[i], state: state),
  );
}

class ProductCard extends StatelessWidget {
  final Product product;
  final AppState state;
  const ProductCard({super.key, required this.product, required this.state});
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductPage(product: product, state: state))),
    child: Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: product.imageUrl.isEmpty ? const ColoredBox(color: Color(0xFFF1F3F5), child: Icon(Icons.image_outlined, size: 50, color: AppColors.muted)) : Image.network(product.imageUrl, fit: BoxFit.cover)),
                Positioned(top: 8, right: 8, child: CircleAvatar(backgroundColor: Colors.white, child: IconButton(padding: EdgeInsets.zero, onPressed: () => state.toggleWishlist(product), icon: Icon(state.wishlist.contains(product.id) ? Icons.favorite : Icons.favorite_border, color: state.wishlist.contains(product.id) ? Colors.red : AppColors.navy)))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 4),
            child: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: Text('৳${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.navy)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 8),
            child: SizedBox(width: double.infinity, child: FilledButton(
              onPressed: product.inStock ? () => state.addToCart(product) : null,
              style: FilledButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
              child: const Text('Add to Cart'),
            )),
          ),
        ],
      ),
    ),
  );
}

class ProductPage extends StatelessWidget {
  final Product product;
  final AppState state;
  const ProductPage({super.key, required this.product, required this.state});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Product')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AspectRatio(aspectRatio: 1, child: ClipRRect(borderRadius: BorderRadius.circular(20), child: product.imageUrl.isEmpty ? const ColoredBox(color: Colors.white, child: Icon(Icons.image_outlined, size: 80)) : Image.network(product.imageUrl, fit: BoxFit.cover))),
        const SizedBox(height: 18),
        Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('৳${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.navy)),
        const SizedBox(height: 18),
        Text(product.description.isEmpty ? 'Product description will appear when connected to the live store.' : product.description, style: const TextStyle(height: 1.55, color: AppColors.muted)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => state.toggleWishlist(product), child: const Text('Wishlist'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.orange), onPressed: product.inStock ? () { state.addToCart(product); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart'))); } : null, child: const Text('Add to Cart'))),
        ]),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.navy), onPressed: product.inStock ? () { state.addToCart(product); Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(state: state))); } : null, child: const Text('Buy Now'))),
      ],
    ),
  );
}

class CartPage extends StatelessWidget {
  final AppState state;
  const CartPage({super.key, required this.state});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (_, __) => ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('My Cart', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        if (state.cart.isEmpty)
          const EmptyCart()
        else ...[
          ...state.cart.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)), child: item.product.imageUrl.isEmpty ? const Icon(Icons.image_outlined) : Image.network(item.product.imageUrl, fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('৳${item.product.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                Row(children: [
                  IconButton(onPressed: () => state.changeQty(item.product, -1), icon: const Icon(Icons.remove_circle_outline)),
                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  IconButton(onPressed: () => state.changeQty(item.product, 1), icon: const Icon(Icons.add_circle_outline)),
                ]),
              ])),
            ]),
          )),
          const SizedBox(height: 8),
          SummaryCard(state: state),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.orange, padding: const EdgeInsets.symmetric(vertical: 16)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage(state: state))), child: const Text('Proceed to Checkout'))),
        ],
      ],
    ),
  );
}

class SummaryCard extends StatelessWidget {
  final AppState state;
  const SummaryCard({super.key, required this.state});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('৳${state.subtotal.toStringAsFixed(0)}')]),
      const SizedBox(height: 8),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Delivery'), Text('Calculated at checkout')]),
      const Divider(height: 22),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.w900)), Text('৳${state.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy))]),
    ]),
  );
}

class CheckoutPage extends StatefulWidget {
  final AppState state;
  const CheckoutPage({super.key, required this.state});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  bool sending = false;

  Future<void> submit() async {
    if (name.text.trim().isEmpty || phone.text.trim().isEmpty || address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete your name, phone and address.')));
      return;
    }
    setState(() => sending = true);
    try {
      final orderId = await ApiService.placeOrder(
        name: name.text.trim(),
        phone: phone.text.trim(),
        address: address.text.trim(),
        total: widget.state.subtotal,
        items: widget.state.cart.map((e) => {'product_id': e.product.id, 'quantity': e.quantity}).toList(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderSuccess(orderId: orderId)));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('ORDER_API_NOT_CONFIGURED')
          ? 'Order API is not connected yet. Your checkout form is ready, but live orders need the store API.'
          : 'Order could not be placed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Checkout')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Delivery Information', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Full Name')),
        const SizedBox(height: 12),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number')),
        const SizedBox(height: 12),
        TextField(controller: address, maxLines: 4, decoration: const InputDecoration(labelText: 'Full Delivery Address')),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: const Row(children: [Icon(Icons.payments_outlined, color: AppColors.orange), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Cash on Delivery', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('Pay when your order arrives.', style: TextStyle(color: AppColors.muted))]))])),
        const SizedBox(height: 18),
        SummaryCard(state: widget.state),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.orange, padding: const EdgeInsets.symmetric(vertical: 16)), onPressed: sending ? null : submit, child: Text(sending ? 'Placing Order...' : 'Place Order'))),
      ],
    ),
  );
}

class OrderSuccess extends StatelessWidget {
  final String orderId;
  const OrderSuccess({super.key, required this.orderId});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const CircleAvatar(radius: 42, backgroundColor: Color(0xFFEAF7EF), child: Icon(Icons.check_rounded, size: 48, color: Colors.green)),
      const SizedBox(height: 20),
      const Text('Order Confirmed', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text('Order ID: $orderId', style: const TextStyle(color: AppColors.muted)),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.navy), onPressed: () => Navigator.popUntil(context, (r) => r.isFirst), child: const Text('Continue Shopping'))),
    ]))
  );
}

class EmptyCart extends StatelessWidget {
  const EmptyCart({super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 70), child: Column(children: [const Icon(Icons.shopping_bag_outlined, size: 70, color: AppColors.muted), const SizedBox(height: 14), const Text('Your cart is empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 6), const Text('Add products to see them here.', style: TextStyle(color: AppColors.muted))]));
}

class CategoriesPage extends StatelessWidget {
  final AppState state;
  const CategoriesPage({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    final categories = state.products.map((p) => p.category).where((e) => e.isNotEmpty).toSet().toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Categories', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      if (categories.isEmpty)
        const EmptyCatalog()
      else
        ...categories.map((c) => ListTile(tileColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), leading: const CircleAvatar(child: Icon(Icons.category_outlined)), title: Text(c, style: const TextStyle(fontWeight: FontWeight.w700)), trailing: const Icon(Icons.chevron_right))),
    ]);
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Padding(padding: EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long_outlined, size: 70, color: AppColors.muted), SizedBox(height: 14), Text('Your orders will appear here', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), SizedBox(height: 6), Text('Live order history will be enabled when the store order API is connected.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted))])));
}

class AccountPage extends StatelessWidget {
  final AppState state;
  const AccountPage({super.key, required this.state});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
    const SizedBox(height: 18),
    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(20)), child: const Row(children: [CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.person, color: AppColors.navy, size: 30)), SizedBox(width: 14), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Welcome to', style: TextStyle(color: Colors.white70)), Text('hasanaecommerce', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))])])),
    const SizedBox(height: 16),
    ...['My Orders', 'Wishlist', 'Help & Support', 'About Us', 'Privacy Policy', 'Terms & Conditions'].map((x) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(title: Text(x), trailing: const Icon(Icons.chevron_right)))),
  ]);
}

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final AppState state;
  ProductSearchDelegate(this.state);
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(onPressed: () => close(context, null), icon: const Icon(Icons.arrow_back));
  @override
  Widget buildResults(BuildContext context) {
    final results = state.products.where((p) => p.name.toLowerCase().contains(query.toLowerCase()) || p.description.toLowerCase().contains(query.toLowerCase())).toList();
    if (results.isEmpty) return const Center(child: Text('No products found'));
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .67),
      itemCount: results.length,
      itemBuilder: (_, i) => ProductCard(product: results[i], state: state),
    );
  }
  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
