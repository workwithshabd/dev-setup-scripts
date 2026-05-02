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
  console.log(`Server running on port ${PORT}`);
});
