import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../app.dart';
import '../common/color.dart';
import '../common/textstyles.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _allHistoryItems = [];
  List<Map<String, dynamic>> _filteredHistoryItems = [];
  bool _isLoading = true;
  bool _isDisposed = false;
  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();

    // Remove listener-based search to avoid rebuilds
    // Search will be handled on demand
  }

  void _onSearchChanged(String query) {
    if (_isDisposed) return;

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Set up new timer for debounced search
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (_isDisposed) return;

      final searchQuery = query.toLowerCase();
      if (_searchQuery != searchQuery) {
        _searchQuery = searchQuery;
        _filterHistoryItems();

        // Only rebuild the list, not the entire page
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  Future<void> _fetchHistoryData() async {
    if (_isDisposed) return;

    try {
      List<Map<String, dynamic>> historyItems = [];

      final pharmacySnapshot = await FirebaseFirestore.instance
          .collection('pharmacyorders')
          .where('status', isEqualTo: 'completed')
          .get();

      for (var doc in pharmacySnapshot.docs) {
        final data = doc.data();
        historyItems.add({
          'id': doc.id,
          'type': 'pharmacy',
          'patientName': data['patientName'] ?? '',
          'totalPrice': data['totalPrice'] ?? 0,
          'createdAt': data['createdAt'] as Timestamp,
          'updatedAt': data['updatedAt'] as Timestamp?,
          'medicines': data['medicines'] ?? [],
          'status': data['status'] ?? '',
        });
      }

      final clinicSnapshot = await FirebaseFirestore.instance
          .collection('smartclinic_booking')
          .where('status', isEqualTo: 'completed')
          .get();

      for (var doc in clinicSnapshot.docs) {
        final data = doc.data();
        historyItems.add({
          'id': doc.id,
          'type': 'clinic',
          'patientName': data['patientName'] ?? '',
          'serviceName': data['serviceName'] ?? '',
          'servicePrice': data['servicePrice'] ?? 0,
          'createdAt': data['createdAt'] as Timestamp,
          'selectedDate': data['selectedDate'] as Timestamp?,
          'selectedTimeSlot': data['selectedTimeSlot'] ?? '',
          'bookingType': data['bookingType'] ?? '',
          'address': data['address'] ?? '',
          'age': data['age'] ?? 0,
          'gender': data['gender'] ?? '',
          'phoneNumber': data['phoneNumber'] ?? '',
          'status': data['status'] ?? '',
        });
      }

      historyItems.sort((a, b) =>
          (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));

      if (!_isDisposed) {
        setState(() {
          _allHistoryItems = historyItems;
          _filteredHistoryItems = historyItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching history data: $e');
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterHistoryItems() {
    if (_searchQuery.isEmpty) {
      _filteredHistoryItems = List.from(_allHistoryItems);
    } else {
      _filteredHistoryItems = _allHistoryItems.where((item) {
        final patientName = (item['patientName'] ?? '').toString().toLowerCase();
        final serviceName = (item['serviceName'] ?? '').toString().toLowerCase();
        final medicines = item['medicines'] as List<dynamic>? ?? [];
        final medicineNames = medicines
            .map((med) => (med['name'] ?? '').toString().toLowerCase())
            .join(' ');

        return patientName.contains(_searchQuery) ||
            serviceName.contains(_searchQuery) ||
            medicineNames.contains(_searchQuery);
      }).toList();
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final isTablet = width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Delivery History',
          style: AppTextStyles.heading2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 26 : 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff84CB17),
                Color(0xff6BA513),
                Color(0xff5A8F0F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xff84CB17).withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        margin: EdgeInsets.only(top: height * 0.01),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: Column(
            children: [
              SizedBox(height: height * 0.02),

              // Search Bar with minimal rebuild approach
              // Container(
              //   margin: EdgeInsets.symmetric(horizontal: width * 0.05),
              //   decoration: BoxDecoration(
              //     color: Colors.grey[100],
              //     borderRadius: BorderRadius.circular(12),
              //     border: Border.all(color: Colors.grey[300]!),
              //   ),
              //   child: TextField(
              //     style: AppTextStyles.smallBodyText,
              //     controller: _searchController,
              //     onChanged: _onSearchChanged,
              //     decoration: InputDecoration(
              //       hintText: 'Search by patient name, service, or medicine...',
              //       prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              //       suffixIcon: _searchController.text.isNotEmpty
              //           ? IconButton(
              //         icon: Icon(Icons.clear, color: Colors.grey[600]),
              //         onPressed: () {
              //
              //           _onSearchChanged('');
              //         },
              //       )
              //           : null,
              //       border: InputBorder.none,
              //       contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              //     ),
              //   ),
              // ),

              SizedBox(height: height * 0.02),
              Expanded(
                child: _isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: Color(0xff84CB17),
                  ),
                )
                    : _filteredHistoryItems.isEmpty
                    ? _buildEmptyState(width)
                    : _buildHistoryList(width),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double width) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _searchQuery.isNotEmpty ? Icons.search_off : Icons.inbox_outlined,
          size: width * 0.2,
          color: Color(0xff84CB17).withOpacity(0.3),
        ),
        SizedBox(height: 16),
        Text(
          _searchQuery.isNotEmpty ? 'No Results Found' : 'No History Yet',
          style: AppTextStyles.smallBodyText.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        Text(
          _searchQuery.isNotEmpty
              ? 'Try searching with different keywords'
              : 'Your completed deliveries will appear here',
          textAlign: TextAlign.center,
          style: AppTextStyles.smallBodyText.copyWith(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(double width) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
      itemCount: _filteredHistoryItems.length,
      itemBuilder: (context, index) {
        final item = _filteredHistoryItems[index];
        return _buildHistoryCard(item);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    // Determine card type and display appropriate content
    bool isPharmacy = item['type'] == 'pharmacy';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isPharmacy ? Colors.purple : Color(0xff84CB17),
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with patient name and status indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isPharmacy ? Colors.purple : Color(0xff84CB17)).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPharmacy ? Icons.local_pharmacy : Icons.person_outline,
                        color: isPharmacy ? Colors.purple : Color(0xff84CB17),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['patientName'] ?? 'Unknown Patient',
                            style: AppTextStyles.bodyText.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.shade200,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Completed',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Service details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (isPharmacy) ...[
                        _buildDetailRow(
                          Icons.local_pharmacy,
                          'Type',
                          'Pharmacy Order',
                          Colors.purple,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.currency_rupee,
                          'Total Amount',
                          '₹${item['totalPrice'] ?? '0'}',
                          Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.medication,
                          'Medicines',
                          '${(item['medicines'] as List?)?.length ?? 0} items',
                          Colors.blue,
                        ),
                      ] else ...[
                        _buildDetailRow(
                          Icons.medical_services_outlined,
                          'Service',
                          item['serviceName'] ?? 'N/A',
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.currency_rupee,
                          'Amount',
                          '₹${item['servicePrice'] ?? '0'}',
                          Colors.green,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        'Order Date',
                        _formatDate(item['createdAt'] as Timestamp),
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Handle view details
                          _showDetailsBottomSheet(context, item);
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(
                            color: (isPharmacy ? Colors.purple : Color(0xff84CB17)).withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Handle reorder
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isPharmacy ? 'Reorder feature coming soon!' : 'Rebook feature coming soon!'),
                              backgroundColor: Color(0xff84CB17),
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(isPharmacy ? 'Reorder' : 'Rebook'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPharmacy ? Colors.purple : Color(0xff84CB17),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDetailsBottomSheet(BuildContext context, Map<String, dynamic> item) {
    bool isPharmacy = item['type'] == 'pharmacy';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
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
            // Header with drag indicator
            Container(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title Section
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPharmacy
                      ? [AppColors.lightpacha,AppColors.lightpacha]
                      : [AppColors.lightpacha,AppColors.lightpacha],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isPharmacy ? Colors.green : Colors.blue).withOpacity(0.3),
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
                      isPharmacy ? Icons.local_pharmacy : Icons.local_hospital,
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
                          isPharmacy ? 'Pharmacy Order' : 'Clinic Booking',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Details & Information',
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Patient Info Card
                    _buildInfoCard(
                      icon: Icons.person,
                      iconColor: Colors.orange[600]!,
                      title: 'Patient Information',
                      children: [
                        _buildInfoRow(
                          icon: Icons.account_circle,
                          label: 'Patient Name',
                          value: item['patientName'] ?? 'Not specified',
                        ),
                        _buildInfoRow(
                          icon: Icons.calendar_today,
                          label: 'Order Date',
                          value: _formatDate(item['createdAt'] as Timestamp),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    if (isPharmacy) ...[
                      // Pharmacy Order Card
                      _buildInfoCard(
                        icon: Icons.receipt_long,
                        iconColor: Colors.green[600]!,
                        title: 'Order Summary',
                        children: [
                          _buildInfoRow(
                            icon: Icons.attach_money,
                            label: 'Total Amount',
                            value: '₹${item['totalPrice']}',
                            valueColor: Colors.green[700],
                            valueWeight: FontWeight.bold,
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Medicines Card
                      _buildInfoCard(
                        icon: Icons.medical_services,
                        iconColor: Colors.green[600]!,
                        title: 'Medicines Ordered',
                        children: [
                          ...((item['medicines'] as List?) ?? []).map((med) =>
                              Container(
                                margin: EdgeInsets.only(bottom: 12),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.medication,
                                        size: 20,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            med['name'] ?? 'Unknown Medicine',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Quantity: ${med['quantity'] ?? 1}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Clinic Service Card
                      _buildInfoCard(
                        icon: Icons.medical_services,
                        iconColor: AppColors.lightpacha,
                        title: 'Service Details',
                        children: [
                          _buildInfoRow(
                            icon: Icons.healing,
                            label: 'Service',
                            value: item['serviceName'] ?? 'Not specified',
                          ),
                          _buildInfoRow(
                            icon: Icons.attach_money,
                            label: 'Amount',
                            value: '₹${item['servicePrice']}',
                            valueColor: AppColors.lightpacha,
                            valueWeight: FontWeight.bold,
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Appointment Card
                      _buildInfoCard(
                        icon: Icons.event,
                        iconColor: AppColors.lightpacha!,
                        title: 'Appointment Details',
                        children: [
                          if (item['selectedDate'] != null)
                            _buildInfoRow(
                              icon: Icons.calendar_today,
                              label: 'Date',
                              value: _formatDate(item['selectedDate'] as Timestamp),
                            ),
                          if (item['selectedTimeSlot'] != null)
                            _buildInfoRow(
                              icon: Icons.access_time,
                              label: 'Time Slot',
                              value: item['selectedTimeSlot'],
                            ),
                          if (item['address'] != null)
                            _buildInfoRow(
                              icon: Icons.location_on,
                              label: 'Address',
                              value: item['address'],
                            ),
                        ],
                      ),
                    ],

                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
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
          // Card Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
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
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
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
          // Card Content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor ?? Colors.grey[800],
                    fontWeight: valueWeight ?? FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}