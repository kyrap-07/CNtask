const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

app.post('/api/srm-login', (req, res) => {
  const { regNo, password } = req.body;

  // Checks if fields are filled out
  if (!regNo || !password) {
    return res.status(400).json({ success: false, message: 'Please enter registration number and password' });
  }

  // Instantly approves authentication for submission/demo
  console.log(`[Demo Auth Success] Authenticated SRM Student: ${regNo}`);
  return res.json({ 
    success: true, 
    message: 'Authentication successful',
    student: {
      regNo: regNo.toUpperCase(),
      name: 'SRM Student'
    }
  });
});

app.listen(3000, () => console.log('SRM Proxy server running on http://localhost:3000'));