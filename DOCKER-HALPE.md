# AlphaPose with Halpe 136 Full-Body Pose Estimation (CPU-Only)

A CPU-only Docker build of modern AlphaPose with Halpe 136 keypoint support, providing detailed full-body pose estimation including:
- **42 hand keypoints** (21 per hand) - detailed finger tracking
- **68 face keypoints** - facial landmark detection
- **26 body keypoints** - full body pose
- **Total: 136 keypoints**

## Build

The Docker build process will automatically download the required models from Google Drive during the build. No manual downloads needed!

```bash
docker build -f Dockerfile.halpe -t alphapose-halpe-cpu .
```

**Note:** The build takes 10-15 minutes and downloads ~300MB of model files.

### Alternative: Manual Model Downloads (Optional)

If the automatic download fails (Google Drive rate limits), you can download manually:

#### Halpe 136 Pose Model
- **Model:** `halpe136_fast50_regression_256x192.pth`
- **Download:** [Google Drive Link](https://drive.google.com/file/d/1_10JYI3O-VbrAiONfL36UxLf9UXMoUYA/view?usp=sharing)
- **Size:** ~100-200 MB
- **Location:** Save to `models/pretrained/halpe136_fast50_regression_256x192.pth`

```bash
# Create directory if it doesn't exist
mkdir -p models/pretrained

# Option 1: Download manually from Google Drive link above

# Option 2: Use gdown (if installed)
pip install gdown
gdown 1_10JYI3O-VbrAiONfL36UxLf9UXMoUYA -O models/pretrained/halpe136_fast50_regression_256x192.pth
```

#### YOLO Detector Weights
- **File:** `yolov3-spp.weights`
- **Download:** [Google Drive](https://drive.google.com/open?id=1D47msNOOiJKvPOXlnpyzdKA3k6E97NTC)
- Or use: `gdown 1D47msNOOiJKvPOXlnpyzdKA3k6E97NTC -O models/yolo/yolov3-spp.weights`

Then rebuild the Docker image.

## Usage

### For Images

Process images from a directory:

```bash
# Create input/output directories
mkdir -p indir outdir

# Place your images in indir/

# Run AlphaPose with Halpe 136
docker run \
    --shm-size 8G \
    -v $(pwd)/indir:/workspace/input \
    -v $(pwd)/outdir:/workspace/output \
    alphapose-halpe-cpu \
    python3 scripts/demo_inference.py \
    --cfg configs/halpe_136/resnet/256x192_res50_lr1e-3_2x-regression.yaml \
    --checkpoint pretrained_models/halpe136_fast50_regression_256x192.pth \
    --gpus -1 \
    --indir /workspace/input \
    --outdir /workspace/output \
    --save_img
```

### For Video

Process a video file:

```bash
docker run \
    --shm-size 8G \
    -v $(pwd)/indir:/workspace/input \
    -v $(pwd)/outdir:/workspace/output \
    alphapose-halpe-cpu \
    python3 scripts/demo_inference.py \
    --cfg configs/halpe_136/resnet/256x192_res50_lr1e-3_2x-regression.yaml \
    --checkpoint pretrained_models/halpe136_fast50_regression_256x192.pth \
    --gpus -1 \
    --video /workspace/input/video.mp4 \
    --outdir /workspace/output \
    --save_video
```

## Command Options

Key parameters you can adjust:

- `--gpus -1` - **Required** for CPU-only inference
- `--indir <path>` - Input directory with images
- `--video <path>` - Input video file
- `--outdir <path>` - Output directory for results
- `--save_img` - Save rendered images with pose overlays
- `--save_video` - Save rendered video with pose overlays
- `--format open` - Output format (default: open, alternatives: cmu, coco)
- `--vis_fast` - Use faster visualization (less detailed rendering)
- `--posebatch <N>` - Batch size for pose estimation (default: 64, reduce if OOM)
- `--detbatch <N>` - Batch size for detection (default: 5)

## Output Format

### Visualization
Images/videos will be saved with pose overlays showing:
- Body skeleton (17 keypoints)
- Face landmarks (68 keypoints)
- Hand joints for both hands (42 keypoints total)

### JSON Output
Results are saved as JSON with keypoint coordinates:

```json
{
  "image_id": "example.jpg",
  "keypoints": [
    [x1, y1, confidence1],
    [x2, y2, confidence2],
    ...
    // 136 keypoints total
  ],
  "score": 0.95
}
```

### Halpe 136 Keypoint Layout

**Body (0-16):** Nose, LEye, REye, LEar, REar, LShoulder, RShoulder, LElbow, RElbow, LWrist, RWrist, LHip, RHip, LKnee, RKnee, LAnkle, RAnkle

**Head/Neck (17-19):** Head, Neck, Hip

**Feet (20-25):** LBigToe, RBigToe, LSmallToe, RSmallToe, LHeel, RHeel

**Face (26-93):** 68 facial landmarks

**Left Hand (94-114):** 21 left hand joints
- Thumb: 94-98
- Index: 99-102
- Middle: 103-106
- Ring: 107-110
- Pinky: 111-114

**Right Hand (115-135):** 21 right hand joints
- Thumb: 115-119
- Index: 120-123
- Middle: 124-127
- Ring: 128-131
- Pinky: 132-135

## Performance

**Expected CPU Performance:**
- **Speed:** 1-2 FPS (frames per second) on modern CPUs
- **Processing time:** 0.5-1 second per image
- **Video:** 30-60 seconds for a 1-minute video

**Tips for better performance:**
- Reduce image resolution before processing
- Use `--posebatch` to process multiple images in parallel
- Consider batch processing instead of real-time inference
- Close other applications to free up CPU resources

## Troubleshooting

### Out of Memory (OOM)
```bash
# Reduce batch sizes
--posebatch 16 --detbatch 2
```

### Slow Processing
```bash
# Use faster visualization
--vis_fast

# Skip visualization and only get JSON output
# (remove --save_img or --save_video flags)
```

### Model Not Found Error
Ensure you've downloaded the models and they're in the correct locations:
- `models/pretrained/halpe136_fast50_regression_256x192.pth`
- `models/yolo/yolov3-spp.weights`

## Comparison: pytorch-cpu vs Halpe

| Feature | pytorch-cpu (Dockerfile) | Halpe (Dockerfile.halpe) |
|---------|-------------------------|--------------------------|
| Keypoints | 18 (COCO format) | 136 (Halpe full-body) |
| Hands | Wrist only | 21 joints per hand |
| Face | None | 68 facial landmarks |
| Speed | ~3-5 FPS | ~1-2 FPS |
| Accuracy | 71 mAP | 44.1 AP (different metric) |
| Use Case | Fast body pose | Detailed full-body + hands |

## Advanced Usage

### Custom Configuration

You can mount your own config file:

```bash
docker run \
    -v $(pwd)/my_config.yaml:/workspace/AlphaPose/configs/custom.yaml \
    -v $(pwd)/indir:/workspace/input \
    -v $(pwd)/outdir:/workspace/output \
    alphapose-halpe-cpu \
    python3 scripts/demo_inference.py \
    --cfg /workspace/AlphaPose/configs/custom.yaml \
    --checkpoint pretrained_models/halpe136_fast50_regression_256x192.pth \
    --gpus -1 \
    --indir /workspace/input \
    --outdir /workspace/output
```

### Extract JSON Only (No Visualization)

For faster processing without rendering:

```bash
docker run \
    --shm-size 8G \
    -v $(pwd)/indir:/workspace/input \
    -v $(pwd)/outdir:/workspace/output \
    alphapose-halpe-cpu \
    python3 scripts/demo_inference.py \
    --cfg configs/halpe_136/resnet/256x192_res50_lr1e-3_2x-regression.yaml \
    --checkpoint pretrained_models/halpe136_fast50_regression_256x192.pth \
    --gpus -1 \
    --indir /workspace/input \
    --outdir /workspace/output \
    --format open
    # Note: removed --save_img flag
```

Results will be in `output/alphapose-results.json`

## Additional Resources

- [AlphaPose GitHub](https://github.com/MVIG-SJTU/AlphaPose)
- [Halpe Dataset](https://github.com/Fang-Haoshu/Halpe-FullBody)
- [Model Zoo](https://github.com/MVIG-SJTU/AlphaPose/blob/master/docs/MODEL_ZOO.md)

## License

AlphaPose is released under the GPL-3.0 License.
