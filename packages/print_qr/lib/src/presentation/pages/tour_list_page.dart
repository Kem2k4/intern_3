import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'pdf_preview_page.dart';

class TourListPage extends StatefulWidget {
  const TourListPage({super.key});

  @override
  State<TourListPage> createState() => _TourListPageState();
}

class _TourListPageState extends State<TourListPage> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('tours');
  List<Map<String, dynamic>> _tours = [];
  bool _isLoading = true;
  Set<String> _selectedTourIds = {}; // Track selected tours

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    try {
      final snapshot = await _databaseRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final tours = data.entries.map((entry) {
          final tourData = Map<String, dynamic>.from(entry.value as Map);
          tourData['id'] = entry.key;
          return tourData;
        }).toList();

        setState(() {
          _tours = tours;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading tours: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTour(String tourId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa tour này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _databaseRef.child(tourId).remove();
        setState(() {
          _tours.removeWhere((tour) => tour['id'] == tourId);
          _selectedTourIds.remove(tourId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tour thành công')),
          );
        }
      } catch (e) {
        debugPrint('Error deleting tour: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa tour: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: _tours.isEmpty
          ? const Center(
              child: Text(
                'Chưa có tour nào được tạo.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : Column(
              children: [
                Container(
                  color: Colors.blue,
                  child: Column(
                    children: [
                      if (_tours.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_selectedTourIds.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedTourIds.clear();
                                  });
                                },
                                icon: const Icon(Icons.clear, color: Colors.white),
                                label: const Text(
                                  'Bỏ chọn tất cả',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  if (_selectedTourIds.length == _tours.length) {
                                    _selectedTourIds.clear();
                                  } else {
                                    _selectedTourIds = _tours
                                        .map((tour) => tour['id']?.toString() ?? '')
                                        .where((id) => id.isNotEmpty)
                                        .toSet();
                                  }
                                });
                              },
                              icon: Icon(
                                _selectedTourIds.length == _tours.length
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: Colors.white,
                              ),
                              label: Text(
                                _selectedTourIds.length == _tours.length
                                    ? 'Bỏ chọn tất cả'
                                    : 'Chọn tất cả',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _tours.length,
                    itemBuilder: (context, index) {
                      final tour = _tours[index];
                      return _buildTourCard(tour);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: _selectedTourIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                final selectedTours = _tours.where((tour) => _selectedTourIds.contains(tour['id'])).toList();
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    insetPadding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 40.0, left: 8.0, right: 8.0, bottom: 8.0),
                          child: PdfPreviewPage(selectedTours: selectedTours),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              label: Text('Xuất PDF (${_selectedTourIds.length})'),
              icon: const Icon(Icons.picture_as_pdf),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  Widget _buildTourCard(Map<String, dynamic> tour) {
    final tourId = tour['id']?.toString() ?? '';
    final isSelected = _selectedTourIds.contains(tourId);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tour['tourName']?.toString() ?? 'Tên tour không có',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Ngày khởi hành:', tour['departureDate']?.toString() ?? 'N/A'),
                _buildInfoRow('Thời gian:', '${tour['duration']?.toString() ?? 'N/A'} ngày'),
                _buildInfoRow('Phương tiện:', tour['transport']?.toString() ?? 'N/A'),
                _buildInfoRow('Điểm khởi hành:', tour['departureLocation']?.toString() ?? 'N/A'),
                _buildInfoRow('Điểm đến:', tour['destination']?.toString() ?? 'N/A'),
                _buildInfoRow('Giá tiền:', tour['price'] != null ? '${tour['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ' : 'N/A'),
                if (tour['description'] != null && tour['description'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Mô tả: ${tour['description']}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                if (tour['mediaUrls'] != null && tour['mediaUrls'] is List && (tour['mediaUrls'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Số media: ${(tour['mediaUrls'] as List).length}',
                      style: const TextStyle(fontSize: 14, color: Colors.green),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Checkbox(
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedTourIds.add(tourId);
                  } else {
                    _selectedTourIds.remove(tourId);
                  }
                });
              },
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTour(tourId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}