const App = require('../models/appModel');

exports.getApi = async (req, res, next) => {
  try {
    const data = await App.findOne();
    res.json(data || { message: "API running" });
  } catch (err) {
    next(err);
  }
};
