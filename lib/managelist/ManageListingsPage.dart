import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class ManageListingsPage extends StatefulWidget {
  const ManageListingsPage({super.key});

  @override
  _ManageListingsPageState createState() => _ManageListingsPageState();
}

class _ManageListingsPageState extends State<ManageListingsPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _artistId;
  late final AnimationController _animationController;

  List<Map<String, dynamic>> _artworks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _artistId = _auth.currentUser?.uid ?? '';
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    if (_artistId.isNotEmpty) {
      _fetchArtworks();
    }
  }

  Future<void> _fetchArtworks() async {
    try {
      final querySnapshot = await _firestore
          .collection('artworks')
          .where('artistId', isEqualTo: _artistId)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _artworks = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Untitled',
            'artistName': data['artistName'] ?? 'Unknown Artist',
            'price': data['price'] ?? 0.0,
            'style': data['style'] ?? 'Not specified',
            'imageUrl': data['imageUrl'],
            'description': data['description'] ?? '',
            'isAvailable': data['isAvailable'] ?? true,
            'createdAt': data['createdAt'],
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching artworks: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editArtwork(Map<String, dynamic> artwork) async {
    final titleController = TextEditingController(text: artwork['title']);
    final descriptionController = TextEditingController(text: artwork['description']);
    final priceController = TextEditingController(text: artwork['price'].toString());
    final styleController = TextEditingController(text: artwork['style']);
    final availableController = TextEditingController(text: artwork['isAvailable'].toString());

    final List<String> artStyles = [
      'Abstract',
      'Landscape',
      'Portrait',
      'Digital',
      'Surreal',
      'Minimalist',
      'Other'
    ];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0A0A0A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.purple[200]!.withOpacity(0.5), width: 1),
              ),
              title: const Text(
                'EDIT ARTWORK',
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: Colors.purple[200]),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple[200]!),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple[200]!),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      controller: titleController,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.purple[200]),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple[200]!),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple[200]!),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      controller: descriptionController,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Price (\$)',
                        labelStyle: TextStyle(color: Colors.purple[200]),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple[200]!),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple[200]!),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      controller: priceController,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: artwork['style'] ?? 'Other',
                      dropdownColor: const Color(0xFF0A0A0A),
                      decoration: InputDecoration(
                        labelText: 'Art Style',
                        labelStyle: TextStyle(color: Colors.purple[200]),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple[200]!),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple[200]!),
                        ),
                      ),
                      items: artStyles.map((style) {
                        return DropdownMenuItem<String>(
                          value: style,
                          child: Text(
                            style,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        styleController.text = value ?? 'Other';
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Available for sale: ',
                          style: TextStyle(color: Colors.purple[200]),
                        ),
                        Switch(
                          value: artwork['isAvailable'] ?? true,
                          activeColor: Colors.purple,
                          onChanged: (value) {
                            setState(() {
                              artwork['isAvailable'] = value;
                              availableController.text = value.toString();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text(
                    'SAVE CHANGES',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  onPressed: () async {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Title cannot be empty'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final price = double.tryParse(priceController.text);
                    if (price == null || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid price'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      await _firestore.collection('artworks').doc(artwork['id']).update({
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'price': price,
                        'style': styleController.text,
                        'isAvailable': availableController.text == 'true',
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      Navigator.of(context).pop();
                      _fetchArtworks();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Artwork updated successfully'),
                          backgroundColor: Colors.purple.shade700,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating artwork: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleAvailability(String artworkId, bool currentStatus) async {
    try {
      await _firestore.collection('artworks').doc(artworkId).update({
        'isAvailable': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _fetchArtworks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentStatus
                ? 'Artwork marked as unavailable'
                : 'Artwork marked as available',
          ),
          backgroundColor: Colors.purple.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating availability: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeArtwork(String artworkId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red.withOpacity(0.5), width: 1),
        ),
        title: const Text(
          'CONFIRM DELETE',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        content: const Text(
          'Are you sure you want to permanently delete this artwork?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'DELETE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('artworks').doc(artworkId).delete();
        setState(() {
          _artworks.removeWhere((artwork) => artwork['id'] == artworkId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Artwork deleted successfully'),
            backgroundColor: Colors.purple.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting artwork: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Background with blur effect
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.withOpacity(0.2),
                  const Color(0xFF0A0A0A),
                  const Color(0xFF0A0A0A),
                ],
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            )
                : _artworks.isEmpty
                ? Center(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.purple[200]?.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.image_search,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Artworks Yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload your first artwork to get started',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : RefreshIndicator(
              color: Colors.purpleAccent,
              onRefresh: _fetchArtworks,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _artworks.length,
                itemBuilder: (context, index) {
                  final artwork = _artworks[index];
                  final createdAt = artwork['createdAt'] as Timestamp?;
                  final date = createdAt?.toDate();
                  final formattedDate = date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'N/A';

                  return FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                            0.1 * (index % 4),
                            0.1 * (index % 4) + 0.6,
                            curve: Curves.easeOut
                        ),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: artwork['isAvailable'] ?
                            Colors.purple.withOpacity(0.2) :
                            Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // Artwork image as background with blur
                            if (artwork['imageUrl'] != null)
                              Container(
                                height: 200,
                                width: double.infinity,
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
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Container(color: Colors.black.withOpacity(0.2)),
                                ),
                              ),

                            // Gradient overlay
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                    Colors.black.withOpacity(0.9),
                                  ],
                                ),
                              ),
                            ),

                            // Content
                            Container(
                              height: 200,
                              child: Column(
                                children: [
                                  // Top section with image
                                  Expanded(
                                    child: Row(
                                      children: [
                                        // Artwork image
                                        Container(
                                          width: 120,
                                          margin: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
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
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Artwork details
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  artwork['title'],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.purple.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Colors.purple[200]!),
                                                      ),
                                                      child: Text(
                                                        '\$${artwork['price'].toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          color: Colors.purple[200],
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _buildDetailChip(artwork['style']),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Uploaded: $formattedDate',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Bottom section with buttons
                                  Container(
                                    height: 60,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[900]!.withOpacity(0.7),
                                      border: Border(
                                        top: BorderSide(color: Colors.purple[200]!.withOpacity(0.3), width: 1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Availability toggle
                                        Row(
                                          children: [
                                            Text(
                                              artwork['isAvailable'] ? 'Available' : 'Unavailable',
                                              style: TextStyle(
                                                color: artwork['isAvailable'] ? Colors.purple[200] : Colors.grey,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Switch(
                                              value: artwork['isAvailable'] ?? true,
                                              activeColor: Colors.purple,
                                              onChanged: (value) => _toggleAvailability(
                                                artwork['id'],
                                                artwork['isAvailable'] ?? true,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const Spacer(),

                                        // Action buttons
                                        IconButton(
                                          onPressed: () => _editArtwork(artwork),
                                          icon: const Icon(Icons.edit, color: Colors.white),
                                          tooltip: 'Edit Artwork',
                                        ),
                                        IconButton(
                                          onPressed: () => _removeArtwork(artwork['id']),
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Delete Artwork',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add_photo_alternate, color: Colors.white),
        onPressed: () {
          // This would navigate to an "Add Artwork" page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add artwork functionality to be implemented'),
              backgroundColor: Colors.purple,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}