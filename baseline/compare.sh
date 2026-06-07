#!/bin/bash
# Comparison script for MoonBit vs Go QR code implementations

echo "=========================================="
echo "  QR Code Implementation Comparison"
echo "=========================================="
echo ""

echo "🌙 Running MoonBit implementation..."
echo "------------------------------------------"
cd ..
moon run src/cmd/main/main.mbt > baseline/moonbit_output.txt.tmp
cd baseline
cat moonbit_output.txt.tmp
echo ""

echo "🐹 Running Go rscio_qr implementation..."
echo "------------------------------------------"
cd go_rscio_qr && go run main.go > ../go_output.txt.tmp && cd ..
cat go_output.txt.tmp
echo ""

echo "=========================================="
echo "  Comparison Analysis"
echo "=========================================="
echo ""

# Compare outputs
if diff -q moonbit_output.txt.tmp go_output.txt.tmp > /dev/null 2>&1; then
    echo "✅ IDENTICAL: Both implementations produce exactly the same output!"
else
    echo "⚠️  DIFFERENCES DETECTED:"
    echo ""
    echo "Detailed diff:"
    diff -u moonbit_output.txt.tmp go_output.txt.tmp || true
fi

echo ""
echo "Output files saved:"
echo "  - moonbit_output.txt.tmp (MoonBit)"
echo "  - go_output.txt.tmp (Go)"
