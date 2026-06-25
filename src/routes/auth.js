const express = require('express');
const bcrypt = require('bcryptjs');
const pool = require('../config/db');
const { generateToken } = require('../utils/auth');

const router = express.Router();

// POST /api/register - 用户注册
router.post('/register', async (req, res) => {
  try {
    const { username, password, phone, email, nickname } = req.body;
    if (!username || !password) {
      return res.json({ code: 400, message: '用户名和密码不能为空', data: null });
    }

    const [exist] = await pool.query('SELECT id FROM user WHERE username = ?', [username]);
    if (exist.length > 0) {
      return res.json({ code: 400, message: '用户名已存在', data: null });
    }

    if (phone) {
      const [phoneExist] = await pool.query('SELECT id FROM user WHERE phone = ?', [phone]);
      if (phoneExist.length > 0) {
        return res.json({ code: 400, message: '手机号已注册', data: null });
      }
    }

    const hashedPassword = bcrypt.hashSync(password, 10);
    const [result] = await pool.query(
      'INSERT INTO user (username, password, phone, email, nickname, role) VALUES (?, ?, ?, ?, ?, ?)',
      [username, hashedPassword, phone || null, email || null, nickname || null, 'user']
    );

    const [rows] = await pool.query('SELECT id, username, phone, email, nickname, avatar, role FROM user WHERE id = ?', [result.insertId]);
    const user = rows[0];
    const token = generateToken({ id: user.id, username: user.username, role: user.role });

    res.json({ code: 200, message: '注册成功', data: { token, user } });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// POST /api/login - 用户登录
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.json({ code: 400, message: '用户名和密码不能为空', data: null });
    }

    const [rows] = await pool.query('SELECT * FROM user WHERE username = ?', [username]);
    if (rows.length === 0) {
      return res.json({ code: 400, message: '用户不存在', data: null });
    }

    const user = rows[0];
    const isMatch = bcrypt.compareSync(password, user.password);
    if (!isMatch) {
      return res.json({ code: 400, message: '密码错误', data: null });
    }

    const token = generateToken({ id: user.id, username: user.username, role: user.role });
    const userData = {
      id: user.id,
      username: user.username,
      phone: user.phone,
      email: user.email,
      nickname: user.nickname,
      avatar: user.avatar,
      role: user.role
    };

    res.json({ code: 200, message: '登录成功', data: { token, user: userData } });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// POST /api/sms/send - 发送验证码（演示模式返回 123456）
router.post('/sms/send', async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      return res.json({ code: 400, message: '手机号不能为空', data: null });
    }
    res.json({ code: 200, message: '验证码已发送', data: { code: '123456' } });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// POST /api/login/phone - 手机号+验证码登录（演示模式验证码 123456）
router.post('/login/phone', async (req, res) => {
  try {
    const { phone, code } = req.body;
    if (!phone || !code) {
      return res.json({ code: 400, message: '手机号和验证码不能为空', data: null });
    }
    if (code !== '123456') {
      return res.json({ code: 400, message: '验证码错误', data: null });
    }

    const [rows] = await pool.query('SELECT * FROM user WHERE phone = ?', [phone]);
    if (rows.length === 0) {
      return res.json({ code: 400, message: '该手机号未注册', data: null });
    }

    const user = rows[0];
    const token = generateToken({ id: user.id, username: user.username, role: user.role });
    const userData = {
      id: user.id,
      username: user.username,
      phone: user.phone,
      email: user.email,
      nickname: user.nickname,
      avatar: user.avatar,
      role: user.role
    };

    res.json({ code: 200, message: '登录成功', data: { token, user: userData } });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// POST /api/register/phone - 手机号注册
router.post('/register/phone', async (req, res) => {
  try {
    const { username, phone, code, password, nickname } = req.body;
    if (!phone || !code) {
      return res.json({ code: 400, message: '手机号和验证码不能为空', data: null });
    }
    if (code !== '123456') {
      return res.json({ code: 400, message: '验证码错误', data: null });
    }
    if (!password) {
      return res.json({ code: 400, message: '密码不能为空', data: null });
    }

    // username 缺省时回退到 user_+phone，保证字段非空
    const finalUsername = username || ('user_' + phone);

    const [exist] = await pool.query('SELECT id FROM user WHERE username = ?', [finalUsername]);
    if (exist.length > 0) {
      return res.json({ code: 400, message: '用户名已存在', data: null });
    }

    const [phoneExist] = await pool.query('SELECT id FROM user WHERE phone = ?', [phone]);
    if (phoneExist.length > 0) {
      return res.json({ code: 400, message: '手机号已注册', data: null });
    }

    const hashedPassword = bcrypt.hashSync(password, 10);
    const [result] = await pool.query(
      'INSERT INTO user (username, password, phone, nickname, role) VALUES (?, ?, ?, ?, ?)',
      [finalUsername, hashedPassword, phone, nickname || finalUsername, 'user']
    );

    const [rows] = await pool.query('SELECT id, username, phone, email, nickname, avatar, role FROM user WHERE id = ?', [result.insertId]);
    const user = rows[0];
    const token = generateToken({ id: user.id, username: user.username, role: user.role });

    res.json({ code: 200, message: '注册成功', data: { token, user } });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// POST /api/merchant/login - 商家登录
router.post('/merchant/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.json({ code: 400, message: '用户名和密码不能为空', data: null });
    }

    const [rows] = await pool.query('SELECT * FROM user WHERE username = ?', [username]);
    if (rows.length === 0) {
      // 账号不存在，检查是否为待审核/已拒绝的申请，给出明确提示
      const [apps] = await pool.query(
        'SELECT status, reject_reason FROM merchant_application WHERE username = ? ORDER BY created_at DESC LIMIT 1',
        [username]
      );
      if (apps.length > 0) {
        if (apps[0].status === 'pending') {
          return res.json({ code: 403, message: '您的入驻申请正在审核中，通过后即可登录', data: null });
        }
        if (apps[0].status === 'rejected') {
          return res.json({ code: 403, message: '您的入驻申请未通过审核：' + (apps[0].reject_reason || '资料不符'), data: null });
        }
      }
      return res.json({ code: 400, message: '商家账号不存在，请先注册', data: null });
    }

    const user = rows[0];
    const isMatch = bcrypt.compareSync(password, user.password);
    if (!isMatch) {
      return res.json({ code: 400, message: '密码错误', data: null });
    }

    if (user.role !== 'merchant') {
      return res.json({ code: 403, message: '该账号非商家账号，无权登录', data: null });
    }

    const token = generateToken({ id: user.id, username: user.username, role: user.role, hospitalId: user.hospital_id });
    const userData = {
      id: user.id,
      username: user.username,
      phone: user.phone,
      email: user.email,
      nickname: user.nickname,
      avatar: user.avatar,
      role: user.role,
      hospital_id: user.hospital_id
    };

    res.json({ code: 200, message: '登录成功', data: { token, user: userData, hospital_id: user.hospital_id } });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

module.exports = router;
