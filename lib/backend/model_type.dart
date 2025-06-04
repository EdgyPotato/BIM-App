import 'package:ultralytics_yolo/yolo_task.dart';

enum ModelType {
  detect('best-int8', YOLOTask.detect);

  const ModelType(this.modelName, this.task);
  
  final String modelName;
  final YOLOTask task;
  
  String get fileName => '$modelName.tflite';
}