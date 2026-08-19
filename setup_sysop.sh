#!/bin/bash
set -e

echo "=== 1. Creating Production Directory Structure ==="
mkdir -p ~/dxspider-prod/local ~/dxspider-prod/local_data ~/dxspider-prod/connect

# Ensure required files are present in /tmp before moving forward
REQUIRED_FILES=("/tmp/DXVars.pm" "/tmp/Listeners.pm" "/tmp/Dockerfile" "/tmp/docker-compose.yml")

while true; do
  echo ""
  echo "========================================================================"
  echo " Please copy your 4 support files into /tmp:"
  echo "   - /tmp/DXVars.pm"
  echo "   - /tmp/Listeners.pm"
  echo "   - /tmp/Dockerfile"
  echo "   - /tmp/docker-compose.yml"
  echo "========================================================================"
  read -p "Press <Enter> once all 4 files are present in /tmp..."

  ALL_FOUND=true
  for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
      echo " [MISSING] Could not find $file"
      ALL_FOUND=false
    fi
  done

  if [ "$ALL_FOUND" = true ]; then
    echo " All 4 support files detected in /tmp!"
    break
  else
    echo "Please upload the missing file(s) to /tmp and press <Enter> again."
  fi
done

echo "=== 2. Copying Support Files into Staging Directory ==="
cp /tmp/DXVars.pm ~/dxspider-prod/local/DXVars.pm
cp /tmp/Listeners.pm ~/dxspider-prod/local/Listeners.pm
cp /tmp/Dockerfile ~/dxspider-prod/Dockerfile
cp /tmp/docker-compose.yml ~/dxspider-prod/docker-compose.yml

echo "=== 3. Building and Launching DXSpider Container ==="
cd ~/dxspider-prod
docker compose build && docker compose up -d

echo ""
echo "========================================================================"
echo " DXSpider container deployment complete!"
echo " Web console running on port 8080."
echo " Cluster Telnet running on port 7300."
echo "========================================================================"
