#!/bin/bash
# Run script for AlphaPose Halpe 136 CPU-only Docker inference

set -e

echo "=========================================="
echo "AlphaPose Halpe 136 Inference (CPU)"
echo "=========================================="
echo ""

# Default directories
INDIR="${INDIR:-$(pwd)/indir}"
OUTDIR="${OUTDIR:-$(pwd)/outdir}"
MODE="${MODE:-image}"  # image or video
VIDEO_FILE="${VIDEO_FILE:-video.mp4}"

# Check if Docker image exists
if ! docker image inspect alphapose-halpe-cpu &> /dev/null; then
    echo "❌ ERROR: Docker image 'alphapose-halpe-cpu' not found."
    echo ""
    echo "Please build it first:"
    echo "  ./build-halpe.sh"
    echo ""
    exit 1
fi

# Create directories if they don't exist
mkdir -p "$INDIR" "$OUTDIR"

echo "Configuration:"
echo "  Mode: $MODE"
echo "  Input: $INDIR"
echo "  Output: $OUTDIR"

if [ "$MODE" = "video" ]; then
    echo "  Video: $VIDEO_FILE"
fi

echo ""

# Check for input
if [ "$MODE" = "image" ]; then
    IMAGE_COUNT=$(find "$INDIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | wc -l)
    if [ "$IMAGE_COUNT" -eq 0 ]; then
        echo "⚠️  WARNING: No images found in $INDIR"
        echo ""
        echo "Please add images (.jpg, .jpeg, .png) to the input directory."
        exit 1
    fi
    echo "Found $IMAGE_COUNT image(s) to process"
elif [ "$MODE" = "video" ]; then
    if [ ! -f "$INDIR/$VIDEO_FILE" ]; then
        echo "❌ ERROR: Video file not found: $INDIR/$VIDEO_FILE"
        exit 1
    fi
    echo "Found video: $INDIR/$VIDEO_FILE"
fi

echo ""
echo "Starting inference (this may take a while)..."
echo ""

# Run Docker container based on mode
if [ "$MODE" = "image" ]; then
    docker run --rm \
        --shm-size 8G \
        -v "$INDIR":/workspace/input \
        -v "$OUTDIR":/workspace/output \
        alphapose-halpe-cpu \
        python3 scripts/demo_inference.py \
        --cfg configs/halpe_136/resnet/256x192_res50_lr1e-3_2x-regression.yaml \
        --checkpoint pretrained_models/halpe136_fast50_regression_256x192.pth \
        --gpus -1 \
        --indir /workspace/input \
        --outdir /workspace/output \
        --save_img
elif [ "$MODE" = "video" ]; then
    docker run --rm \
        --shm-size 8G \
        -v "$INDIR":/workspace/input \
        -v "$OUTDIR":/workspace/output \
        alphapose-halpe-cpu \
        python3 scripts/demo_inference.py \
        --cfg configs/halpe_136/resnet/256x192_res50_lr1e-3_2x-regression.yaml \
        --checkpoint pretrained_models/halpe136_fast50_regression_256x192.pth \
        --gpus -1 \
        --video /workspace/input/"$VIDEO_FILE" \
        --outdir /workspace/output \
        --save_video
else
    echo "❌ ERROR: Invalid MODE. Use 'image' or 'video'"
    exit 1
fi

echo ""
echo "=========================================="
echo "✓ Processing complete!"
echo "=========================================="
echo ""
echo "Results saved to: $OUTDIR"
echo ""
echo "Output includes:"
echo "  - Rendered images/video with 136 keypoints visualized"
echo "  - alphapose-results.json with detailed keypoint data"
echo ""
echo "Keypoint breakdown:"
echo "  - Body: 26 keypoints"
echo "  - Face: 68 keypoints"
echo "  - Left Hand: 21 keypoints"
echo "  - Right Hand: 21 keypoints"
echo "  - Total: 136 keypoints"
echo ""

# Usage examples
cat << 'EOF'
Usage Examples:

  # Process images (default)
  ./run-halpe.sh

  # Process video
  MODE=video VIDEO_FILE=myvideo.mp4 ./run-halpe.sh

  # Custom directories
  INDIR=/path/to/images OUTDIR=/path/to/output ./run-halpe.sh

See DOCKER-HALPE.md for more advanced usage options.
EOF
