import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _selectedImages = [];
  final TextEditingController _dateController = TextEditingController();
  Map<String, dynamic> _apiResponse = {}; // Save Response

  // Pick images function
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 5 foto!')),
      );
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (var img in images) {
        if (_selectedImages.length < 5) {
          if (kIsWeb) {
            final bytes = await img.readAsBytes();
            setState(() {
              _selectedImages.add(base64Encode(bytes));
            });
          } else {
            setState(() {
              _selectedImages.add(File(img.path));
            });
          }
        }
      }
    }
  }


  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }


  Future<void> _uploadData() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih setidaknya satu gambar!')),
      );
      return;
    }

    // URL API
    String getApiUrl() {
      if (kIsWeb) {
        return "http://127.0.0.1:51000/post"; // URL for Web
      } else {
        return "http://10.0.2.2:51000/post"; // URL for Emulator Android
      }
    }

    final String apiUrl = getApiUrl();


    List<Map<String, dynamic>> imageList = _selectedImages.map((img) {
      String base64Image = kIsWeb
          ? img // Base64 Web
          : base64Encode((img as File).readAsBytesSync());

      return {
        "uri": "data:image/png;base64,$base64Image",
        "matches": [
          {"text": "A photo or selfie in front of the customer’s location or store"},
          {"text": "A photo of the distributor’s product display as well as competitors’ products at the customer’s location"},
        ],
      };
    }).toList();

    final Map<String, dynamic> requestBody = {
      "data": imageList,
      "execEndpoint": "/rank"
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        setState(() {
          _apiResponse = jsonDecode(response.body);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The data has been uploaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload data! ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildApiResponse() {
    if (_apiResponse.isEmpty) {
      return const Text('No validation results available.');
    }

    List<dynamic> data = _apiResponse['data'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Validation Results:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...data.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;
          final matches = item['matches'] ?? [];
          return ExpansionTile(
            initiallyExpanded: true,
            title: Text('Image ${index + 1} Results'),
            children: matches.map<Widget>((match) {
              final clipScore = match['scores']['clip_score']['value'];
              final clipScoreCosine = match['scores']['clip_score_cosine']['value'];
              return ListTile(
                title: Text(match['text']),
                subtitle: Text(
                  'clip_score: $clipScore\nclip_score_cosine: $clipScoreCosine',
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI IMAGE DETECTION'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Visit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    _dateController.text =
                    "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'Customer Images (Max 5 Photos):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildImagePreview(),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.upload_file),
              label: const Text('Pick Images'),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _uploadData,
                child: const Text('Upload'),
              ),
            ),
            const SizedBox(height: 20),
            _buildApiResponse(), // Menampilkan hasil validasi
          ],
        ),
      ),
    );
  }

  // Preview untuk menampilkan gambar
  Widget _buildImagePreview() {
    return _selectedImages.isEmpty
        ? const Text('No Images Selected')
        : Wrap(
      spacing: 10,
      children: List.generate(
        _selectedImages.length,
            (index) => Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              margin: const EdgeInsets.all(4),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: kIsWeb
                      ? MemoryImage(base64Decode(_selectedImages[index]))
                      : FileImage(_selectedImages[index]) as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _removeImage(index),
              child: const CircleAvatar(
                backgroundColor: Colors.red,
                radius: 12,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
