#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ Loaded environment variables from .env file"
else
    echo "❌ .env file not found"
    exit 1
fi

# Run Flutter with environment variables
echo "🚀 Starting Flutter app with environment variables..."
flutter run \
    --dart-define=REPLICATE_API_TOKEN="$REPLICATE_API_TOKEN" \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=REPLICATE_MODEL_ID="$REPLICATE_MODEL_ID" \
    --dart-define=REPLICATE_MODEL_VERSION="$REPLICATE_MODEL_VERSION" \
    --dart-define=DEBUG_MODE="$DEBUG_MODE" \
    --device-id emulator-5554
