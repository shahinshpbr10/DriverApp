import 'package:driver_app/common/textstyles.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _allHistoryItems = [];
  List<Map<String, dynamic>> _filteredHistoryItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _filterHistoryItems();
      });
    });
  }

  Future<void> _fetchHistoryData() async {
    try {
      List<Map<String, dynamic>> historyItems = [];

      // Fetch pharmacy orders with status "completed"
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

      // Fetch smart clinic bookings with status "completed"
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

      // Sort by creation date (newest first)
      historyItems.sort((a, b) =>
          (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));

      setState(() {
        _allHistoryItems = historyItems;
        _filteredHistoryItems = historyItems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching history data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }


  void _filterHistoryItems() {
    if (_searchQuery.isEmpty) {
      _filteredHistoryItems = _allHistoryItems;
    } else {
      _filteredHistoryItems = _allHistoryItems.where((item) {
        final patientName = item['patientName'].toString().toLowerCase();
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Delivery History',
          style: AppTextStyles.heading2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
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
        margin: EdgeInsets.only(top: 8),
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
              SizedBox(height: 20),
              // Search Field
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(style: AppTextStyles.smallBodyText,
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by patient name, service, or medicine...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: Color(0xff84CB17),
                  ),
                )
                    : _filteredHistoryItems.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _searchQuery.isNotEmpty ? Icons.search_off : Icons.inbox_outlined,
          size: 80,
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

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredHistoryItems.length,
      itemBuilder: (context, index) {
        final item = _filteredHistoryItems[index];
        return _buildHistoryCard(item);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final isPharmacy = item['type'] == 'pharmacy';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Color(0xff84CB17).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPharmacy
                        ? Color(0xff84CB17).withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPharmacy ? Icons.local_pharmacy : Icons.medical_services,
                        size: 16,
                        color: isPharmacy ? Color(0xff84CB17) : Colors.blue,
                      ),
                      SizedBox(width: 4),
                      Text(
                        isPharmacy ? 'Pharmacy' : 'Clinic',
                        style: AppTextStyles.smallBodyText.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPharmacy ? Color(0xff84CB17) : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Completed',
                    style: AppTextStyles.smallBodyText.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[600],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Patient Name
            Text(
              item['patientName'],
              style: AppTextStyles.smallBodyText.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),

            // Content based on type
            if (isPharmacy) ...[
              _buildPharmacyContent(item),
            ] else ...[
              _buildClinicContent(item),
            ],

            SizedBox(height: 12),

            // Date and Price
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatDate(item['createdAt']),
                    style: AppTextStyles.smallBodyText.copyWith(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Text(
                  '₹${isPharmacy ? item['totalPrice'] : item['servicePrice']}',
                  style: AppTextStyles.smallBodyText.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff84CB17),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacyContent(Map<String, dynamic> item) {
    final medicines = item['medicines'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medicines:',
          style: AppTextStyles.smallBodyText.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4),
        ...medicines.take(3).map((medicine) => Padding(
          padding: EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(Icons.medication, size: 14, color: Colors.grey[500]),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  medicine['name'] ?? '',
                  style: AppTextStyles.smallBodyText.copyWith(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Text(
                '₹${medicine['price'] ?? 0}',
                style: AppTextStyles.smallBodyText.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        )).toList(),
        if (medicines.length > 3)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '+${medicines.length - 3} more medicines',
              style: AppTextStyles.smallBodyText.copyWith(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildClinicContent(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.medical_services, size: 16, color: Colors.blue),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                item['serviceName'],
                style: AppTextStyles.smallBodyText.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        if (item['selectedDate'] != null) ...[
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
              SizedBox(width: 6),
              Text(
                '${_formatDate(item['selectedDate'])} - ${item['selectedTimeSlot']}',
                style: AppTextStyles.smallBodyText.copyWith(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
        ],
        Row(
          children: [
            Icon(Icons.category, size: 14, color: Colors.grey[500]),
            SizedBox(width: 6),
            Text(
              item['bookingType'].toString().replaceAll('_', ' ').toUpperCase(),
              style: AppTextStyles.smallBodyText.copyWith(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}