import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/common/color.dart';
import 'package:driver_app/common/textstyles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PharmacyOrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const PharmacyOrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> medicines = order['medicines'] ?? [];
    final String createdAt = _formatDate(order['createdAt']);
    final String updatedAt = _formatDate(order['updatedAt']);

    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.lightpacha,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.lightpacha,
                  AppColors.lightpacha.withOpacity(0.05),
                  AppColors.lightpacha,
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Patient Information Section
            _buildCard(
              context,
              children: [
                // _iconBox(
                //   icon: Icons.person,
                //   label: 'Patient Name',
                //   value: order['patientName'] ?? 'Unknown Patient',
                // ),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightpacha,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient Name',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order['patientName'] ?? 'Unknown Patient',
                            style: AppTextStyles.bodyText.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.02),
                _buildInfoRow(Icons.phone, 'Phone Number', order['phoneNumber'] ?? 'Not provided'),
                SizedBox(height: height * 0.015),
                _buildInfoRow(Icons.schedule, 'Order Created', createdAt),
                SizedBox(height: height * 0.015),
                _buildInfoRow(Icons.update, 'Last Updated', updatedAt),
              ],
            ),

            SizedBox(height: height * 0.02),

            /// Medicines List Section
            _buildCard(
              context,
              children: [
                Row(
                  children: [
                    _iconBox(Icons.medication_rounded, AppColors.lightpacha),
                    SizedBox(width: width * 0.03),
                    Expanded(
                      child: Text(
                        'Medicines Ordered',
                        style: AppTextStyles.bodyText.copyWith(
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.lightpacha.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${medicines.length} items',
                        style: AppTextStyles.bodyText.copyWith(
                          fontSize: width * 0.035,
                          fontWeight: FontWeight.w500,
                          color: AppColors.lightpacha,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.015),
                ..._buildMedicinesList(medicines, width),
              ],
            ),

            SizedBox(height: height * 0.02),

            /// Total Price Section
            _buildCard(
              context,
              padding: EdgeInsets.all(width * 0.05),
              background: AppColors.lightpacha,
              children: [
                Row(
                  children: [
                    _iconBox(Icons.payments_rounded, Colors.white.withOpacity(0.2)),
                    SizedBox(width: width * 0.04),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
                            style: AppTextStyles.bodyText.copyWith(
                              fontSize: width * 0.035,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '₹${order['totalPrice'] ?? 0}',
                            style: AppTextStyles.bodyText.copyWith(
                              fontSize: width * 0.08,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),

            SizedBox(height: height * 0.03),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMedicinesList(List<dynamic> meds, double width) {
    if (meds.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(width * 0.05),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.medication_outlined, size: width * 0.1, color: Colors.grey[400]),
              SizedBox(height: 8),
              Text('No medicines listed',
                  style: AppTextStyles.bodyText.copyWith(
                    fontSize: width * 0.04,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        )
      ];
    }

    return meds.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> med = entry.value;

      return Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            _indexCircle(index + 1, width),
            SizedBox(width: width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med['name'] ?? 'Unknown Medicine',
                    style: AppTextStyles.bodyText.copyWith(
                      fontSize: width * 0.045,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('Medicine',
                      style: AppTextStyles.smallBodyText.copyWith(
                        fontSize: width * 0.035,
                        color: Colors.grey[600],
                      )),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                '₹${med['price'] ?? 0}',
                style: AppTextStyles.bodyText.copyWith(
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
                ),
              ),
            )
          ],
        ),
      );
    }).toList();
  }

  Widget _buildCard(BuildContext context, {required List<Widget> children, EdgeInsets? padding, Color? background}) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: width * 0.04),
      padding: padding ?? EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        color: background ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        _iconBox(icon, Colors.deepOrange.withOpacity(0.1), iconColor: Colors.deepOrange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                )),
            SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.bodyText.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ]),
        )
      ],
    );
  }

  Widget _buildIconRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightpacha,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyText.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconBox(IconData icon, Color background, {Color iconColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _indexCircle(int index, double width) {
    return Container(
      width: width * 0.1,
      height: width * 0.1,
      decoration: BoxDecoration(
        color: AppColors.lightpacha.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '$index',
          style: AppTextStyles.bodyText.copyWith(
            color: AppColors.lightpacha,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        dateTime = DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
      }

      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    } catch (_) {
      return 'Invalid date';
    }
  }
}
