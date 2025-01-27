import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Media Picker Demo',
      home: MyHomePage(title: 'Media Picker Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title});

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile>? _mediaFileList;
  File? _selectedFile;
  bool _isVideo = false;
  VideoPlayerController? _videoController;
  String? _pickError;

  Future<void> _pickMedia({
    required ImageSource source,
    bool isMultiImage = false,
  }) async {
    try {
      if (_isVideo) {
        final XFile? pickedVideo = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 10),
        );
        if (pickedVideo != null) {
          _playVideo(pickedVideo);
        }
      } else if (isMultiImage) {
        final List<XFile> pickedImages = await _picker.pickMultiImage();
        setState(() {
          _mediaFileList = pickedImages;
        });
      } else {
        final XFile? pickedImage = await _picker.pickImage(source: source);
        setState(() {
          _mediaFileList = pickedImage != null ? [pickedImage] : null;
        });
      }
    } catch (e) {
      setState(() {
        _pickError = e.toString();
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      setState(() {
        _pickError = e.toString();
      });
    }
  }

  Future<void> _playVideo(XFile videoFile) async {
    if (_videoController != null) {
      await _videoController!.dispose();
    }
    _videoController = VideoPlayerController.file(File(videoFile.path))
      ..setLooping(true)
      ..initialize().then((_) {
        setState(() {
          _videoController!.play();
        });
      });
  }

  Widget _previewMedia() {
    if (_isVideo) {
      return _videoController != null && _videoController!.value.isInitialized
          ? AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            )
          : const Text(
              'No video selected',
              textAlign: TextAlign.center,
            );
    } else if (_mediaFileList != null && _mediaFileList!.isNotEmpty) {
      return GridView.builder(
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: _mediaFileList!.length,
        itemBuilder: (context, index) {
          return Image.file(
            File(_mediaFileList![index].path),
            fit: BoxFit.cover,
          );
        },
      );
    } else if (_selectedFile != null) {
      return Text(
        'Selected file: ${_selectedFile!.path.split('/').last}',
        textAlign: TextAlign.center,
      );
    } else if (_pickError != null) {
      return Text(
        'Error: $_pickError',
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'No media selected',
        textAlign: TextAlign.center,
      );
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: _previewMedia(),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _isVideo = false;
              _pickMedia(source: ImageSource.gallery);
            },
            tooltip: 'Pick Image from Gallery',
            child: const Icon(Icons.photo),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              _isVideo = false;
              _pickMedia(source: ImageSource.gallery, isMultiImage: true);
            },
            tooltip: 'Pick Multiple Images from Gallery',
            child: const Icon(Icons.photo_library),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              _isVideo = true;
              _pickMedia(source: ImageSource.gallery);
            },
            tooltip: 'Pick Video from Gallery',
            child: const Icon(Icons.videocam),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _pickFile,
            tooltip: 'Pick File',
            child: const Icon(Icons.insert_drive_file),
          ),
        ],
      ),
    );
  }
}
