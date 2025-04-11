import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artgallery_new/product/product.dart';
import 'dart:ui';

class ExplorePage extends StatefulWidget {
  final Function(Map<String, dynamic>)? addToWishlist;
  final Function(Map<String, dynamic>)? addToCart;

  const ExplorePage({super.key, this.addToWishlist, this.addToCart});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedCategoryIndex = 0;
  late final AnimationController _animationController;
  Set<String> favoritedArtworks = {};
  bool _isLoading = true;

  List<String> categories = [
    'All',
    'Portrait',
    'Digital',
    'Sculpture',
    'Photography',
    'Mixed Media'
  ];

  List<Map<String, dynamic>> artworks = [];
  List<Map<String, dynamic>> filteredArtworks = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _loadArtworks();
    _searchController.addListener(_filterArtworks);
  }

  Future<void> _loadArtworks() async {
    try {
      final snapshot = await _firestore
          .collection('artworks')
          .where('isAvailable', isEqualTo: true)
          .get();
          
      setState(() {
        artworks = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'imageUrl': data['imageUrl'],
            'title': data['title'],
            'artistId': data['artistId'],
            'artistName': data['artistName'], // Added artistName directly from artwork data
            'price': data['price'],
            'style': data['style'],
            'description': data['description'] ?? 'No description available',
            'isAvailable': data['isAvailable'] ?? true,
          };
        }).toList();
        filteredArtworks = artworks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading artworks: ${e.toString()}')),
      );
    }
    try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final wishlistSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .get();
          
      setState(() {
        favoritedArtworks = Set.from(wishlistSnapshot.docs.map((doc) => doc.id));
      });
    }
  } catch (e) {
    print('Error loading wishlist status: $e');
  }
  }

  void _filterArtworks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredArtworks = artworks
          .where((art) =>
              art['title'].toLowerCase().contains(query) ||
              (art['artistName']?.toLowerCase().contains(query) ?? false))
          .toList();
    });
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      if (index == 0) {
        filteredArtworks = artworks;
      } else {
        final categoryFilter = categories[index].toLowerCase();
        filteredArtworks = artworks.where((art) {
          final style = art['style']?.toString().toLowerCase() ?? '';
          return style.contains(categoryFilter);
        }).toList();
      }
    });
  }

 Future<void> _toggleFavorite(Map<String, dynamic> artwork) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle case where user is not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save favorites')),
      );
      return;
    }

    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(artwork['id']);

    if (favoritedArtworks.contains(artwork['id'])) {
      // Remove from wishlist
      await wishlistRef.delete();
      setState(() {
        favoritedArtworks.remove(artwork['id']);
      });
    } else {
      // Add to wishlist
      await wishlistRef.set({
        'title': artwork['title'],
        'artistName': artwork['artistName'],
        'imageUrl': artwork['imageUrl'],
        'price': artwork['price'],
        'style': artwork['style'],
        'addedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        favoritedArtworks.add(artwork['id']);
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(favoritedArtworks.contains(artwork['id'])
            ? "${artwork['title']} added to wishlist"
            : "${artwork['title']} removed from wishlist"),
        duration: const Duration(seconds: 2),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating wishlist: ${e.toString()}')),
    );
  }
}

  void _navigateToProductPage(Map<String, dynamic> artwork) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => buildProductPage(context, artwork['id']),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to logout?', 
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: const Text('Cancel', 
                  style: TextStyle(color: Colors.purpleAccent)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Logout', 
                  style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.purpleAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Added Profile Button
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutConfirmation,
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/wishlist'),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/img1.jpeg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.7),
                  BlendMode.darken,
                ),
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withOpacity(0.2),
              ),
            ),
          ),
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
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOutQuart,
                  )),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPLORE',
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 3,
                            color: Colors.purple[200],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Discover New\nMasterpieces',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.1, 1.0, curve: Curves.easeOutQuart),
                  )),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Search artists, artworks...",
                          hintStyle: TextStyle(color: Colors.white60),
                          prefixIcon: Icon(Icons.search, color: Colors.white60),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                ),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart),
                  )),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 16),
                    child: SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _selectCategory(index),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: _selectedCategoryIndex == index
                                    ? Colors.purple[200]
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: _selectedCategoryIndex == index
                                      ? Colors.purple[200]!
                                      : Colors.grey[600]!,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                categories[index],
                                style: TextStyle(
                                  color: _selectedCategoryIndex == index
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: _selectedCategoryIndex == index
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                      ),
                    ),
                    child: filteredArtworks.isEmpty
                        ? const Center(
                            child: Text(
                              'No artworks found',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: filteredArtworks.length,
                            itemBuilder: (context, index) {
                              final artwork = filteredArtworks[index];
                              return GestureDetector(
                                onTap: () => _navigateToProductPage(artwork),
                                child: _buildArtCard(artwork),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtCard(Map<String, dynamic> artwork) {
    final isFavorite = favoritedArtworks.contains(artwork['id']);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => _navigateToProductPage(artwork),
                  child: Hero(
                    tag: 'art-${artwork['id']}',
                    child: artwork['imageUrl'] != null
                        ? Image.network(
                            artwork['imageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white54,
                                  size: 50,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                color: Colors.white54,
                                size: 50,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(artwork),
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.purple[200] : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artwork['title'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      height: 2,
                      width: 15,
                      color: Colors.purple[200],
                      margin: const EdgeInsets.only(right: 6),
                    ),
                    Expanded(
                      child: Text(
                        artwork['artistName']?.toString() ?? 'Unknown Artist',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${artwork['price']?.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    color: Colors.purple[200],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (artwork['style'] != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailChip(artwork['style']),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
}