const express = require('express');
const mongoose = require('mongoose');
require('dotenv').config();

const app = express();
app.use(require('cors')({ origin: process.env.FRONTEND_URL }));

app.get('/api', (req,res)=>res.json({message:'API running'}));

mongoose.connect(process.env.MONGO_URI)
.then(()=>console.log('MongoDB Connected'))
.catch(console.error);

app.listen(5000, ()=>console.log('Server running on 5000'));
