import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class UploadArtworkPage extends StatefulWidget {
  const UploadArtworkPage({super.key});

  @override
  _UploadArtworkPageState createState() => _UploadArtworkPageState();
}

class _UploadArtworkPageState extends State<UploadArtworkPage> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final AnimationController _animationController;
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _artistNameController = TextEditingController();
  
  bool _isUploading = false;
  bool _isImageValid = false;

  final List<String> _artStyles = [
    'Abstract',
    'Landscape',
    'Portrait',
    'Digital',
    'Surreal',
    'Minimalist'
  ];
  String? _selectedStyle;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    
    // Fetch current user's display name if available
    final user = _auth.currentUser;
    if (user != null && user.displayName != null) {
      _artistNameController.text = user.displayName!;
    }
  }

  Future<void> _uploadArtwork() async {
    if (!_validateForm()) return;

    setState(() => _isUploading = true);

    try {
      await _firestore.collection('artworks').add({
        'artistId': _auth.currentUser!.uid,
        'artistName': _artistNameController.text,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'style': _selectedStyle,
        'imageUrl': _imageUrlController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'sales': 0,
        'isAvailable': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Artwork published successfully!'),
          backgroundColor: Colors.purple.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  bool _validateForm() {
    if (_titleController.text.isEmpty) {
      _showErrorDialog('Please enter artwork title');
      return false;
    }
    if (_artistNameController.text.isEmpty) {
      _showErrorDialog('Please enter artist name');
      return false;
    }
    if (!_isImageValid) {
      _showErrorDialog('Please enter a valid image URL');
      return false;
    }
    if (_priceController.text.isEmpty || double.tryParse(_priceController.text) == null) {
      _showErrorDialog('Please enter a valid price');
      return false;
    }
    if (_selectedStyle == null) {
      _showErrorDialog('Please select an art style');
      return false;
    }
    return true;
  }

  void _checkImageUrl() {
    final url = _imageUrlController.text;
    setState(() {
      _isImageValid = url.startsWith('https://') && 
          (url.endsWith('.jpg') || 
           url.endsWith('.png') || 
           url.endsWith('.jpeg'));
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Validation Error',
          style: TextStyle(color: Colors.purpleAccent),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: Colors.purple[200]),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _imageUrlController.clear();
      _selectedStyle = null;
      _isImageValid = false;
      // Don't clear artist name as it's likely to be reused
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Animated decorative elements
          Positioned(
            top: -150,
            right: -150,
            child: Opacity(
              opacity: 0.15,
              child: Container(
                width: 300,
                height: 300,
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
            child: _isUploading
                ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOutQuart,
                      )),
                      child: FadeTransition(
                        opacity: _animationController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [Colors.purple[200]!, Colors.blue[300]!],
                                    ).createShader(bounds),
                                    child: const Text(
                                      'SHARE YOUR ART',
                                      style: TextStyle(
                                        fontSize: 14,
                                        letterSpacing: 3,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Create Your\nMasterpiece Listing',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Showcase your art to collectors around the world with detailed information and imagery.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                            // Image URL Section
                            _buildImageUrlSection(),

                            const SizedBox(height: 20),
                            
                            // Artwork Details Form
                            _buildArtworkDetailsForm(),

                            // Upload Button
                            const SizedBox(height: 24),
                            _buildUploadButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUrlSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple[200]!.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ARTWORK IMAGE",
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _imageUrlController,
                  label: 'Image URL (https://)',
                  icon: Icons.link,
                  onChanged: (_) => _checkImageUrl(),
                ),
              ],
            ),
          ),
          if (_imageUrlController.text.isNotEmpty)
            Container(
              height: 250,
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isImageValid ? Colors.green[400]! : Colors.red[400]!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isImageValid 
                      ? Colors.green.withOpacity(0.2) 
                      : Colors.red.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _isImageValid
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        _imageUrlController.text,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          return progress == null
                              ? child
                              : Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.purple[200],
                                    strokeWidth: 2,
                                  ),
                                );
                        },
                        errorBuilder: (_, __, ___) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, 
                                size: 50, 
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Image failed to load',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, 
                            size: 50, 
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Invalid image URL',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'URL must start with https:// and end with .jpg, .png, or .jpeg',
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildArtworkDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple[200]!.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ARTWORK DETAILS",
            style: TextStyle(
              color: Colors.purple,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _artistNameController,
            label: 'Artist Name',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _titleController,
            label: 'Artwork Title',
            icon: Icons.title,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            icon: Icons.description,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _priceController,
                  label: 'Price (\$)',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Art Style Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[800]!.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purple.withOpacity(0.3),
              ),
            ),
            child: DropdownButtonFormField<String>(
              dropdownColor: Colors.grey[850],
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.brush, color: Colors.purple),
                labelText: 'Art Style',
                labelStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              value: _selectedStyle,
              items: _artStyles
                  .map((style) => DropdownMenuItem(
                        value: style,
                        child: Text(
                          style,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStyle = value;
                });
              },
              icon: const Icon(Icons.arrow_drop_down, color: Colors.purple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.purple),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: _isUploading ? null : _uploadArtwork,
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
        child: _isUploading
            ? CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.publish, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'PUBLISH ARTWORK',
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
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _artistNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}