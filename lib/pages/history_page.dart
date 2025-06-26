import 'package:driver_app/common/textstyles.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../app.dart';

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
              Container(
                margin: EdgeInsets.symmetric(horizontal: width * 0.05),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  style: AppTextStyles.smallBodyText,
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
    // same implementation — no size-specific widgets inside
    // Add MediaQuery-based adjustments if needed in content
    return Container(); // Placeholder for brevity
  }

  Widget _buildPharmacyContent(Map<String, dynamic> item) {
    return Container(); // Placeholder
  }

  Widget _buildClinicContent(Map<String, dynamic> item) {
    return Container(); // Placeholder
  }
}
