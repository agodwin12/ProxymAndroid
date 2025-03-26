import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../login/login.dart';


class CompleteInformation extends StatefulWidget {
  final String phone;
  final String nom;
  final String prenom;
  final String email;
  final String password;

  const CompleteInformation({
    Key? key,
    required this.phone,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  _CompleteInformationState createState() => _CompleteInformationState();
}

class _CompleteInformationState extends State<CompleteInformation> {
  File? _profileImage;
  File? _frontIdCard;
  File? _backIdCard;
  bool _isLoading = false;
  late CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String _currentImageType = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController?.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _showImageSourceDialog(String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _showCameraPreview(type);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(type, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCameraPreview(String type) {
    setState(() {
      _currentImageType = type;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              type == 'profile'
                  ? 'Take Profile Picture'
                  : type == 'front_id'
                  ? 'Front ID Card'
                  : 'Back ID Card',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isCameraInitialized)
                        CameraPreview(_cameraController!),
                      if (type == 'front_id' || type == 'back_id')
                        Container(
                          width: MediaQuery.of(context).size.width * 0.85,
                          height: MediaQuery.of(context).size.width * 0.55,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      if (type == 'front_id' || type == 'back_id')
                        Positioned(
                          top: 20,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Align ID card within the frame',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.black,
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                        onPressed: () async {
                          final cameras = await availableCameras();
                          final newCameraIndex = _cameraController!.description == cameras[0] ? 1 : 0;

                          if (newCameraIndex < cameras.length) {
                            await _cameraController?.dispose();

                            _cameraController = CameraController(
                              cameras[newCameraIndex],
                              ResolutionPreset.high,
                              enableAudio: false,
                            );

                            await _cameraController?.initialize();
                            setState(() {});
                          }
                        },
                      ),
                      GestureDetector(
                        onTap: () => _takePicture(type),
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              height: 65,
                              width: 65,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.photo_library, color: Colors.white, size: 30),
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage(type, ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _takePicture(String type) async {
    if (!_isCameraInitialized) return;

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        switch (type) {
          case 'profile':
            _profileImage = File(image.path);
            break;
          case 'front_id':
            _frontIdCard = File(image.path);
            break;
          case 'back_id':
            _backIdCard = File(image.path);
            break;
        }
      });
      Navigator.pop(context);
    } catch (e) {
      print('Error taking picture: $e');
      _showErrorDialog('Failed to capture image');
    }
  }

  Future<void> _pickImage(String type, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          switch (type) {
            case 'profile':
              _profileImage = File(pickedFile.path);
              break;
            case 'front_id':
              _frontIdCard = File(pickedFile.path);
              break;
            case 'back_id':
              _backIdCard = File(pickedFile.path);
              break;
          }
        });
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      _showErrorDialog('Failed to pick image');
    }
  }

  Future<void> _completeProfile() async {
    if (_profileImage == null || _frontIdCard == null || _backIdCard == null) {
      _showErrorDialog('Please upload all required documents');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:5000/auth/complete-profile'),
      );

      request.fields['phone'] = widget.phone;

      request.files.add(await http.MultipartFile.fromPath('photo', _profileImage!.path));
      request.files.add(await http.MultipartFile.fromPath('photo_cni_recto', _frontIdCard!.path));
      request.files.add(await http.MultipartFile.fromPath('photo_cni_verso', _backIdCard!.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var decodedResponse = json.decode(responseData);
      print("🔍 API Response: $decodedResponse");

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(decodedResponse['message'] ?? 'Profile completion failed');
      }
    } catch (error) {
      print('❌ Error in profile completion: $error');
      _showErrorDialog('Server error. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text('Profile completed successfully!'),
        actions: <Widget>[
          TextButton(
            child: const Text('Continue'),
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => Login()),
                    (Route<dynamic> route) => false,
              );
            },
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),

                Text(
                  'Complete your profile',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 40),

                _buildUploadSection(
                  title: 'Upload your picture',
                  subtitle: 'Please upload a clear photo of yourself',
                  onTap: () => _showImageSourceDialog('profile'),
                  selectedFile: _profileImage,
                  icon: Icons.person,
                ),

                const SizedBox(height: 24),

                _buildUploadSection(
                  title: 'Upload front ID Card',
                  subtitle: 'Upload the front side of your ID card',
                  onTap: () => _showImageSourceDialog('front_id'),
                  selectedFile: _frontIdCard,
                  icon: Icons.credit_card,
                ),

                const SizedBox(height: 24),

                _buildUploadSection(
                  title: 'Upload back ID Card',
                  subtitle: 'Upload the back side of your ID card',
                  onTap: () => _showImageSourceDialog('back_id'),
                  selectedFile: _backIdCard,
                  icon: Icons.credit_card,
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDCDC34),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.black)
                        : Text(
                      'Complete',
                      style: TextStyle(
                        color: Color(0xFF463E39),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  '© Copyright PROXYMGROUP',
                  style: TextStyle(
                    color: Color(0xD31A293D),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required IconData icon,
    File? selectedFile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: Color(0xFFDCDC34)),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xD31A293D),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  if (selectedFile != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        selectedFile,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                  Text(selectedFile == null ? 'Select File' : 'Change File'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}