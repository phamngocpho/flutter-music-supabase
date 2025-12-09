import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spotify/core/theme/app_colors.dart';
import 'package:spotify/data/models/song_request.dart';
import 'package:spotify/domain/entities/song_entity.dart';
import 'package:spotify/domain/usecases/admin/add_song_usecase.dart';
import 'package:spotify/domain/usecases/admin/update_song_usecase.dart';
import 'package:spotify/domain/usecases/admin/upload_song_file_usecase.dart';
import 'package:spotify/service_locator.dart';
import 'package:spotify/shared/widgets/basic_app_bar.dart';
import 'package:spotify/shared/widgets/basic_app_button.dart';

class AddEditSongPage extends StatefulWidget {
  final SongEntity? song;

  const AddEditSongPage({super.key, this.song});

  @override
  State<AddEditSongPage> createState() => _AddEditSongPageState();
}

class _AddEditSongPageState extends State<AddEditSongPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late DateTime _releaseDate;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isDetectingDuration = false;

  // File upload
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String? _uploadedUrl;

  // Duration (auto-detected)
  Duration? _detectedDuration;

  bool get isEditing => widget.song != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song?.title ?? '');
    _artistController = TextEditingController(text: widget.song?.artist ?? '');
    _releaseDate = widget.song?.releaseDate ?? DateTime.now();
    _uploadedUrl = widget.song?.url;
    if (widget.song != null) {
      _detectedDuration = Duration(seconds: widget.song!.duration.toInt());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: true, // Important: get bytes for web support
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedFileBytes = result.files.single.bytes;
          _selectedFileName = result.files.single.name;
          _uploadedUrl = null;
          _detectedDuration = null;
        });

        // Auto-detect duration
        await _detectDuration();
      }
    } catch (e) {
      _showSnackBar('Failed to pick file: ${e.toString()}', isError: true);
    }
  }

  Future<void> _detectDuration() async {
    if (_selectedFileBytes == null) return;

    setState(() => _isDetectingDuration = true);

    try {
      final player = AudioPlayer();

      // Create a data source from bytes
      final audioSource = _AudioBytesSource(_selectedFileBytes!);
      final duration = await player.setAudioSource(audioSource);

      if (duration != null) {
        setState(() {
          _detectedDuration = duration;
        });
      }

      await player.dispose();
    } catch (e) {
      // If detection fails, user can still enter manually
      debugPrint('Duration detection failed: $e');
    } finally {
      setState(() => _isDetectingDuration = false);
    }
  }

  Future<String?> _uploadFile() async {
    if (_selectedFileBytes == null) return _uploadedUrl;

    setState(() => _isUploading = true);

    var result = await sl<UploadSongFileUseCase>().call(
      fileBytes: _selectedFileBytes!,
      fileName: _selectedFileName!,
    );

    setState(() => _isUploading = false);

    return result.fold(
      (error) {
        _showSnackBar(error, isError: true);
        return null;
      },
      (url) {
        setState(() => _uploadedUrl = url);
        return url;
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _releaseDate) {
      setState(() => _releaseDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate file for new songs
    if (!isEditing && _selectedFileBytes == null && _uploadedUrl == null) {
      _showSnackBar('Please select an audio file', isError: true);
      return;
    }

    // Validate duration
    if (_detectedDuration == null) {
      _showSnackBar('Could not detect duration. Please try another file.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload file if selected
      String? songUrl = _uploadedUrl;
      if (_selectedFileBytes != null) {
        songUrl = await _uploadFile();
        if (songUrl == null) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final duration = _detectedDuration!.inSeconds;

      if (isEditing) {
        var result = await sl<UpdateSongUseCase>().call(
          params: UpdateSongRequest(
            id: widget.song!.songId,
            title: _titleController.text,
            artist: _artistController.text,
            duration: duration,
            releaseDate: _releaseDate,
            url: songUrl ?? widget.song!.url,
          ),
        );

        result.fold(
          (error) => _showSnackBar(error, isError: true),
          (success) {
            _showSnackBar('Song updated successfully');
            Navigator.pop(context, true);
          },
        );
      } else {
        var result = await sl<AddSongUseCase>().call(
          params: CreateSongRequest(
            title: _titleController.text,
            artist: _artistController.text,
            duration: duration,
            releaseDate: _releaseDate,
            url: songUrl!,
          ),
        );

        result.fold(
          (error) => _showSnackBar(error, isError: true),
          (success) {
            _showSnackBar('Song added successfully');
            Navigator.pop(context, true);
          },
        );
      }
    } catch (e) {
      _showSnackBar('Invalid input: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : AppColors.primary,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppbar(
        title: Text(
          isEditing ? 'Edit Song' : 'Add Song',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _titleController,
                label: 'Title',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _artistController,
                label: 'Artist',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an artist';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildFilePicker(),
              const SizedBox(height: 16),
              _buildDurationDisplay(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 32),
              _isLoading || _isUploading
                  ? Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 8),
                          Text(_isUploading ? 'Uploading file...' : 'Saving...'),
                        ],
                      ),
                    )
                  : BasicAppButton(
                      onPressed: _save,
                      title: isEditing ? 'Update Song' : 'Add Song',
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Audio File',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickFile,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedFileBytes != null || _uploadedUrl != null
                      ? Icons.audio_file
                      : Icons.upload_file,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFileName ??
                            (_uploadedUrl != null
                                ? 'Current file uploaded'
                                : 'Tap to select audio file'),
                        style: TextStyle(
                          color: _selectedFileBytes != null || _uploadedUrl != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_selectedFileBytes != null)
                        Text(
                          'Ready to upload',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      if (_uploadedUrl != null && _selectedFileBytes == null)
                        const Text(
                          'File already uploaded',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_selectedFileBytes != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedFileBytes = null;
                        _selectedFileName = null;
                        _detectedDuration = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
        if (!isEditing && _selectedFileBytes == null && _uploadedUrl == null)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 12),
            child: Text(
              'Required for new songs',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildDurationDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: AppColors.primary),
          const SizedBox(width: 12),
          if (_isDetectingDuration)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8),
                Text('Detecting duration...'),
              ],
            )
          else if (_detectedDuration != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duration: ${_formatDuration(_detectedDuration!)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${_detectedDuration!.inSeconds} seconds (auto-detected)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            )
          else
            const Text(
              'Duration: Select an audio file',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Release Date',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_releaseDate.day}/${_releaseDate.month}/${_releaseDate.year}',
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

/// Custom audio source for bytes
class _AudioBytesSource extends StreamAudioSource {
  final Uint8List _bytes;

  _AudioBytesSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
