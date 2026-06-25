const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const pool = require('./config/db');

const authRoutes = require('./routes/auth');
const petsRoutes = require('./routes/pets');
const hospitalRoutes = require('./routes/hospitals');
const appointmentRoutes = require('./routes/appointments');
const merchantRoutes = require('./routes/merchant');

const app = express();
const PORT = process.env.PORT || 8080;

// 配置 CORS：生产环境通过环境变量 FRONTEND_URL 注入前端域名
const allowedOrigins = [
  'http://localhost:3000',
  'http://127.0.0.1:3000',
  process.env.FRONTEND_URL  // 生产环境前端地址，如 https://pet-medical.vercel.app
].filter(Boolean);

app.use(cors({
  origin: allowedOrigins,
  credentials: true
}));

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// 挂载所有路由
app.use('/api', authRoutes);
app.use('/api/pets', petsRoutes);
app.use('/api/hospitals', hospitalRoutes);
app.use('/api/doctors', hospitalRoutes.doctorRouter);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/merchant', merchantRoutes);

// 健康检查
app.get('/api/health', (req, res) => {
  res.json({ code: 200, message: 'success', data: { status: 'ok', time: new Date().toISOString() } });
});

// 全局错误处理
app.use((err, req, res, next) => {
  console.error('服务器错误:', err);
  res.status(500).json({ code: 500, message: err.message || '服务器内部错误', data: null });
});

// 启动服务器并测试数据库连接
async function start() {
  try {
    const conn = await pool.getConnection();
    console.log('✓ MySQL 数据库连接成功 (端口 3307, 数据库: pet_medical)');
    conn.release();
  } catch (err) {
    console.error('✗ MySQL 数据库连接失败:', err.message);
    console.error('  请检查 MySQL 是否启动、端口是否为 3307、数据库 pet_medical 是否存在');
  }

  app.listen(PORT, () => {
    console.log(`✓ 宠物医疗后端服务已启动: http://localhost:${PORT}`);
    console.log(`✓ CORS 已允许前端访问: http://localhost:3000`);
  });
}

start();

module.exports = app;
