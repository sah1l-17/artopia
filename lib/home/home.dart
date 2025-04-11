import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artgallery_new/product/product.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animationController;
  late final AnimationController _pulseAnimationController;
  late final AnimationController _rotateAnimationController;
  int _currentPage = 0;
  bool _isEmailVerified = false;
  bool _isCheckingAuth = true;
  List<Map<String, dynamic>> _featuredArt = [];
  bool _isLoadingArtworks = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _rotateAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    // Load data and check auth
    _loadFeaturedArtworks();
    _checkAuthState();

    _pageController.addListener(() {
      final next = _pageController.page?.round() ?? 0;
      if (_currentPage != next) {
        setState(() => _currentPage = next);
      }
    });
  }

  Future<void> _loadFeaturedArtworks() async {
    try {
      final snapshot = await _firestore
          .collection('artworks')
          .where('isAvailable', isEqualTo: true)  // Changed from isFeatured to isAvailable
          .limit(4)
          .get();

      setState(() {
        _featuredArt = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'imageUrl': data['imageUrl'],
            'title': data['title'],
            'artistId': data['artistId'],  // Added artistId
            'artistName': data['artistName'],
            'style': data['style'],
            'price': data['price'],
            'description': data['description'],
          };
        }).toList();
        _isLoadingArtworks = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingArtworks = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading artworks: ${e.toString()}')),
      );
    }
  }

  Future<void> _checkAuthState() async {
    final user = _auth.currentUser;
    
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }

    // Check if email is verified
    await user.reload();
    final updatedUser = _auth.currentUser;
    setState(() {
      _isEmailVerified = updatedUser?.emailVerified ?? false;
      _isCheckingAuth = false;
    });

    // Start animations only after auth check
    await _animationController.forward();
    await _pulseAnimationController.repeat(reverse: true);
    await _rotateAnimationController.repeat();

    // Show verification reminder if needed
    if (!_isEmailVerified) {
      _showVerificationReminder();
    }
  }

  void _showVerificationReminder() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Verify Your Email',
          style: TextStyle(color: Colors.purpleAccent),
        ),
        content: const Text(
          'Please check your email for a verification link. You need to verify your email to access all features.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Later',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _auth.currentUser?.sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification email resent!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to resend: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Resend',
              style: TextStyle(color: Colors.purple[200]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _pulseAnimationController.dispose();
    _rotateAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth || _isLoadingArtworks) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.purpleAccent),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background with blur effect
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              final page = _pageController.hasClients ? _pageController.page ?? 0 : 0;
              final currentIndex = page.floor();
              final nextIndex = (currentIndex + 1) % _featuredArt.length;
              final pageFraction = page - currentIndex;

              return Stack(
                children: [
                  Opacity(
                    opacity: 1 - pageFraction.toDouble(),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(_featuredArt[currentIndex]['imageUrl']),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.6),
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
                  ),
                  Opacity(
                    opacity: pageFraction.toDouble(),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(_featuredArt[nextIndex]['imageUrl']),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.6),
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
                  ),
                ],
              );
            },
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

          // Animated decorative elements
          RotationTransition(
            turns: Tween(begin: 0.0, end: 1.0).animate(_rotateAnimationController),
            child: Opacity(
              opacity: 0.05,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.purple[300]!, Colors.transparent],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App title with user info
                _buildAppTitle(),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOutQuart,
                    )),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.purple[200]!, Colors.blue[300]!],
                          ).createShader(bounds),
                          child: const Text(
                            'ARTOPIA',
                            style: TextStyle(
                              fontSize: 16,
                              letterSpacing: 4,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Discover Art in\na New Dimension',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Explore curated collections from emerging and established artists from around the world.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Featured artwork carousel
                Expanded(
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Featured Artworks',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Row(
                                children: [
                                  for (int i = 0; i < _featuredArt.length; i++)
                                    AnimatedBuilder(
                                      animation: _pulseAnimationController,
                                      builder: (context, child) {
                                        final scale = i == _currentPage
                                            ? 1.0 + 0.2 * _pulseAnimationController.value
                                            : 1.0;
                                        return Transform.scale(
                                          scale: scale,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            height: 8,
                                            width: i == _currentPage ? 24 : 8,
                                            margin: const EdgeInsets.only(left: 4),
                                            decoration: BoxDecoration(
                                              color: i == _currentPage
                                                  ? Colors.purple[200]
                                                  : Colors.grey[700],
                                              borderRadius: BorderRadius.circular(4),
                                              boxShadow: i == _currentPage
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.purple[400]!.withOpacity(0.5),
                                                        blurRadius: 8,
                                                        spreadRadius: 2,
                                                      )
                                                    ]
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _featuredArt.length,
                            itemBuilder: (context, index) {
                              final isActive = index == _currentPage;
                              final artwork = _featuredArt[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutQuint,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 500),
                                        curve: Curves.easeOutQuint,
                                        margin: EdgeInsets.symmetric(
                                          vertical: isActive ? 0 : 20,
                                          horizontal: 10,
                                        ),
                                        child: _buildArtCard(artwork, isActive),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom actions
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.6, 1.0, curve: Curves.easeOutQuart),
                  )),
                  child: _buildBottomSection(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purple[300]!, Colors.purple[800]!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple[400]!.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.palette_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          const Text(
            'ARTOPIA',
            style: TextStyle(
              fontSize: 20,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
              ),
            ),
            child: FutureBuilder<String?>(
              future: _getUserName(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }
                final userName = snapshot.data ?? 'Guest';
                return Text(
                  'Welcome $userName',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

 Future<String?> _getUserName() async {
  final user = _auth.currentUser;
  if (user == null) return null;
  
  try {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final fullName = doc.data()?['name'] as String?;
      if (fullName != null && fullName.isNotEmpty) {
        return fullName.split(' ').first;
      }
    }
    
    // Fallback to display name
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!.split(' ').first;
    }
    
    return null;
  } catch (e) {
    debugPrint('Error fetching user name: $e');
    return null;
  }
}

 Widget _buildArtCard(Map<String, dynamic> artwork, bool isActive) {
  return GestureDetector(
    onTap: () {
      if (!_isEmailVerified) {
        _showVerificationReminder();
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => buildProductPage(context, artwork['id']),
        ),
      );
    },
    child: Hero(
      tag: 'art-${artwork['id']}',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              artwork['imageUrl'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.white54),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            if (isActive)
              AnimatedBuilder(
                animation: _rotateAnimationController,
                builder: (context, child) {
                  return Positioned(
                    top: -100 + 50 * _pulseAnimationController.value,
                    right: -100 + 20 * _pulseAnimationController.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    artwork['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        height: 2,
                        width: 30,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple[300]!, Colors.purple[100]!],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      Text(
                        artwork['artistName'] ?? 'Unknown Artist',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (artwork['style'] != null)
                          _buildDetailChip(artwork['style']),
                        const SizedBox(width: 8),
                        if (artwork['price'] != null)
                          _buildDetailChip('\$${artwork['price']}'),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  Widget _buildDetailChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isEmailVerified) {
                  _showVerificationReminder();
                  return;
                }
                Navigator.pushNamed(context, '/explore');
              },
              child: AnimatedBuilder(
                animation: _pulseAnimationController,
                builder: (context, child) {
                  return Container(
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
                          color: Colors.purple.withOpacity(
                              0.3 + 0.1 * _pulseAnimationController.value),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Explore Gallery',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedBuilder(
                          animation: _pulseAnimationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(3 * _pulseAnimationController.value, 0),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}