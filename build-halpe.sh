#!/bin/bash
# Build script for AlphaPose Halpe 136 CPU-only Docker image

set -e

echo "=========================================="
echo "AlphaPose Halpe 136 Docker Build Script"
echo "=========================================="
echo ""
echo "Building Docker image..."
echo "This will automatically download required models (~300MB)"
echo "Build time: ~10-15 minutes"
echo ""

# Build the Docker image
docker build -f Dockerfile.halpe -t alphapose-halpe-cpu .

echo ""
echo "=========================================="
echo "✓ Build complete!"
echo "=========================================="
echo ""
echo "Image: alphapose-halpe-cpu"
echo ""
echo "Next steps:"
echo "  1. Create input/output directories: mkdir -p indir outdir"
echo "  2. Place images in: indir/"
echo "  3. Run: ./run-halpe.sh"
echo ""
echo "Or see DOCKER-HALPE.md for detailed usage instructions."
echo ""
