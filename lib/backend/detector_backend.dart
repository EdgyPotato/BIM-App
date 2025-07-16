import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'model_type.dart';
import 'api_controller.dart';

/// Exception thrown when model operations fail
class ModelException implements Exception {
  const ModelException(this.message);
  final String message;
  
  @override
  String toString() => 'ModelException: $message';
}

class ModelManager {
  ModelManager({
    this.onDownloadProgress,
    this.onStatusUpdate,
  });

  final void Function(double progress)? onDownloadProgress;
  final void Function(String message)? onStatusUpdate;

  static const String _assetsPath = 'assets/models';

  Future<String?> getModelPath(ModelType modelType) async {
    if (!Platform.isAndroid) {
      _updateStatus('Unsupported platform: ${Platform.operatingSystem}');
      return null;
    }

    try {
      return await _resolveAndroidModelPath(modelType);
    } catch (e) {
      _updateStatus('Failed to get model path: $e');
      return null;
    }
  }

  /// Checks if a model is downloaded to local storage
  Future<bool> isModelDownloaded(ModelType modelType) async {
    if (!Platform.isAndroid) return false;

    try {
      final modelFile = await _getLocalModelFile(modelType);
      return await modelFile.exists();
    } catch (e) {
      debugPrint('Error checking if model is downloaded: $e');
      return false;
    }
  }

  /// Checks if a model is available (either bundled or downloaded)
  Future<bool> isModelAvailable(ModelType modelType) async {
    if (!Platform.isAndroid) return false;

    // Check bundled assets first
    if (await _isModelBundled(modelType)) return true;
    
    // Check downloaded models
    return await isModelDownloaded(modelType);
  }

  /// Forces download of a model, removing any existing cached version
  Future<String?> forceDownloadModel(ModelType modelType) async {
    if (!Platform.isAndroid) return null;

    _updateStatus('Force downloading ${modelType.modelName} model...');

    try {
      final modelFile = await _getLocalModelFile(modelType);
      
      // Remove existing file if present
      if (await modelFile.exists()) {
        await modelFile.delete();
        debugPrint('Deleted existing model before re-download');
      }

      return await _downloadModel(modelType, modelFile);
    } catch (e) {
      _updateStatus('Failed to force download model: $e');
      return null;
    }
  }

  /// Clears all downloaded models from local storage
  Future<void> clearCache() async {
    if (!Platform.isAndroid) return;

    _updateStatus('Clearing model cache...');

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      int deletedCount = 0;

      for (final modelType in ModelType.values) {
        final modelFile = File('${documentsDir.path}/${modelType.fileName}');
        
        if (await modelFile.exists()) {
          await modelFile.delete();
          deletedCount++;
          debugPrint('Deleted cached model: ${modelType.fileName}');
        }
      }

      final message = deletedCount > 0 
          ? 'Cache cleared: $deletedCount models deleted'
          : 'Cache was already empty';
      
      debugPrint(message);
      _updateStatus(message);
    } catch (e) {
      _updateStatus('Failed to clear cache: $e');
    }
  }

  /// Resolves the Android model path following priority order:
  /// 1. Bundled assets (highest priority)
  /// 2. Previously downloaded models
  /// 3. Download from remote (if not found)
  Future<String?> _resolveAndroidModelPath(ModelType modelType) async {
    _updateStatus('Checking for ${modelType.modelName} model...');

    // Priority 1: Check bundled assets
    if (await _isModelBundled(modelType)) {
      debugPrint('Using bundled model: ${modelType.fileName}');
      return modelType.fileName;
    }

    // Priority 2: Check local storage
    final modelFile = await _getLocalModelFile(modelType);
    if (await modelFile.exists()) {
      debugPrint('Using downloaded model: ${modelFile.path}');
      return modelFile.path;
    }

    // Priority 3: Download model
    _updateStatus('Model not found locally, downloading...');
    return await _downloadModel(modelType, modelFile);
  }

  /// Checks if a model exists in the app's bundled assets
  Future<bool> _isModelBundled(ModelType modelType) async {
    try {
      await rootBundle.load('$_assetsPath/${modelType.fileName}');
      return true;
    } catch (e) {
      debugPrint('Model not found in assets: ${modelType.fileName}');
      return false;
    }
  }

  /// Gets the File object for a model in local storage
  Future<File> _getLocalModelFile(ModelType modelType) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return File('${documentsDir.path}/${modelType.fileName}');
  }

  /// Downloads a model from the remote repository
  Future<String?> _downloadModel(ModelType modelType, File destinationFile) async {
    _updateStatus('Downloading ${modelType.modelName} model...');

    try {
      final modelPath = await ApiController.downloadModel(
        modelType.modelName,
        destinationFile.path,
        onProgress: onDownloadProgress,
      );

      if (modelPath != null) {
        _updateStatus('Download completed: ${modelType.modelName}');
        debugPrint('Model downloaded successfully: $modelPath');
        return modelPath;
      } else {
        throw const ModelException('Download failed: received null path');
      }
    } catch (e) {
      final error = 'Download failed for ${modelType.modelName}: $e';
      _updateStatus(error);
      debugPrint(error);
      return null;
    }
  }

  /// Updates status and logs messages
  void _updateStatus(String message) {
    debugPrint('ModelManager: $message');
    onStatusUpdate?.call(message);
  }
}