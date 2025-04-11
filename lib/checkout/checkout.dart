import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(List<Map<String, dynamic>>) onCartUpdated;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.onCartUpdated,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isProcessingPayment = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userAddress;
  double _shippingCost = 9.99; // Example shipping cost

  @override
  void initState() {
    super.initState();
    // Debug print to check cart items
    debugPrint('Cart Items in Checkout:');
    for (var item in widget.cartItems) {
      debugPrint('Item: ${item['title']}, Price: ${item['price']}, Type: ${item['price'].runtimeType}');
    }

    _fetchUserAddress();
  }

  Future<void> _fetchUserAddress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()?['address'] != null) {
        setState(() {
          _userAddress = doc.data()!['address'] as String;
        });
      }
    } catch (e) {
      debugPrint('Error fetching address: $e');
    }
  }

  double get subtotal {
    double sum = 0.0;
    for (var item in widget.cartItems) {
      final price = _parsePrice(item['price']);
      final quantity = (item['quantity'] ?? 1).toInt();
      sum += price * quantity;
    }
    return sum;
  }

  double get totalAmount => subtotal + _shippingCost;

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    
    if (price is num) {
      return price.toDouble();
    } else if (price is String) {
      // Remove any non-numeric characters except decimal point
      final cleanPrice = price.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleanPrice) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _createOrder() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Prepare items with parsed prices
      final orderItems = widget.cartItems.map((item) {
        return {
          'id': item['id'],
          'title': item['title'],
          'artistName': item['artistName'],
          'imageUrl': item['imageUrl'],
          'price': _parsePrice(item['price']),
          'quantity': item['quantity'] ?? 1,
        };
      }).toList();

      final orderData = {
        'userId': user.uid,
        'items': orderItems,
        'subtotal': subtotal,
        'shipping': _shippingCost,
        'totalAmount': totalAmount,
        'paymentMethod': 'cod',
        'status': 'pending',
        'address': _userAddress,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save order to Firestore
      await _firestore.collection('orders').add(orderData);

      // Clear user's cart
      await _firestore.collection('users').doc(user.uid).update({
        'cart': FieldValue.delete(),
      });

      // Update parent widget
      widget.onCartUpdated([]);

      setState(() => _isProcessingPayment = false);
      _showConfirmationDialog(
        'Order Placed',
        'Your order will be delivered soon!',
      );
    } catch (e) {
      setState(() => _isProcessingPayment = false);
      debugPrint('Error creating order: $e');
      _showErrorDialog('Order Failed', 'Error saving order: ${e.toString()}');
    }
  }

  void _processPayment() async {
    setState(() => _isProcessingPayment = true);
    await _createOrder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Checkout",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cart Items List
            Expanded(
              child: ListView.builder(
                itemCount: widget.cartItems.length,
                itemBuilder: (context, index) {
                  final item = widget.cartItems[index];
                  final price = _parsePrice(item['price']);
                  final quantity = (item['quantity'] ?? 1).toInt();
                  final itemTotal = price * quantity;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]?.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.purple[200]!.withOpacity(0.3),
                      ),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item['imageUrl']?.toString() ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white54,
                              ),
                            );
                          },
                        ),
                      ),
                      title: Text(
                        item['title']?.toString() ?? 'Untitled',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.purple[200],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Qty: $quantity',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '\$${itemTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Order Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900]?.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple[200]!.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal:', '\$${subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Shipping:', '\$${_shippingCost.toStringAsFixed(2)}'),
                  const Divider(color: Colors.grey, height: 24),
                  _buildSummaryRow(
                    'Total:',
                    '\$${totalAmount.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Address Section
            if (_userAddress != null) ...[
              const Text(
                "DELIVERY ADDRESS",
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900]?.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.purple[200]!.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _userAddress!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Payment Option (Only COD)
            const Text(
              "PAYMENT METHOD",
              style: TextStyle(
                color: Colors.purple,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentOption("Cash on Delivery", Icons.money),
            const SizedBox(height: 24),

            // Confirm Button
            ElevatedButton(
              onPressed: _isProcessingPayment ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: _isProcessingPayment
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "PLACE ORDER",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? Colors.purple[200] : Colors.white,
            fontSize: isTotal ? 22 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String name, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.purple[200],
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: TextStyle(
              color: Colors.purple[200],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.purple[200]!,
            width: 2,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              "OK",
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.red[400]!,
            width: 2,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.red[400],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "OK",
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}