const app = require("express")();
app.get("/test", (req, res) => res.json({status: "ok"}));
module.exports = app;
