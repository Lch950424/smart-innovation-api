const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// 啟用 CORS，允許跨網域請求 (外部設備、前端網頁等)
app.use(cors());

// 支援解析 JSON 格式的 Request Body
app.use(express.json());
// 支援解析 URL-encoded 格式的 Request Body
app.use(express.urlencoded({ extended: true }));

// 靜態檔案目錄 (用於提供測試網頁)
app.use(express.static(path.join(__dirname, 'public')));

// 記憶體中暫存接收到的資料 (Demo 用，重新啟動會清空)
const messageLog = [];

// 限制日誌最大記錄筆數
const MAX_LOG_SIZE = 50;

// API Route: 取得所有接收到的 POST 訊息
app.get('/api/messages', (req, res) => {
  res.json({
    status: 'success',
    count: messageLog.length,
    data: messageLog
  });
});

// API Route: 接收外部 POST 請求
app.post('/api/messages', (req, res) => {
  const payload = req.body;
  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  const receivedAt = new Date().toISOString();

  console.log(`[API POST] 接收到來自 ${clientIp} 的請求:`, JSON.stringify(payload, null, 2));

  // 封裝記錄資料
  const logEntry = {
    id: Date.now().toString(36) + Math.random().toString(36).substr(2, 5),
    receivedAt,
    senderIp: clientIp,
    headers: req.headers,
    body: payload
  };

  // 插入到記錄陣列的最前面 (最新的一筆在最上)
  messageLog.unshift(logEntry);

  // 超過最大限制時刪除舊紀錄
  if (messageLog.length > MAX_LOG_SIZE) {
    messageLog.pop();
  }

  // 回傳成功回應
  res.status(201).json({
    status: 'success',
    message: '資料已成功接收！',
    receivedData: logEntry
  });
});

// 根路由 (回傳測試首頁)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// 啟動伺服器
app.listen(PORT, () => {
  console.log(`=========================================`);
  console.log(`🚀 伺服器已啟動！連線至: http://localhost:${PORT}`);
  console.log(`📡 API POST 接口: http://localhost:${PORT}/api/messages`);
  console.log(`=========================================`);
});
