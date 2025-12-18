import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mediatech/models/media_model.dart';

class MediaService {
  final _collection = FirebaseFirestore.instance.collection('media');
  final _storage = FirebaseStorage.instance;

  Future<List<MediaModel>> loadMedia() async {
    final snap = await _collection.orderBy('createdAt', descending: true).get();
    return snap.docs.map((doc) => MediaModel.fromMap(doc.id, doc.data())).toList();
  }

  Future<String?> uploadImage(File imageFile, String mediaId) async {
    try {
      final ref = _storage.ref().child('media_covers/$mediaId.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<bool> addMedia(MediaModel media) async {
    try {
      final docRef = _collection.doc();
      final mediaWithId = media.copyWith(id: docRef.id);
      await docRef.set(mediaWithId.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMedia(MediaModel media) async {
    try {
      await _collection.doc(media.id).update(media.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMedia(String mediaId) async {
    try {
      try {
        await _storage.ref().child('media_covers/$mediaId.jpg').delete();
      } catch (_) {} // ignore if image doesn't exist
      await _collection.doc(mediaId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
