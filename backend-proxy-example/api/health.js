/**
 * Health Check Endpoint
 * Simple endpoint to verify the proxy is running
 */

module.exports = async (req, res) => {
  res.status(200).json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'spotify-ai-proxy'
  });
};
