import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/common/color.dart';
import 'package:driver_app/common/textstyles.dart';
import 'package:driver_app/pages/pharmacyorderdetailspage.dart';
import 'package:driver_app/pages/smartclinicdetailspage.dart';
import 'package:flutter/cupertino.dart';
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

      if (collection['type'] == 'smart-clinic') {
        query = query.where('status', isEqualTo: 'approved');
      } else if (collection['type'] == 'pharmacy') {
        query = query.where('status', isEqualTo: 'approved');
      }

      final querySnapshot = await query.get();

      for (final doc in querySnapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        data['source'] = collection['type'];
        allOrders.add(data);
        final docid=doc.id;
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
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    CircularProgressIndicator(strokeWidth: 3),
                    const SizedBox(height: 16),
                    Text('Loading pending orders...', style: AppTextStyles.bodyText.copyWith(fontSize: 16, color: Colors.grey[600])),
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
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
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
                  Icon(Icons.inbox_outlined, size: 64, color: AppColors.lightpacha.withOpacity(0.05)),
                  const SizedBox(height: 24),
                  Text('No pending orders', style: AppTextStyles.bodyText.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                  const SizedBox(height: 8),
                  Text('All caught up! New orders will appear here.', style: AppTextStyles.smallBodyText.copyWith(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header section with better design
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.pending_actions, color: Colors.orange[700], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pending Orders', style: AppTextStyles.heading2.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                          Text('${orders.length} orders awaiting action', style: AppTextStyles.smallBodyText.copyWith(fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Order list view
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final isPharmacy = order['source'] == 'pharmacy';
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      curve: Curves.easeOutBack,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isPharmacy ? Colors.deepOrange.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isPharmacy ? AppColors.lightpacha.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isPharmacy ? Icons.local_pharmacy : Icons.medical_services,
                                      color: isPharmacy ? Colors.deepOrange : Colors.green,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order['patientName'] ?? 'Unknown Patient',
                                          style: AppTextStyles.bodyText.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isPharmacy ? Colors.deepOrange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isPharmacy ? 'Pharmacy Order' : 'Smart Clinic',
                                            style: AppTextStyles.smallBodyText.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: isPharmacy ? Colors.deepOrange : Colors.green),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${isPharmacy ? (order['totalPrice'] ?? 0) : (order['servicePrice'] ?? 0)}',
                                        style: AppTextStyles.bodyText.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                      if (order['timestamp'] != null)
                                        Text(
                                          _formatTimestamp(order['timestamp']),
                                          style: AppTextStyles.bodyText.copyWith(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isPharmacy ? Icons.medication : Icons.schedule,
                                      size: 18,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        isPharmacy
                                            ? (order['medicines']?.map((e) => e['name']).join(', ') ?? 'No medicines listed')
                                            : '${order['serviceName'] ?? 'Service'} • ${order['selectedTimeSlot'] ?? 'No time slot'}',
                                        style: AppTextStyles.smallBodyText.copyWith(fontSize: 14, color: Colors.grey[700], height: 1.3),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            title: Row(
                                              children: [
                                                Icon(Icons.info_outline, color: AppColors.lightpacha),
                                                const SizedBox(width: 8),
                                               Text(
                                                  'Feature Not Available',
                                                  style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            content: Text(
                                              'You can’t reject this right now.\n\nThis feature is still under development and will be available soon. Thank you for your patience!',
                                              style: AppTextStyles.smallBodyText.copyWith(fontSize: 15, height: 1.5),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:AppColors.lightpacha,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                ),
                                                child: Text('OK',style: AppTextStyles.bodyText,),
                                              ),
                                            ],
                                          ),
                                        );

                                      },
                                      icon: const Icon(Icons.close, size: 18),
                                      label: Text(
                                        'Reject',
                                        style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red[600],
                                        side: BorderSide(color: Colors.red[300]!),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  )
                        ,
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        if (isPharmacy) {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => PharmacyOrderDetailPage(order: order)));
                                        } else {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => SmartClinicOrderDetailPage(order: order)));
                                        }
                                      },
                                      icon: const Icon(Icons.check, size: 18,color: Colors.white,),
                                      label:  Text('Accept',style: AppTextStyles.bodyText.copyWith(color: Colors.white,fontWeight: FontWeight.w600),),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:  AppColors.lightpacha,
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
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


}
