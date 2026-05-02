#!/usr/bin/env bash
set -e

# -------- HELP --------
show_help() {
  echo ""
  echo "MERN Setup CLI"
  echo ""
  echo "Usage:"
  echo "  mern-setup [project-name]"
  echo ""
  echo "Example:"
  echo "  mern-setup myapp"
  echo ""
  echo "Features:"
  echo "  - Express backend (MVC)"
  echo "  - React frontend (Vite)"
  echo "  - Tailwind CSS"
  echo "  - MongoDB .env setup"
  echo ""
}

if [[ "${1:-}" == "-help" || "${1:-}" == "--help" ]]; then
  show_help
  exit 0
fi

# -------- INTERACTIVE --------
echo ""
echo "==========================================="
echo "        MERN Setup Interactive Mode"
echo "==========================================="
echo ""

read -p "Project name (default: mern-app): " INPUT_NAME
APP_NAME=${INPUT_NAME:-mern-app}

read -p "MongoDB URI (leave blank to fill later): " MONGO_INPUT
MONGO_URI=${MONGO_INPUT:-your_mongodb_connection_string_here}

read -p "JWT Secret (default: devsecret): " JWT_INPUT
JWT_SECRET=${JWT_INPUT:-devsecret}

read -p "Frontend URL (default: http://localhost:5173): " FRONTEND_INPUT
FRONTEND_URL=${FRONTEND_INPUT:-http://localhost:5173}

echo ""
echo "-------------------------------------------"
echo "Confirm Setup:"
echo "Project: $APP_NAME"
echo "Mongo URI: $MONGO_URI"
echo "Frontend URL: $FRONTEND_URL"
echo "-------------------------------------------"

read -p "Continue? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Setup cancelled."
  exit 0
fi

# -------- ROOT --------
mkdir "$APP_NAME"
cd "$APP_NAME"

# =========================
# BACKEND (MVC)
# =========================
echo "Setting up backend..."
mkdir backend
cd backend

npm init -y
npm install express mongoose cors dotenv
npm install nodemon --save-dev

node -e "
let pkg=require('./package.json');
pkg.scripts={dev:'nodemon server.js',start:'node server.js'};
require('fs').writeFileSync('package.json', JSON.stringify(pkg,null,2));
"

mkdir controllers models routes middleware

# MODEL
cat <<EOF > models/appModel.js
const mongoose = require('mongoose');

const appSchema = new mongoose.Schema({
  message: { type: String, required: true }
}, { timestamps: true });

module.exports = mongoose.model('App', appSchema);
EOF

# CONTROLLER
cat <<EOF > controllers/appController.js
const App = require('../models/appModel');

exports.getApi = async (req, res, next) => {
  try {
    const data = await App.findOne();
    res.json(data || { message: "API running" });
  } catch (err) {
    next(err);
  }
};
EOF

# ROUTES
cat <<EOF > routes/appRoutes.js
const express = require('express');
const router = express.Router();
const { getApi } = require('../controllers/appController');

router.get('/', getApi);

module.exports = router;
EOF

# CORS
cat <<EOF > middleware/corsMiddleware.js
const cors = require('cors');

module.exports = cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:5173',
  credentials: true
});
EOF

# ERROR HANDLER
cat <<EOF > middleware/errorMiddleware.js
module.exports = (err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: err.message || "Server Error" });
};
EOF

# SERVER
cat <<EOF > server.js
const express = require('express');
const mongoose = require('mongoose');
require('dotenv').config();

const corsMiddleware = require('./middleware/corsMiddleware');
const errorMiddleware = require('./middleware/errorMiddleware');
const appRoutes = require('./routes/appRoutes');

const app = express();

app.use(corsMiddleware);
app.use(express.json());

app.use('/api', appRoutes);

mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('MongoDB Connected'))
  .catch(err => console.log(err));

const PORT = process.env.PORT || 5000;

app.use(errorMiddleware);

app.listen(PORT, () => {
  console.log(\`Server running on port \${PORT}\`);
});
EOF

# ENV
cat <<EOF > .env
PORT=5000
MONGO_URI=$MONGO_URI
JWT_SECRET=$JWT_SECRET
FRONTEND_URL=$FRONTEND_URL
EOF

cd ..

# =========================
# FRONTEND
# =========================
echo "Setting up frontend..."
npm create vite@latest frontend -- --template react
cd frontend

npm install

npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

cat <<EOF > tailwind.config.js
export default {
  content: ["./index.html","./src/**/*.{js,ts,jsx,tsx}"],
  theme: { extend: {} },
  plugins: [],
}
EOF

cat <<EOF > src/index.css
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

cat <<EOF > src/App.jsx
import { useEffect, useState } from "react";

function App() {
  const [msg, setMsg] = useState("");

  useEffect(() => {
    fetch("http://localhost:5000/api")
      .then(res => res.json())
      .then(data => setMsg(data.message));
  }, []);

  return (
    <div className="flex items-center justify-center h-screen">
      <h1 className="text-3xl font-bold text-blue-600">
        {msg || "Loading..."}
      </h1>
    </div>
  );
}

export default App;
EOF

cd ..

# =========================
# SUCCESS
# =========================
echo ""
echo "==========================================="
echo "   ✅ MERN Project Created Successfully"
echo "==========================================="
echo ""

echo "Project: $APP_NAME"
echo ""

echo "Run backend:"
echo "  cd $APP_NAME/backend && npm run dev"
echo ""

echo "Run frontend:"
echo "  cd $APP_NAME/frontend && npm run dev"
echo ""

echo "Frontend: http://localhost:5173"
echo "Backend API: http://localhost:5000/api"
echo ""

echo "⚠️ Add your MongoDB URI in backend/.env"
echo ""
echo "🚀 Ready to build!"
