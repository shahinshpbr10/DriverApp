import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/common/color.dart';
import 'package:driver_app/common/textstyles.dart';
import 'package:driver_app/pages/pharmacyorderdetailspage.dart';
import 'package:driver_app/pages/smartclinicdetailspage.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PendingOrdersTab extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _fetchPendingOrders() async {
    final List<Map<String, dynamic>> allOrders = [];
    final List<Map<String, String>> collections = [
      {'name': 'smartclinic_booking', 'type': 'smart-clinic'},
      {'name': 'pharmacyorders', 'type': 'pharmacy'},
    ];

    for (final collection in collections) {
      Query query = FirebaseFirestore.instance.collection(collection['name']!);

      query = query.where('status', isEqualTo: 'approved');

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
        return bTime.compareTo(aTime);
      }
      return 0;
    });

    return allOrders;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchPendingOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: width * 0.08,
                      height: width * 0.08,
                      child: const CircularProgressIndicator(strokeWidth: 3),
                    ),
                    SizedBox(height: height * 0.02),
                    Text('Loading pending orders...', style: AppTextStyles.bodyText.copyWith(fontSize: width * 0.045, color: Colors.grey[600])),
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
                  Icon(Icons.error_outline, size: width * 0.15, color: Colors.red[300]),
                  SizedBox(height: height * 0.02),
                  Text('Something went wrong', style: AppTextStyles.bodyText.copyWith(fontSize: width * 0.05, fontWeight: FontWeight.w600)),
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
                  Icon(Icons.inbox_outlined, size: width * 0.15, color: AppColors.lightpacha.withOpacity(0.1)),
                  SizedBox(height: height * 0.02),
                  Text('No pending orders', style: AppTextStyles.bodyText.copyWith(fontSize: width * 0.05, fontWeight: FontWeight.w600)),
                  SizedBox(height: height * 0.01),
                  Text('All caught up! New orders will appear here.',
                      style: AppTextStyles.smallBodyText.copyWith(fontSize: width * 0.04, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.045),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: height * 0.025),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(width * 0.025),
                        decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.pending_actions, size: width * 0.05, color: Colors.orange[700]),
                      ),
                      SizedBox(width: width * 0.03),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pending Orders',
                              style: AppTextStyles.heading2.copyWith(fontSize: width * 0.045, fontWeight: FontWeight.w700)),
                          Text('${orders.length} orders awaiting action',
                              style: AppTextStyles.smallBodyText.copyWith(fontSize: width * 0.035, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(width * 0.04, height * 0.02, width * 0.04, height * 0.1),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final isPharmacy = order['source'] == 'pharmacy';

                    return Container(
                      margin: EdgeInsets.only(bottom: height * 0.02),
                      child: Material(
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: EdgeInsets.all(width * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isPharmacy ? Colors.deepOrange.withOpacity(0.2) : Colors.green.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(width * 0.03),
                                    decoration: BoxDecoration(
                                      color: isPharmacy ? AppColors.lightpacha.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isPharmacy ? Icons.local_pharmacy : Icons.medical_services,
                                      size: width * 0.055,
                                      color: isPharmacy ? Colors.deepOrange : Colors.green,
                                    ),
                                  ),
                                  SizedBox(width: width * 0.03),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(order['patientName'] ?? 'Unknown Patient',
                                            style: AppTextStyles.bodyText.copyWith(fontSize: width * 0.045, fontWeight: FontWeight.bold)),
                                        SizedBox(height: height * 0.005),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: width * 0.025, vertical: height * 0.006),
                                          decoration: BoxDecoration(
                                            color: isPharmacy ? Colors.deepOrange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isPharmacy ? 'Pharmacy Order' : 'Smart Clinic',
                                            style: AppTextStyles.smallBodyText.copyWith(
                                              fontSize: width * 0.03,
                                              color: isPharmacy ? Colors.deepOrange : Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('₹${isPharmacy ? (order['totalPrice'] ?? 0) : (order['servicePrice'] ?? 0)}',
                                          style: AppTextStyles.bodyText.copyWith(fontSize: width * 0.05, fontWeight: FontWeight.w600)),
                                      Text(_formatTimestamp(order['timestamp']),
                                          style: AppTextStyles.smallBodyText.copyWith(fontSize: width * 0.03, color: Colors.grey[600])),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: height * 0.015),
                              Row(
                                children: [
                                  Icon(isPharmacy ? Icons.medication : Icons.schedule, size: width * 0.04, color: Colors.grey[600]),
                                  SizedBox(width: width * 0.025),
                                  Expanded(
                                    child: Text(
                                      isPharmacy
                                          ? (order['medicines']?.map((e) => e['name']).join(', ') ?? 'No medicines listed')
                                          : '${order['serviceName'] ?? 'Service'} • ${order['selectedTimeSlot'] ?? 'No time slot'}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.smallBodyText.copyWith(fontSize: width * 0.035, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: height * 0.02),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showNotAvailableDialog(context),
                                      icon: Icon(Icons.close, size: width * 0.045),
                                      label: Text('Reject', style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red[600],
                                        side: BorderSide(color: Colors.red[300]!),
                                        padding: EdgeInsets.symmetric(vertical: height * 0.016),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: width * 0.03),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => isPharmacy
                                                ? PharmacyOrderDetailPage(order: order)
                                                : SmartClinicOrderDetailPage(order: order),
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.check, size: width * 0.045, color: Colors.white),
                                      label: Text('Accept',
                                          style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.lightpacha,
                                        padding: EdgeInsets.symmetric(vertical: height * 0.016),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ],
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

  void _showNotAvailableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.lightpacha),
            SizedBox(width: 8),
            Text('Feature Not Available', style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'You can’t reject this right now.\n\nThis feature is still under development and will be available soon.',
          style: AppTextStyles.smallBodyText.copyWith(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: AppTextStyles.bodyText),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.lightpacha,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
