import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/media_service.dart';
import '../models/media_model.dart';
import 'package:image_picker/image_picker.dart';

final mediaServiceProvider = Provider<MediaService>((ref) => MediaService());

final mediaControllerProvider = StateNotifierProvider<MediaController, MediaState>((ref) {
  return MediaController(ref);
});

class MediaState {
  final bool loading;
  final String? error;
  final List<MediaModel> media;
  final String? success;
  final bool uploadingImage;

  MediaState({
    this.loading = false,
    this.error,
    this.media = const [],
    this.success,
    this.uploadingImage = false,
  });

  MediaState copyWith({
    bool? loading,
    String? error,
    List<MediaModel>? media,
    String? success,
    bool? uploadingImage,
  }) {
    return MediaState(
      loading: loading ?? this.loading,
      error: error,
      media: media ?? this.media,
      success: success,
      uploadingImage: uploadingImage ?? this.uploadingImage,
    );
  }
}

class MediaController extends StateNotifier<MediaState> {
  final Ref _ref;
  final _picker = ImagePicker();

  MediaController(this._ref) : super(MediaState()) {
    loadMedia();
  }

  MediaService get _service => _ref.read(mediaServiceProvider);

  void clearMessages() {
    state = state.copyWith(error: null, success: null);
  }

  Future<void> loadMedia() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final media = await _service.loadMedia();
      state = state.copyWith(media: media, loading: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load media: ${e.toString()}', loading: false);
    }
  }

  Future<bool> addMedia(MediaModel media) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final success = await _service.addMedia(media);
      if (success) {
        await loadMedia();
        state = state.copyWith(success: 'Media added successfully');
        return true;
      } else {
        state = state.copyWith(error: 'Failed to add media', loading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to add media: ${e.toString()}', loading: false);
      return false;
    }
  }

  Future<bool> updateMedia(MediaModel media) async {
    state = state.copyWith(error: null);
    try {
      final success = await _service.updateMedia(media);
      if (success) {
        await loadMedia();
        state = state.copyWith(success: 'Media updated successfully');
        return true;
      } else {
        state = state.copyWith(error: 'Failed to update media');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update media: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteMedia(String mediaId) async {
    state = state.copyWith(error: null);
    try {
      final success = await _service.deleteMedia(mediaId);
      if (success) {
        await loadMedia();
        state = state.copyWith(success: 'Media deleted successfully');
        return true;
      } else {
        state = state.copyWith(error: 'Failed to delete media');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete media: ${e.toString()}');
      return false;
    }
  }

  Future<File?> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
}
