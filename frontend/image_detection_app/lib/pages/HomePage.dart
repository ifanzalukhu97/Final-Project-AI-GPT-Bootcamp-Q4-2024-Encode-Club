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
  Map<String, dynamic> _apiResponse = {}; // Simpan hasil API

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
        const SnackBar(content: Text('Select the image')),
      );
      return;
    }

    String getApiUrl() {
      if (kIsWeb) {
        return "http://127.0.0.1:51000/post";
      } else {
        return "http://10.0.2.2:51000/post";
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
          const SnackBar(content: Text('Data uploaded')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data failed to uploaded! ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  String _validateTargets(List<dynamic> data) {
    bool hasSelfie = false;
    bool hasDistributorProduct = false;

    print('Isi data: $data');
    for (var item in data) {
      var matches = item['matches'] ?? [];
      for (var match in matches) {
        String text = match['text'] ?? '';
        double clipScore = match['scores']?['clip_score']?['value'] ?? 0.0;

        text = text.replaceAll('’', "'"); //
        print('Item: $item');
        print('Matches: $matches');

        if (text.contains("A photo or selfie in front of the customer's location or store") &&
            clipScore > 0.5) {
          hasSelfie = true;
        }

        if (text.contains("A photo of the distributor's product display as well as competitors' products at the customer's location") &&
            clipScore > 0.5) {
          hasDistributorProduct = true;
        }
      }
    }

    if (hasSelfie && hasDistributorProduct) {
      return "Target Achieved";
    }
    return "Target Not Achieved";
  }


  // Widget _buildApiResponse() {
  //   if (_apiResponse.isEmpty) {
  //     return const Text('No validation results available.');
  //   }
  //
  //   List<dynamic> data = _apiResponse['data'] ?? [];
  //   String validationResult = _validateTargets(data);
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Validation Results:',
  //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //       ),
  //       const SizedBox(height: 10),
  //       Text(
  //         'Status: $validationResult',
  //         style: TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.bold,
  //           color: validationResult == "Target Achieved" ? Colors.green : Colors.red,
  //         ),
  //       ),
  //       const SizedBox(height: 10),
  //       ...data.asMap().entries.map((entry) {
  //         int index = entry.key;
  //         var item = entry.value;
  //         final matches = item['matches'] ?? [];
  //
  //         // Cari clip_score tertinggi
  //         matches.sort((a, b) =>
  //             ((b['scores']?['clip_score']?['value'] ?? 0.0) as double)
  //                 .compareTo(a['scores']?['clip_score']?['value'] ?? 0.0));
  //
  //         return ExpansionTile(
  //           title: Text('Image ${index + 1} Results'),
  //           children: matches.map<Widget>((match) {
  //             final clipScore = match['scores']?['clip_score']?['value'] ?? 0.0;
  //             return ListTile(
  //               title: Text(match['text']),
  //               subtitle: Text('clip_score: $clipScore'),
  //             );
  //           }).toList(),
  //         );
  //       }),
  //     ],
  //   );
  // }

  Widget _buildApiResponse() {
    if (_apiResponse.isEmpty) {
      return const Text('No validation results available.');
    }

    List<dynamic> data = _apiResponse['data'] ?? [];
    String validationResult = _validateTargets(data);
    print("$_validateTargets");

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
            title: Text('Image ${index + 1} Results'),
            children: matches.map<Widget>((match) {
              final clipScore = match['scores']?['clip_score']?['value'] ?? 0.0;
              // final clipScoreCosine= match['scores']?['clip_score']?['value'] ?? 0.0;
              return ListTile(
                title: Text(match['text']),
                subtitle: Text('clip_score: $clipScore'),
                // trailing: Text('clip_score_cosine: $clipScoreCosine')

              );
            }).toList(),
          );
        }),
        const SizedBox(height: 10),
        Text(
          'Status: $validationResult',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: validationResult == "Target Achieved" ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

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
            _buildApiResponse(),
          ],
        ),
      ),
    );
  }

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
