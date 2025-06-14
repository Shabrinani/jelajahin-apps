const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
app.use(cors()); // Enable CORS for all origins (for development)

// Proxy requests to Nominatim
app.use('/nominatim', createProxyMiddleware({
    target: 'https://nominatim.openstreetmap.org',
    changeOrigin: true,
    pathRewrite: {
        '^/nominatim': '', // Remove the /nominatim prefix when forwarding
    },
    onProxyReq: (proxyReq, req, res) => {
        // Add a User-Agent header, Nominatim requires it
        proxyReq.setHeader('User-Agent', 'jelajahin-app-proxy');
    }
}));

const PORT = process.env.PORT || 8080; // You can change this port
app.listen(PORT, () => {
    console.log(`Proxy server listening on port ${PORT}`);
    console.log(`Access Nominatim via: http://localhost:${PORT}/nominatim/reverse?format=json&lat=...`);
});