const cors = require('cors');

module.exports = cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:5173',
  credentials: true
});
