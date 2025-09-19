const { createClient } = require('@supabase/supabase-js');
const readline = require('readline');

// Initialize Supabase client
const supabase = createClient(
  'https://rnygtixdxbnflxflzpyr.supabase.co',
  'sb_publishable_7jmrzEA_j5vrXtP4OWhEBA_UjDD32z3'
);

// Create readline interface for user input
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function askQuestion(question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      resolve(answer);
    });
  });
}

async function getToken() {
  console.log('🔐 Supabase Token Generator');
  console.log('==========================\n');
  
  try {
    // Get credentials
    const email = await askQuestion('📧 Enter your email: ');
    const password = await askQuestion('🔒 Enter your password: ');
    
    console.log('\n🔄 Signing in...');
    
    // Sign in
    const { data, error } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password: password.trim()
    });
    
    if (error) {
      console.log('❌ Sign in failed:', error.message);
      
      if (error.message.includes('Invalid login credentials')) {
        console.log('\n💡 Suggestions:');
        console.log('   - Check your email and password');
        console.log('   - Make sure your account exists');
        console.log('   - Try signing up first if you\'re new');
      }
      
      rl.close();
      return;
    }
    
    console.log('✅ Sign in successful!');
    console.log('👤 User:', data.user.email);
    
    // Get session
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    
    if (sessionError || !session) {
      console.log('❌ Failed to get session:', sessionError?.message || 'No session');
      rl.close();
      return;
    }
    
    const token = session.access_token;
    
    console.log('\n🎯 SUCCESS! Here\'s your JWT token:');
    console.log('=====================================');
    console.log(token);
    console.log('=====================================');
    
    console.log('\n📊 Token Info:');
    console.log('   Length:', token.length, 'characters');
    console.log('   Expires:', new Date(session.expires_at * 1000));
    console.log('   Preview:', token.substring(0, 50) + '...');
    
    console.log('\n🧪 Test this token with:');
    console.log('curl -X POST https://operastudio.io/.netlify/functions/replicate-predict \\');
    console.log('  -H "Content-Type: application/json" \\');
    console.log('  -H "Authorization: Bearer ' + token + '" \\');
    console.log('  -d \'{"input":{"image":"data:image/jpeg;base64,test"}}\'');
    
    console.log('\n✅ Expected result: 400 (bad image data) or 200 (success)');
    console.log('❌ If you get 401, there\'s an authentication problem');
    
  } catch (error) {
    console.log('❌ Error:', error.message);
  }
  
  rl.close();
}

// Run the script
getToken(); 