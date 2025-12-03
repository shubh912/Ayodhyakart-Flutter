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
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(),
    );
  }
}

// --- DATA MODELS ---
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

// --- MAIN SCREEN ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<Product> products = [];
  List<CartItem> cart = [];
  String? userName;
  String? userPhone;
  bool isAdmin = false;

  // Image Proxy for High Quality
  final String proxyUrl = "https://wsrv.nl/?url=";

  @override
  void initState() {
    super.initState();
    _generateData();
  }

  // --- 1. DATA GENERATOR (Matches your Web Logic) ---
  void _generateData() {
    final images = {
      'Dairy': ["https://m.media-amazon.com/images/I/51wG877Jq+L.jpg", "https://m.media-amazon.com/images/I/61+9+852+6L._SX679_.jpg"],
      'Grocery': ["https://m.media-amazon.com/images/I/71J-yN-wZ9L._SX679_.jpg", "https://m.media-amazon.com/images/I/61G+5j+8+bL.jpg"],
      'Snacks': ["https://m.media-amazon.com/images/I/718X6+6+GGL._SX679_.jpg", "https://m.media-amazon.com/images/I/81+9+852+6L.jpg"],
      'Drinks': ["https://m.media-amazon.com/images/I/51v8nyxSOYL._SX679_.jpg", "https://m.media-amazon.com/images/I/61+9+852+6L.jpg"],
    };

    final config = [
      {'c': 'Dairy', 'n': ['Amul Milk', 'Butter', 'Cheese'], 'w': '500ml'},
      {'c': 'Grocery', 'n': ['Atta', 'Oil', 'Salt'], 'w': '1kg'},
      {'c': 'Snacks', 'n': ['Lays', 'Kurkure', 'Maggi'], 'w': '50g'},
      {'c': 'Drinks', 'n': ['Coke', 'Sprite', 'Frooti'], 'w': '750ml'},
    ];

    int id = 1;
    for (int i = 0; i < 500; i++) {
      var conf = config[Random().nextInt(config.length)];
      String cat = conf['c'] as String;
      List<String> names = conf['n'] as List<String>;
      List<String> imgPool = images[cat]!;
      
      products.add(Product(
        id: id++,
        name: names[Random().nextInt(names.length)],
        cat: cat,
        price: Random().nextInt(200) + 20,
        weight: conf['w'] as String,
        image: proxyUrl + imgPool[Random().nextInt(imgPool.length)] + "&w=200&output=webp",
      ));
    }
  }

  // --- CART LOGIC ---
  void _updateQty(Product p, int delta) {
    setState(() {
      int idx = cart.indexWhere((c) => c.product.id == p.id);
      if (idx != -1) {
        cart[idx].qty += delta;
        if (cart[idx].qty <= 0) cart.removeAt(idx);
      } else if (delta > 0) {
        cart.add(CartItem(product: p, qty: 1));
      }
    });
  }

  int _getQty(int pid) {
    var item = cart.firstWhere((c) => c.product.id == pid, orElse: () => CartItem(product: products[0], qty: 0));
    return item.qty;
  }

  int _getTotal() => cart.fold(0, (sum, item) => sum + (item.product.price * item.qty));

  // --- WHATSAPP ORDER ---
  Future<void> _placeOrder() async {
    if (userName == null) {
      _showAuthDialog();
      return;
    }
    String items = cart.map((e) => "${e.product.name} x${e.qty}").join(', ');
    String msg = "New Order from $userName ($userPhone)\nItems: $items\nTotal: ₹${_getTotal()}";
    
    final Uri url = Uri.parse("https://wa.me/919129125998?text=${Uri.encodeComponent(msg)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      setState(() => cart.clear());
      _showSnack("Order Sent via WhatsApp!");
    } else {
      _showSnack("Could not launch WhatsApp");
    }
  }

  // --- AUTH DIALOGS ---
  void _showAuthDialog() {
    TextEditingController phoneCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Login"),
      content: TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Phone (10 digits)")),
      actions: [
        TextButton(onPressed: () {
          if (phoneCtrl.text.length == 10) {
            Navigator.pop(ctx);
            _showOtpDialog(phoneCtrl.text);
          }
        }, child: const Text("Get OTP"))
      ],
    ));
  }

  void _showOtpDialog(String phone) {
    TextEditingController otpCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Verify OTP"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("OTP Sent: 1234", style: TextStyle(color: Colors.green)),
        TextField(controller: otpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Enter OTP")),
      ]),
      actions: [
        TextButton(onPressed: () {
          if (otpCtrl.text == "1234") {
            setState(() { userName = "User"; userPhone = phone; });
            Navigator.pop(ctx);
            _showSnack("Logged In!");
          }
        }, child: const Text("Verify"))
      ],
    ));
  }

  void _showAdminLogin() {
    TextEditingController idCtrl = TextEditingController();
    TextEditingController passCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Merchant Login"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: idCtrl, decoration: const InputDecoration(labelText: "ID")),
        TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
      ]),
      actions: [
        TextButton(onPressed: () {
          if (idCtrl.text == "Jupiter" && passCtrl.text == "Shubh=y5") {
            setState(() => isAdmin = true);
            Navigator.pop(ctx);
            _showSnack("Admin Access Granted");
          } else {
            _showSnack("Invalid Credentials");
          }
        }, child: const Text("Login"))
      ],
    ));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    final tabs = [ _buildHome(), _buildCart(), _buildOrders(), _buildAccount() ];

    return Scaffold(
      body: SafeArea(child: tabs[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        indicatorColor: const Color(0xFFe7f9e8),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Color(0xFF0C831F)), label: "Home"),
          NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag, color: Color(0xFF0C831F)), label: "Cart"),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF0C831F)), label: "Orders"),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: Color(0xFF0C831F)), label: "Account"),
        ],
      ),
    );
  }

  // --- HOME TAB ---
  Widget _buildHome() {
    return Column(
      children: [
        // App Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                RichText(text: const TextSpan(children: [
                  TextSpan(text: "Ayodhya", style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w900)),
                  TextSpan(text: "kart", style: TextStyle(color: Color(0xFFf5c934), fontSize: 22, fontWeight: FontWeight.w900)),
                ])),
                const Text("⚡ 12 Mins • Ayodhya", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              ]),
              IconButton(icon: const Icon(Icons.account_circle, size: 30), onPressed: () => setState(() => _selectedIndex = 3)),
            ],
          ),
        ),
        
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search "Milk", "Curd"...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (val) {}, // Implement Search filter logic here if needed
          ),
        ),
        const SizedBox(height: 10),

        // Body
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Banners
                SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildBanner(const Color(0xFFFF9966), "50% OFF"),
                      _buildBanner(const Color(0xFF56ab2f), "Fresh Veg"),
                      _buildBanner(const Color(0xFF4568DC), "Dairy"),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Categories
                _buildShelf("Dairy"),
                _buildShelf("Grocery"),
                _buildShelf("Snacks"),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildBanner(Color color, String text) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildShelf(String cat) {
    var items = products.where((p) => p.cat == cat).take(10).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(cat, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("See all", style: TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.bold)),
          ]),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (ctx, i) => _buildCard(items[i]),
          ),
        )
      ],
    );
  }

  Widget _buildCard(Product p) {
    int qty = _getQty(p.id);
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CachedNetworkImage(imageUrl: p.image, placeholder: (c,u)=>const Center(child: CircularProgressIndicator()), errorWidget: (c,u,e)=>const Icon(Icons.image)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(p.weight, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("₹${p.price}", style: const TextStyle(fontWeight: FontWeight.bold)),
                qty == 0
                  ? InkWell(
                      onTap: () => _updateQty(p, 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFf7fff9), border: Border.all(color: const Color(0xFF0C831F)), borderRadius: BorderRadius.circular(6)),
                        child: const Text("ADD", style: TextStyle(color: Color(0xFF0C831F), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF0C831F), borderRadius: BorderRadius.circular(6)),
                      child: Row(children: [
                        InkWell(onTap: () => _updateQty(p, -1), child: const Icon(Icons.remove, color: Colors.white, size: 16)),
                        const SizedBox(width: 4),
                        Text("$qty", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        InkWell(onTap: () => _updateQty(p, 1), child: const Icon(Icons.add, color: Colors.white, size: 16)),
                      ]),
                    )
              ])
            ]),
          )
        ],
      ),
    );
  }

  // --- 2. CART TAB ---
  Widget _buildCart() {
    if (cart.isEmpty) return const Center(child: Text("Cart is empty"));
    return Column(
      children: [
        AppBar(title: const Text("My Cart")),
        Expanded(child: ListView.separated(
          itemCount: cart.length,
          separatorBuilder: (c, i) => const Divider(),
          itemBuilder: (ctx, i) => ListTile(
            title: Text(cart[i].product.name),
            subtitle: Text("₹${cart[i].product.price} x ${cart[i].qty}"),
            trailing: Text("₹${cart[i].product.price * cart[i].qty}", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        )),
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("To Pay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("₹${_getTotal()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C831F), foregroundColor: Colors.white),
              onPressed: _placeOrder, 
              child: const Text("Place Order (WhatsApp)"),
            ))
          ]),
        )
      ],
    );
  }

  // --- 3. ORDERS TAB ---
  Widget _buildOrders() {
    return const Center(child: Text("No orders yet. Place one via Cart!"));
  }

  // --- 4. ACCOUNT TAB ---
  Widget _buildAccount() {
    if(isAdmin) return _buildAdmin();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(userName ?? "Guest User", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(userPhone ?? "Not Logged In", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          if(userName == null) ElevatedButton(onPressed: _showLoginDialog, child: const Text("Login")),
          TextButton(onPressed: _showAdminLogin, child: const Text("Merchant Login")),
        ],
      ),
    );
  }

  Widget _buildAdmin() {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel"), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: ()=>setState(()=>isAdmin=false))]),
      body: Center(child: const Text("Admin Features (Add Product) go here")),
    );
  }
}
