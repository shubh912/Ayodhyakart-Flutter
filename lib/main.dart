import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';

void main() {
  runApp(const AyodhyakartApp());
}

class AyodhyakartApp extends StatelessWidget {
  const AyodhyakartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayodhyakart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF0C831F), // Blinkit Green
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C831F)),
      ),
      home: const MainScreen(),
    );
  }
}

// --- MODELS ---
class Product {
  final int id;
  final String name;
  final String cat;
  final int price;
  final String weight;
  final String image;
  Product({required this.id, required this.name, required this.cat, required this.price, required this.weight, required this.image});
}

class CartItem {
  final Product product;
  int qty;
  CartItem({required this.product, required this.qty});
}

// --- SCREEN ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;
  List<Product> products = [];
  List<CartItem> cart = [];
  bool isLoggedIn = false;
  String userName = "Guest";
  String userPhone = "";
  bool isAdmin = false;

  // Image Proxy to fix loading issues
  final String proxy = "https://wsrv.nl/?url=";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    // REAL IMAGES
    final imgDB = {
      'Dairy': ["https://m.media-amazon.com/images/I/51wG877Jq+L.jpg", "https://m.media-amazon.com/images/I/61+9+852+6L._SX679_.jpg"],
      'Grocery': ["https://m.media-amazon.com/images/I/71J-yN-wZ9L._SX679_.jpg", "https://m.media-amazon.com/images/I/61G+5j+8+bL.jpg"],
      'Snacks': ["https://m.media-amazon.com/images/I/718X6+6+GGL._SX679_.jpg", "https://m.media-amazon.com/images/I/81+9+852+6L.jpg"],
      'Drinks': ["https://m.media-amazon.com/images/I/51v8nyxSOYL._SX679_.jpg", "https://m.media-amazon.com/images/I/61+9+852+6L.jpg"],
    };

    int id = 1;
    final config = [
      {'c': 'Dairy', 'n': ['Amul Milk', 'Butter'], 'w': '500ml'},
      {'c': 'Grocery', 'n': ['Atta', 'Oil'], 'w': '1kg'},
      {'c': 'Snacks', 'n': ['Lays', 'Kurkure'], 'w': '50g'},
      {'c': 'Drinks', 'n': ['Coke', 'Sprite'], 'w': '750ml'},
    ];

    for(int i=0; i<500; i++) {
      var conf = config[Random().nextInt(config.length)];
      var cat = conf['c'] as String;
      var name = (conf['n'] as List)[Random().nextInt((conf['n'] as List).length)];
      var imgPool = imgDB[cat]!;
      
      products.add(Product(
        id: id++,
        name: name,
        cat: cat,
        price: Random().nextInt(200)+20,
        weight: conf['w'] as String,
        image: proxy + imgPool[Random().nextInt(imgPool.length)] + "&w=200&output=webp"
      ));
    }
  }

  // --- LOGIC ---
  void _modQty(Product p, int d) {
    setState(() {
      int i = cart.indexWhere((c) => c.product.id == p.id);
      if (i != -1) {
        cart[i].qty += d;
        if (cart[i].qty <= 0) cart.removeAt(i);
      } else if (d > 0) {
        cart.add(CartItem(product: p, qty: 1));
      }
    });
  }

  int _getQty(int pid) {
    var item = cart.firstWhere((c) => c.product.id == pid, orElse: () => CartItem(product: products[0], qty: 0));
    return item.qty;
  }

  // --- ACTIONS ---
  Future<void> _placeOrder() async {
    if (!isLoggedIn) { _showLogin(); return; }
    
    int total = cart.fold(0, (sum, i) => sum + (i.product.price * i.qty));
    String items = cart.map((e) => "${e.product.name} x${e.qty}").join(', ');
    String msg = "New Order from $userName ($userPhone)\nItems: $items\nTotal: ₹$total";
    
    final Uri url = Uri.parse("https://wa.me/919129125998?text=${Uri.encodeComponent(msg)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      setState(() { cart.clear(); });
    }
  }

  void _showLogin() {
    TextEditingController phoneCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Login"),
      content: TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Phone")),
      actions: [TextButton(onPressed: () {
        if(phoneCtrl.text.length == 10) {
          setState(() { isLoggedIn=true; userName="User"; userPhone=phoneCtrl.text; });
          Navigator.pop(ctx);
        }
      }, child: const Text("Get OTP"))],
    ));
  }

  void _showAdminLogin() {
    TextEditingController u = TextEditingController();
    TextEditingController p = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Merchant Login"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: u, decoration: const InputDecoration(labelText: "ID")),
        TextField(controller: p, obscureText: true, decoration: const InputDecoration(labelText: "Password"))
      ]),
      actions: [TextButton(onPressed: () {
        if(u.text == "Jupiter" && p.text == "Shubh=y5") {
          setState(() { isAdmin=true; _idx=3; });
          Navigator.pop(ctx);
        }
      }, child: const Text("Login"))],
    ));
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = [_buildHome(), _buildCart(), const Center(child: Text("No Orders")), _buildAccount()];
    return Scaffold(
      body: SafeArea(child: tabs[_idx]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        indicatorColor: const Color(0xFFe7f9e8),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: "Home"),
          NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: "Cart"),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: "Orders"),
          NavigationDestination(icon: Icon(Icons.person_outline), label: "Account"),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Ayodhyakart", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const Text("⚡ 12 Mins", style: TextStyle(fontWeight: FontWeight.bold))
        ])),
        Expanded(
          child: ListView(children: [
            _buildShelf("Dairy"), _buildShelf("Grocery"), _buildShelf("Snacks"), _buildShelf("Drinks")
          ]),
        )
      ],
    );
  }

  Widget _buildShelf(String cat) {
    var items = products.where((p) => p.cat == cat).take(10).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.all(16), child: Text(cat, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      SizedBox(height: 240, child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (c, i) => _buildCard(items[i])
      ))
    ]);
  }

  Widget _buildCard(Product p) {
    int qty = _getQty(p.id);
    return Container(
      width: 140, margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Padding(padding: const EdgeInsets.all(8), child: CachedNetworkImage(imageUrl: p.image, placeholder: (c,u)=>const Icon(Icons.image), errorWidget: (c,u,e)=>const Icon(Icons.error)))),
        Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(p.weight, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("₹${p.price}", style: const TextStyle(fontWeight: FontWeight.bold)),
            qty == 0 
              ? InkWell(onTap: ()=>_modQty(p,1), child: Container(padding: const EdgeInsets.symmetric(horizontal:12, vertical:4), decoration: BoxDecoration(color: const Color(0xFFf7fff9), border: Border.all(color: const Color(0xFF0C831F)), borderRadius: BorderRadius.circular(6)), child: const Text("ADD", style: TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.bold, fontSize: 10))))
              : Container(padding: const EdgeInsets.symmetric(horizontal:6, vertical:4), decoration: BoxDecoration(color: const Color(0xFF0C831F), borderRadius: BorderRadius.circular(6)), child: Row(children: [
                  InkWell(onTap: ()=>_modQty(p,-1), child: const Icon(Icons.remove, color: Colors.white, size: 14)),
                  const SizedBox(width: 4), Text("$qty", style: const TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(width: 4), InkWell(onTap: ()=>_modQty(p,1), child: const Icon(Icons.add, color: Colors.white, size: 14)),
                ]))
          ])
        ]))
      ]),
    );
  }

  Widget _buildCart() {
    return Column(children: [
      Expanded(child: ListView.builder(itemCount: cart.length, itemBuilder: (c, i) => ListTile(
        title: Text(cart[i].product.name), subtitle: Text("x${cart[i].qty}"), trailing: Text("₹${cart[i].product.price * cart[i].qty}"),
      ))),
      if(cart.isNotEmpty) Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C831F), foregroundColor: Colors.white),
        onPressed: _placeOrder, child: const Text("Order via WhatsApp")
      )))
    ]);
  }

  Widget _buildAccount() {
    if(isAdmin) return Scaffold(appBar: AppBar(title: const Text("Admin"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: ()=>setState(()=>isAdmin=false))]), body: const Center(child: Text("Add Product Screen")));
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(isLoggedIn ? userName : "Guest", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      if(!isLoggedIn) ElevatedButton(onPressed: _showLogin, child: const Text("Login")),
      TextButton(onPressed: _showAdminLogin, child: const Text("Merchant Login"))
    ]));
  }
}
