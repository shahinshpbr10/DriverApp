import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/common/color.dart';
import 'package:driver_app/common/textstyles.dart';
import 'package:driver_app/pages/pharmacyorderdetailspage.dart';
import 'package:driver_app/pages/smartclinicdetailspage.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class InProgressOrdersTab extends StatelessWidget {
  Stream<List<Map<String, dynamic>>> _listenToInProgressOrders() {
    final controller = StreamController<List<Map<String, dynamic>>>();

    List<Map<String, dynamic>> smartClinicOrders = [];
    List<Map<String, dynamic>> pharmacyOrders = [];

    void emitCombined() {
      final combined = [...smartClinicOrders, ...pharmacyOrders];

      combined.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime != null && bTime != null) {
          return bTime.compareTo(aTime);
        }
        return 0;
      });

      controller.add(combined);
    }

    // Listen to smart clinic "in-progress" orders
    FirebaseFirestore.instance
        .collection('smartclinic_booking')
        .where('status', isEqualTo: 'in-progress')
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

    // Listen to pharmacy "pending" orders
    FirebaseFirestore.instance
        .collection('pharmacyorders')
        .where('status', isEqualTo: 'in-progress')
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
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;
    final cardMargin = size.height * 0.015;
    final iconSize = size.width * 0.05;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body:StreamBuilder<List<Map<String, dynamic>>>(
        stream: _listenToInProgressOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(strokeWidth: 3),
                    SizedBox(height: size.height * 0.02),
                    Text('Loading In-progress orders...',
                        style: AppTextStyles.bodyText.copyWith(
                          fontSize: size.width * 0.045,
                          color: Colors.grey[600],
                        )),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: size.width * 0.15, color: Colors.red[300]),
                  SizedBox(height: size.height * 0.02),
                  Text('Something went wrong',
                      style: AppTextStyles.bodyText.copyWith(
                        fontSize: size.width * 0.05,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      )),
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
                    padding: EdgeInsets.all(size.width * 0.07),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.hourglass_empty, size: size.width * 0.15, color: Colors.blue[300]),
                  ),
                  SizedBox(height: size.height * 0.03),
                  Text('No orders in progress',
                      style: AppTextStyles.bodyText.copyWith(
                        fontSize: size.width * 0.05,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      )),
                  SizedBox(height: size.height * 0.01),
                  Text('Active orders will appear here.',
                      style: AppTextStyles.smallBodyText.copyWith(
                        fontSize: size.width * 0.04,
                        color: Colors.grey[600],
                      )),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Container(
                  padding: EdgeInsets.all(size.width * 0.045),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(size.width * 0.025),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.access_time, color: Colors.blue[700], size: iconSize),
                      ),
                      SizedBox(width: size.width * 0.03),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('In Progress',
                              style: AppTextStyles.bodyText.copyWith(
                                fontSize: size.width * 0.045,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                              )),
                          Text('${orders.length} orders being processed',
                              style: AppTextStyles.smallBodyText.copyWith(
                                fontSize: size.width * 0.035,
                                color: Colors.grey[600],
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(padding, cardMargin, padding, size.height * 0.08),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final isPharmacy = order['source'] == 'pharmacy';

                    return Container(
                      margin: EdgeInsets.only(bottom: cardMargin),
                      child: Material(
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: EdgeInsets.all(padding),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(size.width * 0.025),
                                    decoration: BoxDecoration(
                                      color: isPharmacy ? Colors.deepOrange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isPharmacy ? Icons.local_pharmacy : Icons.medical_services,
                                      color: isPharmacy ? Colors.deepOrange : Colors.green,
                                      size: iconSize,
                                    ),
                                  ),
                                  SizedBox(width: size.width * 0.03),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(order['patientName'] ?? 'Unknown Patient',
                                            style: AppTextStyles.bodyText.copyWith(
                                              fontSize: size.width * 0.045,
                                              color: Colors.black87,
                                            )),
                                        SizedBox(height: size.height * 0.005),
                                        Row(
                                          children: [
                                            _buildTag('IN PROGRESS', Colors.blue[700]!, size),
                                            SizedBox(width: size.width * 0.02),
                                            _buildTag(
                                              isPharmacy ? 'Pharmacy' : 'Smart Clinic',
                                              isPharmacy ? Colors.deepOrange : Colors.green,
                                              size,
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
                                        style: AppTextStyles.bodyText.copyWith(
                                          fontSize: size.width * 0.045,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (order['timestamp'] != null)
                                        Text(
                                          _formatTimestamp(order['timestamp']),
                                          style: AppTextStyles.smallBodyText.copyWith(
                                            fontSize: size.width * 0.032,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: size.height * 0.015),
                              Row(
                                children: [
                                  SizedBox(
                                    width: size.width * 0.04,
                                    height: size.width * 0.04,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                                    ),
                                  ),
                                  SizedBox(width: size.width * 0.03),
                                  Expanded(
                                    child: Text(
                                      isPharmacy ? 'Preparing medicines...' : 'Processing appointment...',
                                      style: AppTextStyles.bodyText.copyWith(
                                        fontSize: size.width * 0.037,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: size.height * 0.015),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        isPharmacy ? PharmacyOrderDetailPage(order: order) : SmartClinicOrderDetailPage(order: order),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.check_circle, size: size.width * 0.045),
                                  label: Text('Mark as Complete',
                                      style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.lightpacha,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildTag(String text, Color color, Size size) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.02, vertical: size.height * 0.004),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.smallBodyText.copyWith(
          fontSize: size.width * 0.03,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
