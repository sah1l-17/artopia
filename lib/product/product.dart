import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artgallery_new/cart/cart.dart';
import 'dart:ui';

Widget buildProductPage(BuildContext context, String artworkId) {
  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance
        .collection('artworks')
        .doc(artworkId)
        .get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          backgroundColor: Color(0xFF0A0A0A),
          body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
        );
      }

      if (!snapshot.hasData || !snapshot.data!.exists) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: const Center(
            child: Text('Artwork not found', style: TextStyle(color: Colors.white)),
          ),
        );
      }

      final artworkData = snapshot.data!.data() as Map<String, dynamic>;
      return _ProductPageContent(
        artwork: {
          'id': artworkId,
          ...artworkData,
        },
      );
    },
  );
}

class _ProductPageContent extends StatefulWidget {
  final Map<String, dynamic> artwork;

  const _ProductPageContent({required this.artwork});

  @override
  _ProductPageContentState createState() => _ProductPageContentState();
}

class _ProductPageContentState extends State<_ProductPageContent>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _isAddingToCart = false;
  int _cartItemCount = 0;
  int? _currentItemQuantity;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      setState(() {
        _cartItemCount = cartSnapshot.docs.length;
        
        // Check if current artwork is in cart
        final currentItem = cartSnapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>?>().firstWhere(
          (doc) => doc?.id == widget.artwork['id'],
          orElse: () => null,
        );
        
        _currentItemQuantity = currentItem?.data()['quantity'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cart: ${e.toString()}')),
      );
    }
  }

  Future<void> _addToCart() async {
    setState(() => _isAddingToCart = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.pushNamed(context, '/login');
        return;
      }

      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(widget.artwork['id']);

      final artworkData = {
        ...widget.artwork,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Remove the 'id' field if it exists in the artwork data to avoid duplication
      artworkData.remove('id');

      await cartRef.set({
        ...artworkData,
        'quantity': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await _loadCartData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Added to cart"),
          backgroundColor: Colors.purple.shade700,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: _navigateToCart,
            textColor: Colors.white,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: ${e.toString()}')),
      );
    } finally {
      setState(() => _isAddingToCart = false);
    }
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: _navigateToCart,
              ),
              if (_cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image with blur
          if (artwork['imageUrl'] != null)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(artwork['imageUrl']),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.7),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),
            ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF0A0A0A).withOpacity(0.8),
                  const Color(0xFF0A0A0A),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Artist name and title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (artwork['artistName'] ?? 'Unknown Artist').toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 3,
                            color: Colors.purple[200],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          artwork['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hero image
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Hero(
                      tag: 'art-${artwork['id']}',
                      child: Container(
                        height: 350,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: artwork['imageUrl'] != null
                              ? Image.network(
                                  artwork['imageUrl'],
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.white54,
                                    size: 50,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  // Price & Cart Info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple[200]!),
                          ),
                          child: Text(
                            '\$${(artwork['price'] ?? 0).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.purple[200],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_currentItemQuantity != null)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(left: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.purple[200]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shopping_cart, color: Colors.purple, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'In cart: $_currentItemQuantity',
                                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Description
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]!.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purple[200]!.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "DESCRIPTION",
                          style: TextStyle(
                            color: Colors.purple,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          artwork['description'] ?? 'No description available',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Style & Availability
                  if (artwork['style'] != null)
                    Container(
                      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[900]!.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple[200]!.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          _buildDetailChip('Style: ${artwork['style']}'),
                          const SizedBox(width: 8),
                          _buildDetailChip('Available: ${artwork['isAvailable'] == true ? 'Yes' : 'No'}'),
                        ],
                      ),
                    ),

                  // Add to cart button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: GestureDetector(
                      onTap: _isAddingToCart ? null : _addToCart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple[400]!,
                              Colors.purple[800]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isAddingToCart
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_shopping_cart, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text(
                                    'ADD TO CART',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}