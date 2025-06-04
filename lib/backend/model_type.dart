import 'package:ultralytics_yolo/yolo_task.dart';

enum ModelType {
  detect('best-int8', YOLOTask.detect);

  final String modelName;
  final YOLOTask task;
  const ModelType(this.modelName, this.task);
}
