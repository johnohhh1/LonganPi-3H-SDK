#!/usr/bin/env bash
set -e

# Configuration
KERNEL_SRC="./build/linux-6.6"
DEFCONFIG="longanpi_3h_android_defconfig"
OUTDIR="./out"
CROSS_COMPILE="${CROSS_COMPILE:-aarch64-linux-gnu-}"

echo "Building Android kernel for LonganPi 3H..."
echo "Kernel source: $KERNEL_SRC"
echo "Defconfig: $DEFCONFIG"
echo "Output: $OUTDIR"
echo "Cross-compiler: $CROSS_COMPILE"

# Create output directory
mkdir -p "$OUTDIR"

# Check if kernel source exists
if [ ! -d "$KERNEL_SRC" ]; then
    echo "Error: Kernel source not found at $KERNEL_SRC"
    exit 1
fi

# Check if defconfig exists
if [ ! -f "$KERNEL_SRC/arch/arm64/configs/$DEFCONFIG" ]; then
    echo "Error: Defconfig not found at $KERNEL_SRC/arch/arm64/configs/$DEFCONFIG"
    exit 1
fi

# Check if cross-compiler is available
if ! command -v ${CROSS_COMPILE}gcc &> /dev/null; then
    echo "Error: Cross-compiler not found: ${CROSS_COMPILE}gcc"
    echo "Please install: sudo apt install gcc-aarch64-linux-gnu"
    exit 1
fi

cd "$KERNEL_SRC"

echo "Configuring kernel..."
make ARCH=arm64 CROSS_COMPILE="$CROSS_COMPILE" $DEFCONFIG

echo "Building kernel Image..."
make ARCH=arm64 CROSS_COMPILE="$CROSS_COMPILE" -j$(nproc) Image

echo "Building device tree..."
make ARCH=arm64 CROSS_COMPILE="$CROSS_COMPILE" -j$(nproc) dtbs

echo "Building compressed Image..."
make ARCH=arm64 CROSS_COMPILE="$CROSS_COMPILE" -j$(nproc) Image.gz

# Copy outputs
echo "Copying kernel artifacts..."
cp arch/arm64/boot/Image.gz "$OUTDIR/"
cp arch/arm64/boot/Image "$OUTDIR/"
cp arch/arm64/boot/dts/allwinner/sun50i-h618-longanpi-3h.dtb "$OUTDIR/"

# Create Image.gz-dtb for Android
echo "Creating Image.gz-dtb for Android..."
cat arch/arm64/boot/Image.gz arch/arm64/boot/dts/allwinner/sun50i-h618-longanpi-3h.dtb > "$OUTDIR/Image.gz-dtb"

echo "Kernel build complete!"
echo "Output files in $OUTDIR/:"
echo "  - Image.gz (compressed kernel)"
echo "  - Image.gz-dtb (compressed kernel + device tree)"
echo "  - Image (uncompressed kernel)"
echo "  - sun50i-h618-longanpi-3h.dtb (device tree blob)" 