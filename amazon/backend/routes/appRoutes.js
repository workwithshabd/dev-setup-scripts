const express = require('express');
const router = express.Router();
const { getApi } = require('../controllers/appController');

router.get('/', getApi);

module.exports = router;
