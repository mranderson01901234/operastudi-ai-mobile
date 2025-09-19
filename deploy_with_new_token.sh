#!/bin/bash

echo "🚀 DEPLOYMENT SCRIPT WITH NEW REPLICATE TOKEN"
echo "============================================="
echo ""

# Set the new Replicate API token
export REPLICATE_API_TOKEN="YOUR_NEW_REPLICATE_TOKEN_HERE"

echo "✅ Step 1: Pull Latest Code"
echo "-------------------------"
git pull origin main

echo ""
echo "✅ Step 2: Verify New Replicate Token"
echo "------------------------------------"
curl -s -X GET "https://api.replicate.com/v1/account" \
  -H "Authorization: Token $REPLICATE_API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '"Account: \(.username) (\(.type))"'

echo ""
echo "✅ Step 3: Update Environment Files"
echo "----------------------------------"

# Update deploy scripts with new token
sed -i "s/REPLICATE_API_TOKEN=r8_.*/REPLICATE_API_TOKEN=$REPLICATE_API_TOKEN/" deploy-local-build.sh
sed -i "s/REPLICATE_API_TOKEN=r8_.*/REPLICATE_API_TOKEN=$REPLICATE_API_TOKEN/" deploy-mobile.sh
sed -i "s/REPLICATE_API_TOKEN=r8_.*/REPLICATE_API_TOKEN=$REPLICATE_API_TOKEN/" deploy-production.sh

echo "Updated deployment scripts with new token"

echo ""
echo "✅ Step 4: Build and Deploy Options"
echo "----------------------------------"
echo "Choose your deployment method:"
echo ""
echo "🌐 For Netlify Deployment:"
echo "   1. Update Netlify environment variables:"
echo "      REPLICATE_API_TOKEN = YOUR_NEW_REPLICATE_TOKEN_HERE"
echo "   2. Trigger a new deployment"
echo ""
echo "🖥️  For Local Server:"
echo "   export REPLICATE_API_TOKEN=\"YOUR_NEW_REPLICATE_TOKEN_HERE\""
echo "   node server.js"
echo ""
echo "📱 For Mobile Build:"
echo "   ./deploy-mobile.sh"
echo ""
echo "🏭 For Production:"
echo "   ./deploy-production.sh"

echo ""
echo "🧪 Step 5: Test Authentication"
echo "-----------------------------"
echo "After deployment, test with:"
echo "1. Get JWT token from: http://localhost:8080/get_token.html"
echo "2. Test API call:"
echo ""
echo "curl -X POST https://operastudio.io/.netlify/functions/replicate-predict \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \\"
echo "  -d '{\"input\":{\"image\":\"data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD//2Q==\"}}'"

echo ""
echo "🎯 Expected Results:"
echo "✅ Status 200/201: Complete success!"
echo "⚠️  Status 400: Auth works, minor image issue"
echo "❌ Status 401: Authentication problem" 