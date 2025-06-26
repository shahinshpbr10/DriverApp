import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/common/textstyles.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_searchable_dropdown/flutter_searchable_dropdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../common/color.dart';

class SmartClinicOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const SmartClinicOrderDetailPage({super.key, required this.order});

  @override
  State<SmartClinicOrderDetailPage> createState() => _SmartClinicOrderDetailPageState();
}

class _SmartClinicOrderDetailPageState extends State<SmartClinicOrderDetailPage> {
  String? selectedTestId;
  List<Map<String, dynamic>> addonTests = [];
  int addonPrice = 0;
  bool isUploading = false;
  late String status; // Dynamically fetched status from Firestore
  XFile? proofImage;
  final ImagePicker _picker = ImagePicker();



  Future<void> _addTestToBooking() async {
    if (selectedTestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a test first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('lab_tests').doc(selectedTestId).get();
    if (doc.exists) {
      final data = doc.data()!;
      addonTests.add(data);
      addonPrice += (data['PATIENT_RATE'] as num?)?.toInt() ?? 0;
      setState(() => selectedTestId = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _removeTest(int index) async {
    final test = addonTests[index];
    addonPrice -= (test['PATIENT_RATE'] as num?)?.toInt() ?? 0;
    addonTests.removeAt(index);
    setState(() {});
  }

  Future<void> _saveAddonTests() async {
    setState(() => isUploading = true);
    try {
      final docId = widget.order['documentId']; // ✅ get docId from the order map

      if (docId == null) {
        throw Exception("Booking document ID is missing");
      }

      await FirebaseFirestore.instance
          .collection('smartclinic_booking')
          .doc(docId)
          .update({
        'addon_tests': addonTests,
        'addon_price': addonPrice,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Add-on tests saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving tests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }
  @override
  void initState() {
    super.initState();
    status = widget.order['status'] ?? 'pending'; // Fetch current status from Firestore document
  }

  // This function updates the status and uploads the proof image if status is completed
  Future<void> _updateStatus() async {
    if (status == 'completed' && proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload proof image to complete the booking.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      String? proofImageUrl;

      // If status is 'completed' and image is selected, upload it to Firebase Storage
      if (status == 'completed' && proofImage != null) {
        final fileName = 'proofs/${widget.order['documentId']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        final uploadTask = await ref.putFile(File(proofImage!.path));
        proofImageUrl = await uploadTask.ref.getDownloadURL();
      }

      // Update Firestore document
      await FirebaseFirestore.instance.collection('smartclinic_booking')
          .doc(widget.order['documentId'])
          .update({
        'status': status,
        if (proofImageUrl != null) 'proof_image_url': proofImageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  // This function allows the user to pick an image from the gallery or camera
  Future<void> _pickProofImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery); // You can also use ImageSource.camera
    if (picked != null) {
      setState(() => proofImage = picked);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildOrderSummaryCard(),

                  const SizedBox(height: 16),  // Enhanced Add-on Tests Section
                  Card(
                    elevation: 0,

                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.white, Colors.grey[50]!],
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xff84CB17),
                                      Color(0xff6BA513),],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.add_circle, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Add-On Tests",
                                      style: AppTextStyles.bodyText.copyWith(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "Enhance your package with additional tests",
                                      style: AppTextStyles.smallBodyText.copyWith(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Test Selection Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.lightpacha, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.search, color: AppColors.lightpacha, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Select Test",
                                      style: AppTextStyles.bodyText.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Enhanced Dropdown Container
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!, width: 1),
                                  ),
                                  child: StreamBuilder(
                                    stream: FirebaseFirestore.instance.collection('lab_tests').snapshots(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return Container(
                                          padding: const EdgeInsets.all(20),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightpacha!),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                "Loading tests...",
                                                style: AppTextStyles.smallBodyText.copyWith(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      final docs = snapshot.data!.docs;

                                      return SearchableDropdown.single(
                                        hint: Row(
                                          children: [
                                            Icon(Icons.science, color: Colors.grey[500], size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Choose a test to add",
                                              style: AppTextStyles.smallBodyText.copyWith(
                                                color: Colors.grey[600],
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                        value: selectedTestId,
                                        items: docs.map((doc) {
                                          return DropdownMenuItem<String>(
                                            value: doc.id,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[100],
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Icon(Icons.biotech, color: Colors.blue[600], size: 16),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          doc['TEST_NAME'] ?? 'Unknown Test',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 14,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                        Text(
                                                          "₹${doc['PATIENT_RATE'] ?? 0}",
                                                          style: TextStyle(
                                                            color: Colors.green[600],
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() => selectedTestId = value);
                                        },
                                        isExpanded: true,
                                        iconEnabledColor: AppColors.lightpacha,
                                        style: const TextStyle(color: Colors.black87),
                                        underline: Container(),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Enhanced Add Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _addTestToBooking,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.lightpacha,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                      shadowColor: Colors.purple.withOpacity(0.3),
                                    ),
                                    child:Text(
                                      "Add Selected Test",
                                      style: AppTextStyles.bodyText.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

// Enhanced Selected Tests List
                  if (addonTests.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Card(
                        elevation: 0,
                        shadowColor: Colors.indigo.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: Column(
                            children: [
                              // Header with Total
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xff84CB17),
                                      Color(0xff6BA513),],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.list_alt, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Selected Tests",
                                            style: AppTextStyles.bodyText.copyWith(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            "${addonTests.length} test${addonTests.length > 1 ? 's' : ''} selected",
                                            style: AppTextStyles.smallBodyText.copyWith(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.currency_rupee, color: Colors.green[600], size: 18),
                                          Text(
                                            "$addonPrice",
                                            style: AppTextStyles.smallBodyText.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      
                              // Tests List
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: addonTests.length,
                                  separatorBuilder: (context, index) => Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.grey[300]!,
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  itemBuilder: (context, index) {
                                    final test = addonTests[index];
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Colors.grey[50]!, Colors.white],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey[200]!, width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Color(0xff84CB17),
                                                  Color(0xff6BA513),],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.blue.withOpacity(0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(Icons.science, color: Colors.white, size: 20),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  test['TEST_NAME'] ?? 'Unknown Test',
                                                  style: AppTextStyles.smallBodyText.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: Colors.black87,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green[100],
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    "₹${test['PATIENT_RATE'] ?? 0}",
                                                    style:AppTextStyles.smallBodyText.copyWith(
                                                      color: Colors.green[700],
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: IconButton(
                                              icon: Icon(Icons.delete_outline, color: Colors.red[600], size: 22),
                                              onPressed: () => _removeTest(index),
                                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                              tooltip: "Remove test",
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),



                    // Enhanced Save Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isUploading ? null : _saveAddonTests,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:AppColors.lightpacha,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: isUploading
                              ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                "Saving Tests...",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                              Text(
                                "Save Add-On Tests",
                                style: AppTextStyles.smallBodyText.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  buildStatusDropdown(),
                  // Patient Information Card
                  _buildPatientCard(),

                  const SizedBox(height: 16),

                  // Service Details Card
                  _buildServiceCard(),

                  const SizedBox(height: 16),

                  // Appointment Details Card
                  _buildAppointmentCard(),

                  const SizedBox(height: 16),

                  // Payment Information Card
                  _buildPaymentCard(),

                  // const SizedBox(height: 24),

                  // Action Buttons
                  // _buildActionButtons(),

                  const SizedBox(height: 32),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final status = widget.order['status'] ?? 'pending';
    GeoPoint? geoPoint = widget.order['location'] as GeoPoint?;
    double latitude = geoPoint?.latitude ?? 0.0;
    double longitude = geoPoint?.longitude ?? 0.0;



    // Responsive sizing
    double iconSize = width * 0.08;
    double headingFontSize = width * 0.05;
    double subTextFontSize = width * 0.032;
    double boxPadding = width * 0.035;

    return SliverAppBar(
      expandedHeight: width * 0.33, // ~268px on 800px height
      floating: false,
      pinned: true,
      backgroundColor: AppColors.lightpacha,
      leading: Container(
        margin: EdgeInsets.all(width * 0.02),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: iconSize * 0.9),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(width * 0.02),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.share, color: Colors.white, size: iconSize),
            onPressed: () {
              // Share functionality
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff84CB17),
                Color(0xff6BA513),
                Color(0xff5A8F0F),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: width * 0.08),
                Container(
                  padding: EdgeInsets.all(boxPadding),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
                SizedBox(height: width * 0.015),
                Text(
                  status.toUpperCase(),
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontSize: headingFontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: width * 0.006),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03,
                    vertical: width * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ID: ${widget.order['uid'] ?? 'N/A'}',
                    style: AppTextStyles.smallBodyText.copyWith(
                      color: Colors.white,
                      fontSize: subTextFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: width * 0.01),
                buildCompactContactWidget(
                  latitude: latitude,
                  longitude: longitude,
                  phoneNumber: widget.order['phoneNumber'],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      elevation: 0,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.indigo[50]!,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff84CB17),
                        Color(0xff6BA513),],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: AppTextStyles.bodyText.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Booked on ${_formatDate(widget.order['createdAt'])}',
                        style: AppTextStyles.smallBodyText.copyWith(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lightpacha,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Text(
                    '₹${widget.order['servicePrice'] ?? 0}',
                    style: AppTextStyles.smallBodyText.copyWith(
                      fontSize: 16,

                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Update Booking Status',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: status,
          items: ['pending', 'in-progress', 'completed'].map((status) {
            return DropdownMenuItem(value: status, child: Text(status.toUpperCase()));
          }).toList(),
          onChanged: (value) {
            setState(() => status = value!);
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Status',
          ),
        ),
        const SizedBox(height: 16),
        if (status == 'completed') ...[
          ElevatedButton.icon(
            onPressed: _pickProofImage,
            icon: const Icon(Icons.image),
            label: Text(proofImage == null ? 'Upload Proof Image' : 'Change Proof Image'),
          ),
          const SizedBox(height: 8),
          if (proofImage != null)
            Image.file(File(proofImage!.path), height: 100),
        ],
      ],
    );
  }


  Widget buildCompactContactWidget({
    required double latitude,
    required double longitude,
    required String phoneNumber,
  }) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Maps Button
          Expanded(
            child: GestureDetector(
              onTap: () => _openGoogleMaps(latitude, longitude),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    bottomLeft: Radius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Maps',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 30,
            color: Colors.grey.withOpacity(0.3),
          ),

          // Phone Button
          Expanded(
            child: GestureDetector(
              onTap: () => _makePhoneCall(phoneNumber),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Call',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Alternative version with just icons (even more compact)
  Widget buildCompactContactWidgetIconsOnly({
    required double latitude,
    required double longitude,
    required String phoneNumber,
  }) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Maps Button
          Expanded(
            child: GestureDetector(
              onTap: () => _openGoogleMaps(latitude, longitude),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    bottomLeft: Radius.circular(25),
                  ),
                ),
                child: Icon(
                  Icons.map_outlined,
                  color: Colors.blue[600],
                  size: 24,
                ),
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 30,
            color: Colors.grey.withOpacity(0.3),
          ),

          // Phone Button
          Expanded(
            child: GestureDetector(
              onTap: () => _makePhoneCall(phoneNumber),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: Icon(
                  Icons.phone_outlined,
                  color: Colors.green[600],
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Helper functions (same as before)
  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    try {
      await launchUrl(
        Uri.parse(googleMapsUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Error opening maps: $e');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      print('Error making phone call: $e');
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget buildStatusDropdown() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Title Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.assignment_turned_in,
                    color: AppColors.lightpacha,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Booking Status',
                      style: AppTextStyles.bodyText.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.grey[800],
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Manage your booking progress',
                      style: AppTextStyles.smallBodyText.copyWith(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Enhanced Dropdown Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    color: Colors.grey[50],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: status,
                    items: [
                      {'value': 'approved', 'color': Colors.orange, 'icon': Icons.check_circle_outline},
                      {'value': 'pending', 'color': Colors.amber, 'icon': Icons.schedule},
                      {'value': 'in-progress', 'color': Colors.blue, 'icon': Icons.work_outline},
                      {'value': 'completed', 'color': Colors.green, 'icon': Icons.task_alt},
                    ].map((statusItem) {
                      return DropdownMenuItem(
                        value: statusItem['value'] as String,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                statusItem['icon'] as IconData,
                                color: statusItem['color'] as Color,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                (statusItem['value'] as String).toUpperCase(),
                                style: AppTextStyles.bodyText.copyWith(
                                  color: statusItem['color'] as Color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => status = value!);
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintText: 'Select status',
                      hintStyle: AppTextStyles.bodyText.copyWith(color: Colors.grey[400]),
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Enhanced Image Upload Section
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: status == 'completed' ? null : 0,
              child: status == 'completed'
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proof of Completion',
                    style: AppTextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Image Upload Button
                  GestureDetector(
                    onTap: _pickProofImage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: proofImage == null ? Colors.green[50] : Colors.green[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            proofImage == null ? Icons.cloud_upload_outlined : Icons.edit,
                            color: Colors.green[600],
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            proofImage == null ? 'Upload Proof Image' : 'Change Proof Image',
                            style: AppTextStyles.bodyText.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Tap to ${proofImage == null ? 'select' : 'change'} image',
                            style: AppTextStyles.bodyText.copyWith(
                              color: Colors.green[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Image Preview
                  if (proofImage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(proofImage!.path),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              )
                  : const SizedBox.shrink(),
            ),

            // Enhanced Save Button
            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isUploading ? null : _updateStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUploading ? Colors.grey[300] : AppColors.lightpacha,
                  foregroundColor: Colors.white,
                  elevation: isUploading ? 0 : 4,
                  shadowColor: Colors.blue.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isUploading
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Updating...',
                      style: AppTextStyles.bodyText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save, size: 20),
                    const SizedBox(width: 8),
                     Text(
                      'Save Status',
                      style: AppTextStyles.bodyText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard() {
    return _buildModernCard(
      title: 'Patient Information',
      icon: Icons.person,
      iconColor: Colors.white,
      backgroundColor: AppColors.lightpacha,
      child: Column(
        children: [
          _buildModernInfoRow(Icons.badge, 'Name', widget.order['patientName'] ?? 'Unknown'),
          _buildModernInfoRow(Icons.phone, 'Phone', widget.order['phoneNumber'] ?? 'N/A'),
          _buildModernInfoRow(Icons.cake, 'Age', '${widget.order['age'] ?? 'N/A'} years'),
          _buildModernInfoRow(Icons.person_outline, 'Gender', widget.order['gender'] ?? 'N/A'),
          _buildModernInfoRow(Icons.group, 'Booking For', widget.order['bookingFor'] ?? 'N/A'),
          _buildModernInfoRow(Icons.location_on, 'Address', widget.order['address'] ?? 'N/A', isLast: true, isAddress: true),
        ],
      ),
    );
  }

  Widget _buildServiceCard() {
    return _buildModernCard(
      title: 'Service Details',
      icon: Icons.medical_services,
      iconColor: AppColors.
      white,
      backgroundColor:AppColors.lightpacha
      ,
      child: Column(
        children: [
          _buildModernInfoRow(Icons.science, 'Test Name', widget.order['serviceName'] ?? 'N/A'),
          _buildModernInfoRow(Icons.category, 'Type', widget.order['bookingType']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'N/A'),
          _buildModernInfoRow(Icons.inventory, 'Package', widget.order['isPackage'] == true ? 'Yes' : 'No', isLast: true),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard() {
    return _buildModernCard(
      title: 'Appointment Details',
      icon: Icons.schedule,
      iconColor: AppColors.white,
      backgroundColor: AppColors.lightpacha,
      child: Column(
        children: [
          _buildModernInfoRow(Icons.calendar_today, 'Date', _formatDate(widget.order['selectedDate'])),
          _buildModernInfoRow(Icons.access_time, 'Time Slot', widget.order['selectedTimeSlot'] ?? 'N/A'),
          _buildModernInfoRow(Icons.history, 'Booked On', _formatDate(widget.order['createdAt']), isLast: true),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return _buildModernCard(
      title: 'Payment Information',
      icon: Icons.payment,
      iconColor: AppColors.white,
      backgroundColor: AppColors.lightpacha,
      child: Column(
        children: [
          _buildModernInfoRow(Icons.credit_card, 'Payment Method',
              widget.order['selectedPaymentMethod']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'N/A'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.lightpacha,AppColors.lightpacha],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${widget.order['servicePrice'] ?? 0}',
                      style: AppTextStyles.bodyText.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.currency_rupee,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Download receipt functionality
            },
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('Download Receipt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Contact support functionality
            },
            icon: Icon(Icons.support_agent, color: Colors.grey[700]),
            label: const Text('Contact Support'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Widget child,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: AppTextStyles.bodyText.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value, {bool isLast = false, bool isAddress = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.smallBodyText.copyWith(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyText.copyWith(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              maxLines: isAddress ? 3 : 1,
              overflow: isAddress ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green[600]!;
      case 'pending':
        return Colors.orange[600]!;
      case 'cancelled':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime dateTime;

      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp.toString().contains('at')) {
        // Example: 21 June 2024 at 15:20:10
        String clean = timestamp.toString().replaceAll(' UTC+5:30', '');
        dateTime = DateFormat("d MMMM yyyy 'at' HH:mm:ss").parse(clean);
      } else {
        dateTime = DateTime.parse(timestamp.toString());
      }

      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }
}