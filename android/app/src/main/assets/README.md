# YOLOv8 Model Placeholder

Place your `yolov8n.tflite` model file in this folder.

Download from: https://github.com/ultralytics/yolo-flutter-app/releases/tag/v0.0.0

Or export using Python:
```python
from ultralytics import YOLO
model = YOLO('yolov8n.pt')
model.export(format='tflite')
```
