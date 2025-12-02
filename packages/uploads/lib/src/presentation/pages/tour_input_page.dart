import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'media_view_page.dart';

class TourInputPage extends StatefulWidget {
  const TourInputPage({super.key});

  @override
  State<TourInputPage> createState() => _TourInputPageState();
}

class _TourInputPageState extends State<TourInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _tourNameController = TextEditingController();
  final _departureDateController = TextEditingController();
  final _durationController = TextEditingController();
  final _transportController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _departureLocationController = TextEditingController();
  final _destinationController = TextEditingController();
  final _priceController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _mediaFiles = [];
  bool _isLoading = false;

  DateTime? _selectedDate;

  @override
  void dispose() {
    _tourNameController.dispose();
    _departureDateController.dispose();
    _durationController.dispose();
    _transportController.dispose();
    _descriptionController.dispose();
    _departureLocationController.dispose();
    _destinationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _departureDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickMedia() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultipleMedia();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _mediaFiles.addAll(pickedFiles);
        });
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
    });
  }

  void _viewMedia(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaViewPage(
          files: _mediaFiles,
          initialIndex: index,
        ),
      ),
    );
  }

  Future<List<String>> _uploadMedia(List<XFile> files) async {
    List<String> downloadUrls = [];
    final storageRef = FirebaseStorage.instance.ref();

    for (var file in files) {
      try {
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final Reference ref = storageRef.child('tour_media/$fileName');
        
        // Determine content type based on extension
        final String extension = file.path.split('.').last.toLowerCase();
        final String contentType = ['jpg', 'jpeg', 'png', 'webp'].contains(extension) 
            ? 'image/$extension' 
            : 'video/$extension';

        final UploadTask uploadTask = ref.putFile(
          File(file.path),
          SettableMetadata(contentType: contentType),
        );

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        debugPrint('Error uploading file ${file.name}: $e');
        // Continue uploading other files even if one fails
      }
    }
    return downloadUrls;
  }

  Future<void> _saveTourInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Upload media files
      final List<String> mediaUrls = await _uploadMedia(_mediaFiles);

      // 2. Prepare data
      final Map<String, dynamic> tourData = {
        'tourName': _tourNameController.text,
        'departureDate': _departureDateController.text,
        'duration': _durationController.text,
        'transport': _transportController.text,
        'departureLocation': _departureLocationController.text,
        'destination': _destinationController.text,
        'price': int.parse(_priceController.text),
        'description': _descriptionController.text,
        'mediaUrls': mediaUrls,
        'createdAt': ServerValue.timestamp,
      };

      // 3. Save to Realtime Database
      final DatabaseReference toursRef = FirebaseDatabase.instance.ref('tours');
      final DatabaseReference newTourRef = toursRef.push();
      
      tourData['id'] = newTourRef.key;
      
      await newTourRef.set(tourData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu thông tin thành công!')),
        );
        // Clear form
        _formKey.currentState!.reset();
        _tourNameController.clear();
        _departureDateController.clear();
        _durationController.clear();
        _transportController.clear();
        _descriptionController.clear();
        _departureLocationController.clear();
        _destinationController.clear();
        _priceController.clear();
        setState(() {
          _mediaFiles.clear();
          _selectedDate = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu thông tin: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _tourNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên tour',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên tour';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _departureDateController,
                    decoration: const InputDecoration(
                      labelText: 'Ngày khởi hành (dd/mm/yy)',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng chọn ngày khởi hành';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Thời lượng (N ngày N đêm)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập thời lượng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _transportController,
                    decoration: const InputDecoration(
                      labelText: 'Phương tiện di chuyển',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _departureLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Khởi hành tại',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Điểm đến',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Giá tiền (VNĐ)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập giá tiền';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Giá tiền phải là số';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả ngắn',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Hình ảnh / Video',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InkWell(
                        onTap: _pickMedia,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                        ),
                      ),
                      ...List.generate(_mediaFiles.length, (index) {
                        final file = _mediaFiles[index];
                        final isVideo = file.path.toLowerCase().endsWith('.mp4') || 
                                        file.path.toLowerCase().endsWith('.mov');
                        
                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _viewMedia(index),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: isVideo 
                                    ? Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(color: Colors.black),
                                          const Icon(Icons.play_circle_outline, color: Colors.white, size: 40),
                                        ],
                                      )
                                    : Image.file(
                                        File(file.path),
                                        fit: BoxFit.cover,
                                      ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removeMedia(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveTourInfo,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_isLoading ? 'Đang lưu...' : 'Lưu thông tin'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
