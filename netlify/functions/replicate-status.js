const { createClient } = require('@supabase/supabase-js');

// Initialize Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

exports.handler = async (event, context) => {
  // Handle CORS
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  };

  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: '',
    };
  }

  try {
    console.log('🔍 Replicate Status: Starting request');
    console.log('Request method:', event.httpMethod);
    console.log('Request path:', event.path);

    // Extract prediction ID from path
    const pathParts = event.path.split('/');
    const predictionId = pathParts[pathParts.length - 1];
    
    if (!predictionId) {
      console.log('❌ Replicate Status: No prediction ID provided');
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: 'Missing prediction ID',
          message: 'Please provide a prediction ID in the URL path'
        }),
      };
    }

    console.log('🔍 Replicate Status: Checking status for prediction:', predictionId);

    // Validate authentication
    const authHeader = event.headers.authorization || event.headers.Authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      console.log('❌ Replicate Status: No valid authorization header');
      return {
        statusCode: 401,
        headers,
        body: JSON.stringify({
          error: 'Authentication required',
          message: 'Please provide a valid Bearer token'
        }),
      };
    }

    const token = authHeader.replace('Bearer ', '');
    console.log('🔐 Replicate Status: Token received (first 20 chars):', token.substring(0, 20) + '...');

    // Verify Supabase session
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      console.log('❌ Replicate Status: Authentication failed:', authError?.message);
      return {
        statusCode: 401,
        headers,
        body: JSON.stringify({
          error: 'Invalid token',
          message: 'Authentication failed'
        }),
      };
    }

    console.log('✅ Replicate Status: User authenticated:', user.email);

    // Call Replicate API to get prediction status
    const replicateResponse = await fetch(`https://api.replicate.com/v1/predictions/${predictionId}`, {
      method: 'GET',
      headers: {
        'Authorization': `Token ${process.env.REPLICATE_API_TOKEN}`,
        'Content-Type': 'application/json',
      }
    });

    if (!replicateResponse.ok) {
      const errorText = await replicateResponse.text();
      console.log('❌ Replicate Status: Replicate API error:', errorText);
      return {
        statusCode: replicateResponse.status,
        headers,
        body: JSON.stringify({
          error: 'Replicate API error',
          message: errorText
        }),
      };
    }

    const replicateData = await replicateResponse.json();
    console.log('✅ Replicate Status: Status retrieved', {
      id: replicateData.id,
      status: replicateData.status,
      hasOutput: !!replicateData.output
    });

    // Return the response in the format expected by the mobile app
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
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
        started_at: replicateData.started_at,
        completed_at: replicateData.completed_at,
        urls: replicateData.urls
      }),
    };

  } catch (error) {
    console.error('❌ Replicate Status: Unexpected error:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: 'Internal server error',
        message: error.message
      }),
    };
  }
};
