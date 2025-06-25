import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/common/color.dart';
import 'package:driver_app/common/textstyles.dart';
import 'package:flutter/material.dart';

class CompletedOrdersTab extends StatelessWidget {
  // Fetch completed orders from Firestore
  Future<List<Map<String, dynamic>>> _fetchCompletedOrders() async {
    final List<Map<String, dynamic>> allOrders = [];

    final List<Map<String, String>> collections = [
      {'name': 'smartclinic_booking', 'type': 'smart-clinic'},
      {'name': 'pharmacyorders', 'type': 'pharmacy'},
    ];

    for (final collection in collections) {
      Query query = FirebaseFirestore.instance.collection(collection['name']!);

      if (collection['type'] == 'smart-clinic') {
        query = query.where('status', isEqualTo: 'completed');
      } else if (collection['type'] == 'pharmacy') {
        query = query.where('status', isEqualTo: 'completed');
      }

      final querySnapshot = await query.get();

      for (final doc in querySnapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['source'] = collection['type'];
        allOrders.add(data);
      }
    }

    allOrders.sort((a, b) {
      final aTime = a['timestamp'] as Timestamp?;
      final bTime = b['timestamp'] as Timestamp?;
      if (aTime != null && bTime != null) {
        return bTime.compareTo(aTime); // Sort by timestamp
      }
      return 0;
    });

    return allOrders;
  }

  // Format the timestamp to show time ago or exact date
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = timestamp is Timestamp ? timestamp.toDate() : DateTime.tryParse(timestamp) ?? DateTime.now();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<Map<String, dynamic>>>( // Fetch completed orders using FutureBuilder
        future: _fetchCompletedOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                strokeWidth: 3,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  SizedBox(height: 16),
                  Text('Something went wrong', style: AppTextStyles.bodyText.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                ],
              ),
            );
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.hourglass_empty, size: 64, color: Colors.blue[300]),
                  ),
                  SizedBox(height: 24),
                  Text('No completed orders', style: AppTextStyles.bodyText.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                  SizedBox(height: 8),
                  Text('Completed orders will appear here.',style: AppTextStyles.smallBodyText.copyWith(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.check_circle, color: Colors.blue[700], size: 20),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Completed', style: AppTextStyles.bodyText.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                        Text('${orders.length} orders completed', style: AppTextStyles.smallBodyText.copyWith(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final isPharmacy = order['source'] == 'pharmacy';

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      curve: Curves.easeOutBack,
                      margin: EdgeInsets.only(bottom: 12),
                      child: Material(
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            _showOrderDetails(context, order);
                          },
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isPharmacy ? Colors.deepOrange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isPharmacy ? Icons.local_pharmacy : Icons.medical_services,
                                        color: isPharmacy ? Colors.deepOrange : Colors.green,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order['patientName'] ?? 'Unknown Patient',
                                            style: AppTextStyles.bodyText.copyWith(fontSize: 16, color: Colors.black87),
                                          ),
                                          SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'COMPLETED',
                                                  style: AppTextStyles.smallBodyText.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.blue[700]),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isPharmacy
                                                      ? Colors.deepOrange.withOpacity(0.1)
                                                      : Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  isPharmacy ? 'Pharmacy' : 'Smart Clinic',
                                                  style: AppTextStyles.smallBodyText.copyWith(fontSize: 10, fontWeight: FontWeight.w500, color: isPharmacy ? Colors.deepOrange : Colors.green),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${isPharmacy ? (order['totalPrice'] ?? 0) : (order['servicePrice'] ?? 0)}',
                                          style: AppTextStyles.smallBodyText.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                                        ),
                                        if (order['timestamp'] != null)
                                          Text(
                                            _formatTimestamp(order['timestamp']),
                                            style: AppTextStyles.smallBodyText.copyWith(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Order Completed!',
                                          style: AppTextStyles.smallBodyText.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.green[700]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(20),
                  children: [
                    Text(
                      'Order Details',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.grey[800]),
                    ),
                    SizedBox(height: 20),
                    ...order.entries.map((entry) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              '${entry.key}:',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
