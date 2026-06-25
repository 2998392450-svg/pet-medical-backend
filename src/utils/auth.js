const jwt = require('jsonwebtoken');

const SECRET_KEY = 'pet_medical_secret_2026';

// 验证 token 中间件
function verifyToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ code: 401, message: '未提供认证 token', data: null });
  }
  const token = authHeader.startsWith('Bearer ')
    ? authHeader.slice(7)
    : authHeader;
  try {
    const decoded = jwt.verify(token, SECRET_KEY);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ code: 401, message: 'token 无效或已过期', data: null });
  }
}

// 验证是否商家角色
function requireMerchant(req, res, next) {
  if (!req.user || req.user.role !== 'merchant') {
    return res.status(403).json({ code: 403, message: '需要商家权限', data: null });
  }
  next();
}

// 验证是否管理员角色
function requireAdmin(req, res, next) {
  if (!req.user || req.user.role !== 'admin') {
    return res.status(403).json({ code: 403, message: '需要管理员权限', data: null });
  }
  next();
}

// 生成 token
function generateToken(payload) {
  return jwt.sign(payload, SECRET_KEY, { expiresIn: '7d' });
}

module.exports = {
  SECRET_KEY,
  verifyToken,
  requireMerchant,
  requireAdmin,
  generateToken
};
