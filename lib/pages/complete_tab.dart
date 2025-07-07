import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/common/color.dart';
import 'package:driver_app/common/textstyles.dart';
import 'package:flutter/material.dart';
import 'package:driver_app/app.dart';

class CompletedOrdersTab extends StatelessWidget {
  Stream<List<Map<String, dynamic>>> _listenToCompletedOrders() {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    List<Map<String, dynamic>> smartClinicOrders = [];
    List<Map<String, dynamic>> pharmacyOrders = [];

    void emitCombined() {
      final allOrders = [...smartClinicOrders, ...pharmacyOrders];

      allOrders.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime != null && bTime != null) {
          return bTime.compareTo(aTime);
        }
        return 0;
      });

      controller.add(allOrders);
    }

    // Smart Clinic listener
    FirebaseFirestore.instance
        .collection('smartclinic_booking')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snapshot) {
      smartClinicOrders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['source'] = 'smart-clinic';
        return data;
      }).toList();
      emitCombined();
    });

    // Pharmacy listener
    FirebaseFirestore.instance
        .collection('pharmacyorders')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .listen((snapshot) {
      pharmacyOrders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['source'] = 'pharmacy';
        return data;
      }).toList();
      emitCombined();
    });

    return controller.stream;
  }

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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _listenToCompletedOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                strokeWidth: width * 0.008,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: width * 0.16, color: Colors.red[300]),
                  SizedBox(height: height * 0.02),
                  Text('Something went wrong', style: AppTextStyles.bodyText.copyWith(fontSize: width * 0.045, fontWeight: FontWeight.w600, color: Colors.grey[800])),
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
                    padding: EdgeInsets.all(width * 0.06),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.hourglass_empty, size: width * 0.16, color: Colors.blue[300]),
                  ),
                  SizedBox(height: height * 0.03),
                  Text('No completed orders', style: AppTextStyles.bodyText.copyWith(fontSize: width * 0.05, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                  SizedBox(height: height * 0.01),
                  Text('Completed orders will appear here.', style: AppTextStyles.smallBodyText.copyWith(color: Colors.grey[600], fontSize: width * 0.04)),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(width * 0.05, height * 0.02, width * 0.05, height * 0.015),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(width * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.check_circle, color: Colors.blue[700], size: width * 0.05),
                    ),
                    SizedBox(width: width * 0.03),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Completed', style: AppTextStyles.bodyText.copyWith(fontSize: width * 0.045, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                        Text('${orders.length} orders completed', style: AppTextStyles.smallBodyText.copyWith(fontSize: width * 0.035, color: Colors.grey[600]))
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(width * 0.04, width * 0.04, width * 0.04, width * 0.2),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final isPharmacy = order['source'] == 'pharmacy';

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      curve: Curves.easeOutBack,
                      margin: EdgeInsets.only(bottom: width * 0.03),
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
                            padding: EdgeInsets.all(width * 0.04),
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
                                      padding: EdgeInsets.all(width * 0.025),
                                      decoration: BoxDecoration(
                                        color: isPharmacy ? Colors.deepOrange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isPharmacy ? Icons.local_pharmacy : Icons.medical_services,
                                        color: isPharmacy ? Colors.deepOrange : Colors.green,
                                        size: width * 0.05,
                                      ),
                                    ),
                                    SizedBox(width: width * 0.03),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            order['patientName'] ?? 'Unknown Patient',
                                            style: AppTextStyles.bodyText.copyWith(fontSize: width * 0.042, color: Colors.black87),
                                          ),
                                          SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: width * 0.02, vertical: height * 0.003),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'COMPLETED',
                                                  style: AppTextStyles.smallBodyText.copyWith(fontSize: width * 0.028, fontWeight: FontWeight.w600, color: Colors.blue[700]),
                                                ),
                                              ),
                                              SizedBox(width: width * 0.02),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: width * 0.02, vertical: height * 0.003),
                                                decoration: BoxDecoration(
                                                  color: isPharmacy
                                                      ? Colors.deepOrange.withOpacity(0.1)
                                                      : Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  isPharmacy ? 'Pharmacy' : 'Smart Clinic',
                                                  style: AppTextStyles.smallBodyText.copyWith(fontSize: width * 0.028, fontWeight: FontWeight.w500, color: isPharmacy ? Colors.deepOrange : Colors.green),
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
                                          style: AppTextStyles.smallBodyText.copyWith(fontSize: width * 0.045, fontWeight: FontWeight.w700, color: Colors.black87),
                                        ),
                                        if (order['timestamp'] != null)
                                          Text(
                                            _formatTimestamp(order['timestamp']),
                                            style: AppTextStyles.smallBodyText.copyWith(fontSize: width * 0.03, color: Colors.grey[600]),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: height * 0.015),
                                Container(
                                  padding: EdgeInsets.all(width * 0.03),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, size: width * 0.04, color: Colors.green[600]),
                                      SizedBox(width: width * 0.03),
                                      Expanded(
                                        child: Text(
                                          'Order Completed!',
                                          style: AppTextStyles.smallBodyText.copyWith(fontSize: width * 0.037, fontWeight: FontWeight.w500, color: Colors.green[700]),
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
            color: Colors.grey[50],
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Enhanced Header
              Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Title Section with Icon
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[600]!, Colors.blue[800]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Details',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Complete Order Information',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
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

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    SizedBox(height: 10),

                    // Organize order data into sections
                    ..._buildOrderSections(order),

                    SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOrderSections(Map<String, dynamic> order) {
    List<Widget> sections = [];

    // Filter out Firebase and technical fields
    Map<String, dynamic> filteredOrder = _filterOrder(order);

    // Define sections with their fields and icons
    Map<String, Map<String, dynamic>> sectionConfig = {
      'Basic Information': {
        'icon': Icons.info_outline,
        'color': Colors.blue[600]!,
        'fields': ['id', 'orderId', 'orderNumber', 'status', 'type']
      },
      'Customer Details': {
        'icon': Icons.person_outline,
        'color': Colors.green[600]!,
        'fields': ['customerName', 'patientName', 'userId', 'email', 'phone', 'phoneNumber']
      },
      'Order Items': {
        'icon': Icons.shopping_bag_outlined,
        'color': Colors.orange[600]!,
        'fields': ['items', 'medicines', 'products', 'serviceName', 'services']
      },
      'Payment Information': {
        'icon': Icons.payment,
        'color': Colors.purple[600]!,
        'fields': ['totalPrice', 'totalAmount', 'amount', 'servicePrice', 'price', 'paymentStatus', 'paymentMethod']
      },
      'Dates & Time': {
        'icon': Icons.schedule,
        'color': Colors.indigo[600]!,
        'fields': ['createdAt', 'updatedAt', 'orderDate', 'selectedDate', 'selectedTimeSlot', 'deliveryDate']
      },
      'Location': {
        'icon': Icons.location_on_outlined,
        'color': Colors.red[600]!,
        'fields': ['address', 'deliveryAddress', 'location', 'city', 'state', 'pincode']
      },
    };

    for (String sectionTitle in sectionConfig.keys) {
      var config = sectionConfig[sectionTitle]!;
      List<String> fields = config['fields'];

      // Find matching fields in the filtered order
      Map<String, dynamic> sectionData = {};
      for (String field in fields) {
        if (filteredOrder.containsKey(field) && filteredOrder[field] != null) {
          sectionData[field] = filteredOrder[field];
        }
      }

      if (sectionData.isNotEmpty) {
        sections.add(_buildSection(
          title: sectionTitle,
          icon: config['icon'],
          color: config['color'],
          data: sectionData,
        ));
        sections.add(SizedBox(height: 16));
      }
    }

    // Add any remaining fields that don't fit in predefined sections
    Map<String, dynamic> remainingFields = {};
    for (var entry in filteredOrder.entries) {
      bool found = false;
      for (var config in sectionConfig.values) {
        if ((config['fields'] as List<String>).contains(entry.key)) {
          found = true;
          break;
        }
      }
      if (!found && entry.value != null) {
        remainingFields[entry.key] = entry.value;
      }
    }

    if (remainingFields.isNotEmpty) {
      sections.add(_buildSection(
        title: 'Additional Information',
        icon: Icons.more_horiz,
        color: Colors.grey[600]!,
        data: remainingFields,
      ));
    }

    return sections;
  }

// Filter out Firebase and technical fields
  Map<String, dynamic> _filterOrder(Map<String, dynamic> order) {
    // Define fields to exclude (Firebase and technical fields)
    Set<String> excludedFields = {
      // Firebase specific
      'uid', 'docId', 'documentId', '_id', 'ref', 'reference','completedAt',
      // Firestore metadata
      'exists', 'metadata', 'fromCache', 'hasPendingWrites',
      // Technical fields
      'createdBy', 'updatedBy', 'deleted', 'active', 'enabled',
      'version', 'revision', 'hash', 'checksum',
      // Internal tracking
      'internalId', 'systemId', 'trackingId', 'sessionId','Completed At'
      // Debug fields
      'debug', 'test', 'temp', 'temporary', 'source','proof_image_url','location','selectedDate','CreatedAt'
    };

    Map<String, dynamic> filtered = {};

    for (var entry in order.entries) {
      String key = entry.key.toLowerCase();

      // Skip if key is in excluded list
      if (excludedFields.any((excluded) => key.contains(excluded.toLowerCase()))) {
        continue;
      }

      // Skip fields that look like Firebase paths or internal IDs
      if (key.contains('firebase') ||
          key.contains('firestore') ||
          key.startsWith('_') ||
          key.endsWith('_id') ||
          key.endsWith('id') && key.length > 10) {
        continue;
      }

      // Skip empty or null values
      if (entry.value == null ||
          entry.value.toString().trim().isEmpty ||
          entry.value.toString() == 'null') {
        continue;
      }

      filtered[entry.key] = entry.value;
    }

    return filtered;
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, dynamic> data,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          // Section Content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: data.entries.map((entry) => _buildDetailRow(
                key: entry.key,
                value: entry.value,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String key,
    required dynamic value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key
          SizedBox(
            width: 120,
            child: Text(
              _formatKey(key),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),

          // Separator
          Text(
            ': ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),

          // Value
          Expanded(
            child: _buildValueWidget(value),
          ),
        ],
      ),
    );
  }

  Widget _buildValueWidget(dynamic value) {
    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.asMap().entries.map((entry) {
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              '${entry.key + 1}. ${entry.value.toString()}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          );
        }).toList(),
      );
    } else if (value is Map) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: value.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                '${_formatKey(entry.key.toString())}: ${entry.value.toString()}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                ),
              ),
            );
          }).toList(),
        ),
      );
    } else {
      // Check if it's a price/money field
      bool isMoneyField = _isMoneyField(value.toString());

      return Text(
        value.toString(),
        style: TextStyle(
          fontSize: 15,
          fontWeight: isMoneyField ? FontWeight.w600 : FontWeight.w500,
          color: isMoneyField ? Colors.green[700] : Colors.grey[800],
        ),
      );
    }
  }

  String _formatKey(String key) {
    // Convert camelCase to Title Case
    return key.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ')
        .trim();
  }

  bool _isMoneyField(String value) {
    // Check if the value contains currency symbols or looks like a price
    return value.contains('₹') ||
        value.contains('\$') ||
        (RegExp(r'^\d+(\.\d{2})?$').hasMatch(value) && double.tryParse(value) != null);
  }}