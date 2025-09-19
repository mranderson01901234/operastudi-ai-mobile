#!/bin/bash

echo "🔍 COMPLETE AUTHENTICATION TEST"
echo "==============================="
echo ""

NEW_REPLICATE_TOKEN="YOUR_NEW_REPLICATE_TOKEN_HERE"

echo "✅ Step 1: Verify Replicate API Token"
echo "------------------------------------"
curl -s -X GET "https://api.replicate.com/v1/account" \
  -H "Authorization: Token $NEW_REPLICATE_TOKEN" \
  -H "Content-Type: application/json" | jq -r '"\(.type): \(.username)"'

echo ""
echo "✅ Step 2: Test with Production Netlify Endpoint"
echo "-----------------------------------------------"
echo "The production Netlify functions should use the updated token."
echo ""
echo "🧪 Copy and run this command with your JWT token:"
echo ""
echo "curl -X POST https://operastudio.io/.netlify/functions/replicate-predict \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -H 'Authorization: Bearer YOUR_JWT_TOKEN_FROM_WEBPAGE' \\"
echo "  -d '{\"input\":{\"image\":\"data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD//2Q==\"}}'"
echo ""
echo "Expected results:"
echo "✅ Status 200/201: Full success - both tokens work!"
echo "⚠️  Status 400: Supabase auth works, but image data issue"
echo "❌ Status 401: Authentication problem"
echo ""
echo "🔧 Step 3: Update Local Server (if needed)"
echo "-----------------------------------------"
echo "If testing locally, update the environment:"
echo "export REPLICATE_API_TOKEN=\"YOUR_NEW_REPLICATE_TOKEN_HERE\""
echo ""
echo "Then restart your local server:"
echo "node server.js" 