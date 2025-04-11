import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:artgallery_new/login/login.dart';
import 'package:artgallery_new/welcome/welcome.dart';
import 'package:artgallery_new/signup/signup.dart';
import 'package:artgallery_new/home/home.dart';
import 'package:artgallery_new/explore/explore.dart';
import 'package:artgallery_new/product/product.dart'; // buildProductPage should be here
import 'package:artgallery_new/cart/cart.dart';
import 'package:artgallery_new/checkout/checkout.dart';
import 'package:artgallery_new/wishlist/wishlist.dart';
import 'package:artgallery_new/profile/profile.dart';
import 'package:artgallery_new/artist_dashboard/artist_dashboard.dart';
import 'package:artgallery_new/upload_artist/UploadArtworkPage.dart';
import 'package:artgallery_new/managelist/ManageListingsPage.dart';
import 'package:artgallery_new/ordermanagement/ordermanagement.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';


import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e) {
    print("Firebase initialization error: $e");
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Firebase initialization failed')),
      ),
    ));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Map<String, dynamic>> cartItems = [];
  User? _currentUser;
  bool _isLoading = true;
  bool _isArtist = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await loadCartData();
    _setupAuthListener();
  }

  Future<void> loadCartData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString('cart_data');

      if (cartString != null && cartString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cartString);
        setState(() {
          cartItems =
              decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading cart data: $e");
    }
  }

  Future<void> _checkIfArtist() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isArtist = prefs.getBool('is_artist') ?? false;
      });
    } else {
      setState(() {
        _isArtist = false;
      });
    }
  }

void _setupAuthListener() {
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (mounted) {
      setState(() {
        _currentUser = user;
      });

      if (user != null) {
        // ✅ Create or merge Firestore user profile
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userRef.set({
          'name': user.displayName ?? '',
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await _checkIfArtist();
      setState(() {
        _isLoading = false;
      });
    }
  });
}


  Future<void> saveCartData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cart_data', jsonEncode(cartItems));
    } catch (e) {
      debugPrint("Error saving cart data: $e");
    }
  }

  void addToCart(Map<String, dynamic> item) {
    setState(() {
      final existingIndex =
          cartItems.indexWhere((cartItem) => cartItem['id'] == item['id']);
      if (existingIndex >= 0) {
        cartItems[existingIndex]['quantity'] =
            (cartItems[existingIndex]['quantity'] ?? 1) + 1;
      } else {
        cartItems.add({...item, 'quantity': 1});
      }
      saveCartData();
    });
  }

  void updateCart(List<Map<String, dynamic>> updatedCart) {
    setState(() {
      cartItems = updatedCart;
    });
    saveCartData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Art Gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple.shade700,
          primary: Colors.purple.shade700,
        ),
        brightness: _isArtist ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: _isArtist ? Colors.black : null,
        appBarTheme: _isArtist
            ? const AppBarTheme(
                backgroundColor: Colors.black,
                elevation: 0,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        bottomNavigationBarTheme: _isArtist
            ? const BottomNavigationBarThemeData(
                backgroundColor: Colors.black,
                selectedItemColor: Colors.purple,
                unselectedItemColor: Colors.white70,
              )
            : null,
      ),
      home: _getInitialPage(),
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/explore': (context) => const ExplorePage(),
        '/wishlist': (context) => const WishlistPage(),
        '/profile': (context) => const ProfilePage(),
        '/cart': (context) => const CartPage(),
        '/checkout': (context) => CheckoutPage(
              cartItems: cartItems,
              onCartUpdated: updateCart,
            ),
        '/artist_dashboard': (context) => const ArtistHomeNavigation(),
      },
      onGenerateRoute: (settings) {
        // Login route with callback
        if (settings.name == '/login') {
          return MaterialPageRoute(
            builder: (context) => LoginPage(
              onLoginSuccess: () {
                _checkIfArtist().then((_) {
                  Navigator.pushReplacementNamed(
                      context, _isArtist ? '/artist_dashboard' : '/home');
                });
              },
            ),
          );
        }

        // Handle /product/:id
        if (settings.name != null && settings.name!.startsWith('/product/')) {
          final productId = settings.name!.replaceFirst('/product/', '');
          return MaterialPageRoute(
            builder: (context) => buildProductPage(context, productId),
          );
        }

        return null; // Unknown route
      },
    );
  }

  Widget _getInitialPage() {
    if (_currentUser == null) {
      return const WelcomePage();
    } else {
      return _isArtist ? const ArtistHomeNavigation() : const HomePage();
    }
  }
}

class ArtistHomeNavigation extends StatefulWidget {
  const ArtistHomeNavigation({super.key});

  @override
  State<ArtistHomeNavigation> createState() => _ArtistHomeNavigationState();
}

class _ArtistHomeNavigationState extends State<ArtistHomeNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    AdminDashboardPage(),
    UploadArtworkPage(),
    ManageListingsPage(),
    OrderManagementPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = _selectedIndex.clamp(0, _pages.length - 1);
    return Scaffold(
      body: _pages[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        currentIndex: safeIndex,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Manage Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
        ],
      ),
    );
  }
}
