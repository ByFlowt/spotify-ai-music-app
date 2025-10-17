/**
 * AUDD Audio Recognition Proxy Endpoint
 * Securely proxies requests to AUDD.io API
 * 
 * Usage from Flutter:
 * POST https://your-app.vercel.app/api/audd
 * Body: { "audio": "base64_encoded_audio" }
 */

const fetch = require('node-fetch');
const FormData = require('form-data');

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const AUDD_API_KEY = process.env.AUDD_API_KEY;
  
  if (!AUDD_API_KEY) {
    return res.status(500).json({ error: 'API key not configured' });
  }

  try {
    const { audio } = req.body;
    
    if (!audio) {
      return res.status(400).json({ error: 'Audio data is required' });
    }

    // Create form data for AUDD API
    const formData = new FormData();
    formData.append('api_token', AUDD_API_KEY);
    formData.append('audio', audio);

    const response = await fetch('https://api.audd.io/', {
      method: 'POST',
      body: formData
    });

    const data = await response.json();
    res.status(200).json(data);
    
  } catch (error) {
    console.error('AUDD API Error:', error);
    res.status(500).json({ error: 'Failed to process request' });
  }
};
