const crypto = require('crypto');
const http = require('http');

const secret = process.env.PAYMENT_WEBHOOK_SECRET || '875d3153d26ce4f54e4baa0727d3573c9ec20f4e79b364b0cfc7de7908f35603';
const orderCode = Number(process.argv[2] || 25);
const amount = Number(process.argv[3] || 10000);

const data = {
  amount: amount,
  description: `DH${orderCode}`,
  orderCode: orderCode,
};

const sortedKeys = Object.keys(data).sort();
const parts = sortedKeys.map((k) => `${k}=${data[k]}`);
const str = parts.join('&');
const sig = crypto.createHmac('sha256', secret).update(str).digest('hex');

const payload = JSON.stringify({
  code: '00',
  desc: 'success',
  data: data,
  signature: sig,
});

const https = require('https');
const targetUrl = process.argv[4] || 'http://localhost:3000/api/v1/payments/webhook';
const parsedUrl = new URL(targetUrl);
const client = parsedUrl.protocol === 'https:' ? https : http;

console.log('Sending webhook to:', targetUrl, 'order:', orderCode, 'amount:', amount);

const req = client.request(
  targetUrl,
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload),
      'ngrok-skip-browser-warning': 'true',
    },
  },
  (res) => {
    let body = '';
    res.on('data', (d) => (body += d));
    res.on('end', () => {
      console.log('Webhook Response:', res.statusCode, body);
    });
  }
);

req.on('error', (e) => console.error('Error:', e));
req.write(payload);
req.end();
