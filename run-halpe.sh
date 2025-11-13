#!/bin/bash
# Run script for AlphaPose 3D (Hybrik) CPU-only Docker inference

set -e

echo "=========================================="
echo "AlphaPose 3D (Hybrik) Inference (CPU)"
echo "=========================================="
echo ""

# Default directories
INDIR="${INDIR:-$(pwd)/indir}"
OUTDIR="${OUTDIR:-$(pwd)/outdir}"
MODE="${MODE:-image}"  # image or video
VIDEO_FILE="${VIDEO_FILE:-video.mp4}"

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
echo "Starting 3D inference (this may take a while)..."
echo ""

# <<< MINIMAL CHANGE #2: Update docker command for 3D >>>
# Run Docker container based on mode
if [ "$MODE" = "image" ]; then
    docker run --rm \
        --shm-size 8G \
        -v "$INDIR":/workspace/input \
        -v "$OUTDIR":/workspace/output \
        alphapose-halpe-cpu \
        python3 scripts/demo_3d_inference.py \
        --cfg configs/smpl/256x192_adam_lr1e-3-res34_smpl_24_3d_base_2x_mix.yaml \
        --checkpoint pretrained_models/hybrik_hrnet.pth \
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
        python3 scripts/demo_3d_inference.py \
        --cfg configs/smpl/256x192_adam_lr1e-3-res34_smpl_24_3d_base_2x_mix.yaml \
        --checkpoint pretrained_models/hybrik_hrnet.pth \
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
echo "✓ 3D Processing complete!"
echo "=========================================="
echo ""
echo "Results saved to: $OUTDIR"
echo ""
# <<< MINIMAL CHANGE #3: Update output description >>>
echo "Output includes:"
echo "  - Rendered images/video with 3D skeleton/mesh"
echo "  - alphapose-results.json with 3D joint coordinates (pred_xyz_jts_24) and SMPL parameters"
echo ""

# Usage examples
cat << 'EOF'
Usage Examples:

  # Process images (default)
  ./run-3d.sh

  # Process video
  MODE=video VIDEO_FILE=myvideo.mp4 ./run-3d.sh

  # Custom directories
  INDIR=/path/to/images OUTDIR=/path/to/output ./run-3d.sh

See DOCKER-3D.md for more advanced usage options.
EOF