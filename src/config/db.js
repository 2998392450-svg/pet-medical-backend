const mysql = require('mysql2/promise');

// 支持环境变量配置，方便部署到云平台（Render/Railway）
// 本地开发时使用默认值，生产环境通过环境变量注入
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3307,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '123456',
  database: process.env.DB_NAME || 'pet_medical',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  // 云数据库（Aiven/PlanetScale 等）通常需要 SSL
  // rejectUnauthorized: false 避免自签证书链验证失败
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined
});

module.exports = pool;
