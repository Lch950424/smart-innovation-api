const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// ==========================================
// 記憶體模擬資料庫 (In-Memory Database)
// ==========================================

// 1. 用戶資料 (預設一組管理員與一組家屬)
const users = [
  { username: 'admin', password: '123', role: 'admin', elder_id: null },
  { username: 'family', password: '123', role: 'family', elder_id: 'elder-01' }
];

// 2. 長者資料 (預設一位長者，定位中心設定為 台北101 周邊)
const FENCE_CENTER = { lat: 25.0339, lng: 121.5644 }; // 圍籬中心點
const FENCE_RADIUS_METERS = 100; // 圍籬半徑 (公尺)

const elders = [
  {
    id: 'elder-01',
    name: '王大爺',
    status: 'normal', // normal, out_of_bounds, on_leave, outing
    latitude: 25.0339,
    longitude: 121.5644,
    last_active: new Date().toISOString()
  }
];

// 3. 警報記錄
let alerts = [];

// 4. 用藥提醒
let medications = [
  { id: 'med-01', elder_id: 'elder-01', med_name: '降血壓藥', remind_time: '08:00', is_administered: false },
  { id: 'med-02', elder_id: 'elder-01', med_name: '心血管保健食品', remind_time: '12:00', is_administered: false }
];

// 5. 請假/外出記錄
let leaves = [];

// 計算兩點經緯度距離 (公尺)
function getDistanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // 地球半徑 (公尺)
  const phi1 = lat1 * Math.PI/180;
  const phi2 = lat2 * Math.PI/180;
  const deltaPhi = (lat2-lat1) * Math.PI/180;
  const deltaLambda = (lon2-lon1) * Math.PI/180;

  const a = Math.sin(deltaPhi/2) * Math.sin(deltaPhi/2) +
            Math.cos(phi1) * Math.cos(phi2) *
            Math.sin(deltaLambda/2) * Math.sin(deltaLambda/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

  return R * c; // 距離 (公尺)
}

// ==========================================
// API 路由設計
// ==========================================

// 🔓 1. 登入 API
app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;
  const user = users.find(u => u.username === username && u.password === password);

  if (!user) {
    return res.status(401).json({ status: 'error', message: '帳號或密碼錯誤' });
  }

  res.json({
    status: 'success',
    data: {
      username: user.username,
      role: user.role,
      elder_id: user.elder_id,
      token: 'mock-jwt-token-' + user.role
    }
  });
});

// ⌚ 2. 手錶端 API: 傳送座標並進行電子圍籬判定
app.post('/api/wearable/status', (req, res) => {
  const { elderId, latitude, longitude } = req.body;
  const elder = elders.find(e => e.id === elderId);

  if (!elder) {
    return res.status(404).json({ status: 'error', message: '找不到該長者裝置' });
  }

  // 更新長者座標與時間
  elder.latitude = parseFloat(latitude);
  elder.longitude = parseFloat(longitude);
  elder.last_active = new Date().toISOString();

  // 計算與圍籬中心距離
  const distance = getDistanceMeters(elder.latitude, elder.longitude, FENCE_CENTER.lat, FENCE_CENTER.lng);
  let triggeredAlert = null;

  // 圍籬邏輯判定：
  // 如果超出半徑，且長者目前狀態是「正常」 (未請假、未外出)，則觸發警報！
  if (distance > FENCE_RADIUS_METERS) {
    if (elder.status === 'normal') {
      elder.status = 'out_of_bounds';

      // 產生警報記錄
      triggeredAlert = {
        id: 'alert-' + Date.now(),
        elder_id: elder.id,
        elder_name: elder.name,
        triggered_at: new Date().toISOString(),
        status: 'pending',
        lat: elder.latitude,
        lng: elder.longitude
      };
      alerts.unshift(triggeredAlert);
      console.log(`⚠️ [電子圍籬警報] 長者 ${elder.name} 超出邊界！距離: ${distance.toFixed(1)}公尺`);
    }
  } else {
    // 如果回到圍籬內，且狀態是超出邊界，則自動變回正常 (但歷史警報需要管理員手動點選確認)
    if (elder.status === 'out_of_bounds') {
      elder.status = 'normal';
    }
  }

  res.json({
    status: 'success',
    data: {
      elderStatus: elder.status,
      distanceFromCenter: distance,
      isOutOfBounds: distance > FENCE_RADIUS_METERS,
      alertTriggered: triggeredAlert !== null
    }
  });
});

// ⌚ 3. 手錶端 API: 強制發送警報
app.post('/api/wearable/alert', (req, res) => {
  const { elderId } = req.body;
  const elder = elders.find(e => e.id === elderId);

  if (!elder) {
    return res.status(404).json({ status: 'error', message: '找不到該長者裝置' });
  }

  elder.status = 'out_of_bounds';
  const newAlert = {
    id: 'alert-' + Date.now(),
    elder_id: elder.id,
    elder_name: elder.name,
    triggered_at: new Date().toISOString(),
    status: 'pending',
    lat: elder.latitude,
    lng: elder.longitude
  };
  alerts.unshift(newAlert);

  res.json({
    status: 'success',
    data: newAlert
  });
});

// 🧑‍⚕️ 4. 管理者 API: 獲取長者位置
app.get('/api/admin/elders/location', (req, res) => {
  res.json({
    status: 'success',
    fenceCenter: FENCE_CENTER,
    fenceRadius: FENCE_RADIUS_METERS,
    data: elders
  });
});

// 🧑‍⚕️ 5. 管理者 API: 獲取所有警報 (Pending 優先)
app.get('/api/admin/alerts', (req, res) => {
  res.json({
    status: 'success',
    data: alerts
  });
});

// 🧑‍⚕️ 6. 管理者 API: 確認/解除警報
app.post('/api/admin/alerts/:id/confirm', (req, res) => {
  const { id } = req.params;
  const alert = alerts.find(a => a.id === id);

  if (!alert) {
    return res.status(404).json({ status: 'error', message: '找不到該警報記錄' });
  }

  alert.status = 'confirmed_by_admin';
  alert.resolved_at = new Date().toISOString();

  // 若該長者已無其他 pending 警報，且現在已經回到圍籬內，則重置狀態為 normal
  const elder = elders.find(e => e.id === alert.elder_id);
  if (elder && elder.status === 'out_of_bounds') {
    const distance = getDistanceMeters(elder.latitude, elder.longitude, FENCE_CENTER.lat, FENCE_CENTER.lng);
    if (distance <= FENCE_RADIUS_METERS) {
      elder.status = 'normal';
    }
  }

  res.json({
    status: 'success',
    message: '管理員已確認警報',
    data: alert
  });
});

// 🧑‍⚕️ 7. 管理者 API: 獲取今日用藥狀態
app.get('/api/admin/meds/today', (req, res) => {
  res.json({
    status: 'success',
    data: medications
  });
});

// 🧑‍⚕️ 8. 管理者 API: 標記用藥確認 (餵食完成)
app.post('/api/admin/meds/:id/check', (req, res) => {
  const { id } = req.params;
  const { isAdministered } = req.body;
  const med = medications.find(m => m.id === id);

  if (!med) {
    return res.status(404).json({ status: 'error', message: '找不到該用藥記錄' });
  }

  med.is_administered = isAdministered;
  res.json({
    status: 'success',
    data: med
  });
});

// 👨‍👩‍👧 9. 家屬 API: 設定長者請假與外出狀態
app.post('/api/family/leave', (req, res) => {
  const { elderId, type } = req.body; // type: 'leave' (請假), 'outing' (外出), 'cancel' (取消回歸正常)
  const elder = elders.find(e => e.id === elderId);

  if (!elder) {
    return res.status(404).json({ status: 'error', message: '找不到該長者記錄' });
  }

  if (type === 'cancel') {
    elder.status = 'normal';
  } else if (type === 'leave') {
    elder.status = 'on_leave';
  } else if (type === 'outing') {
    elder.status = 'outing';
  }

  // 記錄請假/外出單
  const leaveEntry = {
    id: 'leave-' + Date.now(),
    elder_id: elderId,
    type,
    created_at: new Date().toISOString()
  };
  leaves.unshift(leaveEntry);

  res.json({
    status: 'success',
    message: `已成功變更狀態為 ${elder.status}`,
    data: {
      elderStatus: elder.status
    }
  });
});

// 👨‍👩‍👧 10. 家屬 API: 獲取該長者用藥清單
app.get('/api/family/meds', (req, res) => {
  res.json({
    status: 'success',
    data: medications
  });
});

// 👨‍👩‍👧 11. 家屬 API: 新增用藥提醒
app.post('/api/family/meds', (req, res) => {
  const { elderId, medName, remindTime } = req.body;

  const newMed = {
    id: 'med-' + Date.now(),
    elder_id: elderId,
    med_name: medName,
    remind_time: remindTime,
    is_administered: false
  };

  medications.push(newMed);
  res.status(201).json({
    status: 'success',
    data: newMed
  });
});

// 根路由 (回傳 Demo 控制台)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`=========================================`);
  console.log(`🚀 專案 API 伺服器已啟動！`);
  console.log(`🔗 Demo 測試控制網頁: http://localhost:${PORT}`);
  console.log(`=========================================`);
});
