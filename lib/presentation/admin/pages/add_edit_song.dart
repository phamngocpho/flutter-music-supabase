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
import 'package:spotify/domain/usecases/admin/upload_cover_image_usecase.dart';
import 'package:spotify/domain/usecases/admin/upload_lyrics_file_usecase.dart';
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
  late TextEditingController _genreController;
  late DateTime _releaseDate;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isDetectingDuration = false;

  // Audio file upload
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String? _uploadedUrl;

  // Cover image upload
  Uint8List? _selectedCoverBytes;
  String? _selectedCoverName;
  String? _uploadedCoverUrl;

  // Lyrics file upload
  Uint8List? _selectedLyricsBytes;
  String? _selectedLyricsName;
  String? _uploadedLyricsUrl;

  // Duration (auto-detected)
  Duration? _detectedDuration;

  bool get isEditing => widget.song != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song?.title ?? '');
    _artistController = TextEditingController(text: widget.song?.artist ?? '');
    _genreController = TextEditingController(text: widget.song?.genre ?? '');
    _releaseDate = widget.song?.releaseDate ?? DateTime.now();
    _uploadedUrl = widget.song?.url;
    _uploadedCoverUrl = widget.song?.coverUrl;
    _uploadedLyricsUrl = widget.song?.lyricsUrl;
    if (widget.song != null) {
      _detectedDuration = Duration(seconds: widget.song!.duration.toInt());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedFileBytes = result.files.single.bytes;
          _selectedFileName = result.files.single.name;
          _uploadedUrl = null;
          _detectedDuration = null;
        });

        await _detectDuration();
      }
    } catch (e) {
      _showSnackBar('Failed to pick audio file: ${e.toString()}', isError: true);
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedCoverBytes = result.files.single.bytes;
          _selectedCoverName = result.files.single.name;
          _uploadedCoverUrl = null;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: ${e.toString()}', isError: true);
    }
  }

  Future<void> _pickLyricsFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['lrc', 'txt'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedLyricsBytes = result.files.single.bytes;
          _selectedLyricsName = result.files.single.name;
          _uploadedLyricsUrl = null;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick lyrics file: ${e.toString()}', isError: true);
    }
  }

  Future<void> _detectDuration() async {
    if (_selectedFileBytes == null) return;

    setState(() => _isDetectingDuration = true);

    try {
      final player = AudioPlayer();
      final audioSource = _AudioBytesSource(_selectedFileBytes!);
      final duration = await player.setAudioSource(audioSource);

      if (duration != null) {
        setState(() => _detectedDuration = duration);
      }

      await player.dispose();
    } catch (e) {
      debugPrint('Duration detection failed: $e');
    } finally {
      setState(() => _isDetectingDuration = false);
    }
  }

  Future<String?> _uploadAudioFile() async {
    if (_selectedFileBytes == null) return _uploadedUrl;

    var result = await sl<UploadSongFileUseCase>().call(
      fileBytes: _selectedFileBytes!,
      fileName: _selectedFileName!,
    );

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

  Future<String?> _uploadCoverImage() async {
    if (_selectedCoverBytes == null) return _uploadedCoverUrl;

    var result = await sl<UploadCoverImageUseCase>().call(
      fileBytes: _selectedCoverBytes!,
      fileName: _selectedCoverName!,
    );

    return result.fold(
      (error) {
        _showSnackBar(error, isError: true);
        return null;
      },
      (url) {
        setState(() => _uploadedCoverUrl = url);
        return url;
      },
    );
  }

  Future<String?> _uploadLyricsFile() async {
    if (_selectedLyricsBytes == null) return _uploadedLyricsUrl;

    var result = await sl<UploadLyricsFileUseCase>().call(
      fileBytes: _selectedLyricsBytes!,
      fileName: _selectedLyricsName!,
    );

    return result.fold(
      (error) {
        _showSnackBar(error, isError: true);
        return null;
      },
      (url) {
        setState(() => _uploadedLyricsUrl = url);
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
            colorScheme: ColorScheme.light(primary: AppColors.primary),
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

    if (!isEditing && _selectedFileBytes == null && _uploadedUrl == null) {
      _showSnackBar('Please select an audio file', isError: true);
      return;
    }

    if (_detectedDuration == null) {
      _showSnackBar('Could not detect duration. Please try another file.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    setState(() => _isUploading = true);

    try {
      // Upload files if selected
      String? songUrl = _uploadedUrl;
      String? coverUrl = _uploadedCoverUrl;
      String? lyricsUrl = _uploadedLyricsUrl;

      if (_selectedFileBytes != null) {
        songUrl = await _uploadAudioFile();
        if (songUrl == null) {
          setState(() {
            _isLoading = false;
            _isUploading = false;
          });
          return;
        }
      }

      if (_selectedCoverBytes != null) {
        coverUrl = await _uploadCoverImage();
      }

      if (_selectedLyricsBytes != null) {
        lyricsUrl = await _uploadLyricsFile();
      }

      setState(() => _isUploading = false);

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
            coverUrl: coverUrl,
            genre: _genreController.text.isEmpty ? null : _genreController.text,
            lyricsUrl: lyricsUrl,
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
            coverUrl: coverUrl,
            genre: _genreController.text.isEmpty ? null : _genreController.text,
            lyricsUrl: lyricsUrl,
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
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });
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
              _buildCoverImagePicker(),
              const SizedBox(height: 16),
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
              _buildTextField(
                controller: _genreController,
                label: 'Genre (Optional)',
                icon: Icons.category,
              ),
              const SizedBox(height: 16),
              _buildAudioFilePicker(),
              const SizedBox(height: 16),
              _buildLyricsFilePicker(),
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
                          Text(_isUploading ? 'Uploading files...' : 'Saving...'),
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

  Widget _buildCoverImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cover Image',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickCoverImage,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade900,
            ),
            child: _selectedCoverBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _selectedCoverBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : _uploadedCoverUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _uploadedCoverUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildCoverPlaceholder();
                          },
                        ),
                      )
                    : _buildCoverPlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image, size: 60, color: Colors.grey.shade600),
        const SizedBox(height: 8),
        Text(
          'Tap to select cover image',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildAudioFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Audio File',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickAudioFile,
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

  Widget _buildLyricsFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lyrics File (Optional - LRC format)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickLyricsFile,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedLyricsBytes != null || _uploadedLyricsUrl != null
                      ? Icons.lyrics
                      : Icons.upload_file,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedLyricsName ??
                            (_uploadedLyricsUrl != null
                                ? 'Lyrics file uploaded'
                                : 'Tap to select lyrics file (.lrc)'),
                        style: TextStyle(
                          color: _selectedLyricsBytes != null || _uploadedLyricsUrl != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_selectedLyricsBytes != null)
                        Text(
                          'Ready to upload',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      if (_uploadedLyricsUrl != null && _selectedLyricsBytes == null)
                        const Text(
                          'Lyrics file already uploaded',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_selectedLyricsBytes != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedLyricsBytes = null;
                        _selectedLyricsName = null;
                      });
                    },
                  ),
              ],
            ),
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
