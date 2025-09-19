const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const multer = require('multer');
const fetch = require('node-fetch');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3002;

// Initialize Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// Middleware
app.use(cors({
  origin: '*',
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Configure multer for file uploads
const upload = multer({
  limits: {
    fileSize: 50 * 1024 * 1024 // 50MB limit
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Replicate Predict endpoint (matches Netlify function)
app.post('/.netlify/functions/replicate-predict', async (req, res) => {
  try {
    console.log('🚀 Replicate Predict: Starting request');
    console.log('Request method:', req.method);
    console.log('Request headers:', JSON.stringify(req.headers, null, 2));

    // Parse request body
    const requestBody = req.body || {};
    console.log('Request body keys:', Object.keys(requestBody));

    // Validate authentication
    const authHeader = req.headers.authorization || req.headers.Authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      console.log('❌ Replicate Predict: No valid authorization header');
      return res.status(401).json({
        error: 'Authentication required',
        message: 'Please provide a valid Bearer token'
      });
    }

    const token = authHeader.replace('Bearer ', '');
    console.log('🔐 Replicate Predict: Token received (first 20 chars):', token.substring(0, 20) + '...');

    // Verify Supabase session
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      console.log('❌ Replicate Predict: Authentication failed:', authError?.message);
      return res.status(401).json({
        error: 'Invalid token',
        message: 'Authentication failed'
      });
    }

    console.log('✅ Replicate Predict: User authenticated:', user.email);

    // Validate request body
    if (!requestBody.input || !requestBody.input.image) {
      console.log('❌ Replicate Predict: Missing image in request');
      return res.status(400).json({
        error: 'Missing image',
        message: 'Request must include input.image'
      });
    }

    // Extract image data
    const imageData = requestBody.input.image;
    const scale = requestBody.input.scale || 2;
    const sharpen = requestBody.input.sharpen || 45;
    const denoise = requestBody.input.denoise || 30;
    const face_recovery = requestBody.input.face_recovery || false;

    console.log('📸 Replicate Predict: Processing image', {
      hasImage: !!imageData,
      scale: scale,
      sharpen: sharpen,
      denoise: denoise,
      face_recovery: face_recovery,
      imageSize: imageData.length
    });

    // Call Replicate API
    const replicateResponse = await fetch('https://api.replicate.com/v1/predictions', {
      method: 'POST',
      headers: {
        'Authorization': `Token ${process.env.REPLICATE_API_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        version: process.env.REPLICATE_MODEL_VERSION || 'df9a3c1d',
        input: {
          image: imageData,
          scale: parseInt(scale),
          sharpen: parseInt(sharpen),
          denoise: parseInt(denoise),
          face_recovery: face_recovery
        }
      })
    });

    if (!replicateResponse.ok) {
      const errorText = await replicateResponse.text();
      console.log('❌ Replicate Predict: Replicate API error:', errorText);
      return res.status(replicateResponse.status).json({
        error: 'Replicate API error',
        message: errorText
      });
    }

    const replicateData = await replicateResponse.json();
    console.log('✅ Replicate Predict: Prediction created', {
      id: replicateData.id,
      status: replicateData.status
    });

    // Return the response in the format expected by the mobile app
    res.status(201).json({
      id: replicateData.id,
      model: replicateData.model,
      version: replicateData.version,
      deployment: replicateData.deployment,
      input: replicateData.input,
      logs: replicateData.logs,
      output: replicateData.output,
      data_removed: replicateData.data_removed,
      error: replicateData.error,
      status: replicateData.status,
      created_at: replicateData.created_at,
      urls: replicateData.urls
    });

  } catch (error) {
    console.error('❌ Replicate Predict: Unexpected error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Replicate Status endpoint
app.get('/.netlify/functions/replicate-status/:id', async (req, res) => {
  try {
    const predictionId = req.params.id;
    console.log('📊 Replicate Status: Checking prediction:', predictionId);

    // Validate authentication
    const authHeader = req.headers.authorization || req.headers.Authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Authentication required',
        message: 'Please provide a valid Bearer token'
      });
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return res.status(401).json({
        error: 'Invalid token',
        message: 'Authentication failed'
      });
    }

    // Call Replicate API to get prediction status
    const replicateResponse = await fetch(`https://api.replicate.com/v1/predictions/${predictionId}`, {
      headers: {
        'Authorization': `Token ${process.env.REPLICATE_API_TOKEN}`,
        'Content-Type': 'application/json',
      }
    });

    if (!replicateResponse.ok) {
      const errorText = await replicateResponse.text();
      console.log('❌ Replicate Status: API error:', errorText);
      return res.status(replicateResponse.status).json({
        error: 'Replicate API error',
        message: errorText
      });
    }

    const statusData = await replicateResponse.json();
    console.log('✅ Replicate Status: Status retrieved', {
      id: statusData.id,
      status: statusData.status,
      hasOutput: !!statusData.output
    });

    res.json(statusData);

  } catch (error) {
    console.error('❌ Replicate Status: Unexpected error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// General Enhancement endpoint
app.post('/.netlify/functions/api-v1-enhance-general', upload.single('image'), async (req, res) => {
  try {
    console.log('🚀 General Enhancement: Starting request');

    // Validate authentication
    const authHeader = req.headers.authorization || req.headers.Authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Authentication required',
        message: 'Please provide a valid Bearer token'
      });
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return res.status(401).json({
        error: 'Invalid token',
        message: 'Authentication failed'
      });
    }

    console.log('✅ General Enhancement: User authenticated:', user.email);

    // Handle both multipart and JSON requests
    let imageData, settings;
    
    if (req.file) {
      // Multipart form data
      imageData = `data:image/jpeg;base64,${req.file.buffer.toString('base64')}`;
      settings = {
        scale: req.body.scale || 2,
        sharpen: req.body.sharpen || 45,
        denoise: req.body.denoise || 30,
        face_recovery: req.body.face_recovery === 'true'
      };
    } else if (req.body.input && req.body.input.image) {
      // JSON request (from mobile app)
      imageData = req.body.input.image;
      settings = {
        scale: req.body.input.scale || 2,
        sharpen: req.body.input.sharpen || 45,
        denoise: req.body.input.denoise || 30,
        face_recovery: req.body.input.face_recovery || false
      };
    } else {
      return res.status(400).json({
        error: 'Missing image',
        message: 'Please provide an image file or base64 image data'
      });
    }

    console.log('📸 General Enhancement: Processing image', {
      hasImage: !!imageData,
      settings: settings
    });

    // Create prediction using Replicate API
    const replicateResponse = await fetch('https://api.replicate.com/v1/predictions', {
      method: 'POST',
      headers: {
        'Authorization': `Token ${process.env.REPLICATE_API_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        version: process.env.REPLICATE_MODEL_VERSION || 'df9a3c1d',
        input: {
          image: imageData,
          scale: parseInt(settings.scale),
          sharpen: parseInt(settings.sharpen),
          denoise: parseInt(settings.denoise),
          face_recovery: settings.face_recovery
        }
      })
    });

    if (!replicateResponse.ok) {
      const errorText = await replicateResponse.text();
      console.log('❌ General Enhancement: Replicate API error:', errorText);
      return res.status(replicateResponse.status).json({
        error: 'Replicate API error',
        message: errorText
      });
    }

    const replicateData = await replicateResponse.json();
    console.log('✅ General Enhancement: Prediction created', {
      id: replicateData.id,
      status: replicateData.status
    });

    res.status(201).json(replicateData);

  } catch (error) {
    console.error('❌ General Enhancement: Unexpected error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Start server
app.listen(port, () => {
  console.log(`🚀 Opera Studio API Server running on port ${port}`);
  console.log(`📡 Endpoints available:`);
  console.log(`   POST /.netlify/functions/replicate-predict`);
  console.log(`   GET  /.netlify/functions/replicate-status/:id`);
  console.log(`   POST /.netlify/functions/api-v1-enhance-general`);
  console.log(`   GET  /health`);
});

module.exports = app; 