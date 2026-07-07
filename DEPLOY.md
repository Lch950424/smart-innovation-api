# 🚀 DigitalOcean 部署指南 (使用 GitHub 學生開發包)

這份指南將引導你如何將這個專案部署到網路上，獲得一個可供外部網路（例如：手機、感測器晶片）存取的 **HTTPS** 網址。

---

## 步驟一：將專案推送到 GitHub

1. 在你的 GitHub 帳號上建立一個新的儲存庫 (Repository)，名稱可以叫 `smart-innovation-api`。
2. 在你的本機專案目錄下執行以下指令，將程式碼推送到 GitHub：
   ```bash
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin <你的 GitHub 儲存庫網址>
   git push -u origin main
   ```

---

## 步驟二：啟用 DigitalOcean 學生優惠

1. 前往 [GitHub Student Developer Pack](https://education.github.com/pack)。
2. 登入後找到 **DigitalOcean**，點選獲取優惠代碼（Promo Code）。
3. 註冊/登入 [DigitalOcean](https://www.digitalocean.com/) 帳號，並在帳戶設定的 **Billing** (帳單) 頁面中，輸入該優惠代碼。
4. 你將獲得 **$200 美元** 的免費額度（有效期限 1 年）。

---

## 步驟三：在 DigitalOcean App Platform 部署

我們使用 **App Platform** (PaaS 服務)，這不需要設定 Linux，會自動偵測 Node.js 並完成部署。

1. 登入 DigitalOcean 控制台，點選右上角的 **Create** ➔ 選擇 **Apps**。
2. **Service Provider** 選擇 **GitHub**，授權並選擇你剛剛推送的 `smart-innovation-api` 儲存庫。
3. 設定 App 參數：
   * **Region**：選擇靠近台灣的區域，例如 **Singapore (新加坡)**。
   * **Branch**：選擇 `main`。
   * **Source Directory**：保持 `/` (根目錄)。
   * 點選 **Next**。
4. **Resources (資源配置)**：
   * 系統會自動偵測這是一個 Web Service。
   * 點選 Web Service 的 **Edit** 編輯按鈕。
   * **Size**：選擇 **Basic** ➔ **Micro ($5.00/mo - 512MB RAM, 1 vCPU)**。*這筆費用會直接從你獲得的 $200 學生額度中扣除，完全免費！*
   * **Run Command**：確保是 `npm start`。
   * **HTTP Port**：確保是 `3000` (如果沒有自動偵測到，手動新增)。
   * 點選 **Back**，然後點選 **Next**。
5. **Environment Variables (環境變數)**：
   * 暫時不需要新增，點選 **Next**。
6. **Info (專案名稱)**：
   * 可自訂你的專案名稱與網址前綴。
7. **Review & Create**：
   * 確認帳單估算為 `$5.00/mo`，點選 **Create Resources**。

---

## 步驟四：完成與測試

1. 點選建立後，DigitalOcean 會開始建置 (Building) 並部署 (Deploying)。這通常需要 2~3 分鐘。
2. 部署成功後，頁面上方會顯示一個綠色的公開網址（例如：`https://smart-innovation-api-xxxx.ondigitalocean.app`）。
3. 用瀏覽器開啟該網址，你將會看到我們設計的 **智慧創新 API 測試控制台**！
4. **測試 POST 請求**：
   * 你可以使用網頁左側的模擬器發送資料。
   * 或者從你的 Python 爬蟲、ESP32/Arduino 單晶片，向該網址發送 POST 請求：
     `POST https://<你的APP網址>/api/messages`
     Payload: `{"sensor": "temperature", "value": 25.4}`
   * 在網頁的「即時接收日誌 (Live Logs)」中，將會即時秀出接收到的資料！

---

## 本地開發與運行

如果你想在部署前先在本機運行測試：
1. 安裝套件：
   ```bash
   npm install
   ```
2. 啟動伺服器：
   ```bash
   npm start
   ```
3. 開啟網頁 `http://localhost:3000` 進行測試。
