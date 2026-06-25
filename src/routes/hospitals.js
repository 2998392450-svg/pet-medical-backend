const express = require('express');
const pool = require('../config/db');
const { verifyToken, requireMerchant } = require('../utils/auth');

const router = express.Router();

// GET /api/hospitals?city=上海 - 获取医院列表
router.get('/', async (req, res) => {
  try {
    const { city, keyword } = req.query;
    let sql = 'SELECT * FROM hospital WHERE 1=1';
    let params = [];

    if (city) {
      sql += ' AND (city = ? OR address LIKE ?)';
      params.push(city, '%' + city + '%');
    }
    if (keyword) {
      sql += ' AND (name LIKE ? OR description LIKE ?)';
      params.push('%' + keyword + '%', '%' + keyword + '%');
    }
    sql += ' ORDER BY rating DESC, created_at DESC';

    const [rows] = await pool.query(sql, params);
    res.json({ code: 200, message: 'success', data: rows });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// GET /api/hospitals/:id - 获取医院详情
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM hospital WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      return res.json({ code: 404, message: '医院不存在', data: null });
    }
    res.json({ code: 200, message: 'success', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// PUT /api/hospitals/:id - 修改医院信息（商家用）
router.put('/:id', verifyToken, requireMerchant, async (req, res) => {
  try {
    const { name, address, phone, description, business_hours, night_service, exotic_accept, emergency_support, services, rating, lng, lat } = req.body;
    const [exist] = await pool.query('SELECT id FROM hospital WHERE id = ?', [req.params.id]);
    if (exist.length === 0) {
      return res.json({ code: 404, message: '医院不存在', data: null });
    }

    await pool.query(
      `UPDATE hospital SET name = ?, address = ?, phone = ?, description = ?, business_hours = ?, night_service = ?, exotic_accept = ?, emergency_support = ?, services = ?, rating = ?, lng = ?, lat = ? WHERE id = ?`,
      [
        name || null, address || null, phone || null, description || null,
        business_hours || null,
        night_service ? 1 : 0, exotic_accept ? 1 : 0, emergency_support ? 1 : 0,
        services || null, rating || 0,
        lng || null, lat || null,
        req.params.id
      ]
    );

    const [rows] = await pool.query('SELECT * FROM hospital WHERE id = ?', [req.params.id]);
    res.json({ code: 200, message: '修改成功', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// GET /api/hospitals/:id/doctors - 获取医院医生列表
router.get('/:id/doctors', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM doctor WHERE hospital_id = ? ORDER BY rating DESC', [req.params.id]);
    res.json({ code: 200, message: 'success', data: rows });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// ===== 医生相关路由（挂载到 /api/doctors）=====

const doctorRouter = express.Router();

// GET /api/doctors/:id - 获取医生详情
doctorRouter.get('/:id', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM doctor WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      return res.json({ code: 404, message: '医生不存在', data: null });
    }
    res.json({ code: 200, message: 'success', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// PUT /api/doctors/:id - 修改医生排班（商家用）
doctorRouter.put('/:id', verifyToken, requireMerchant, async (req, res) => {
  try {
    const { name, title, specialty, rating, work_hours, work_days, description } = req.body;
    const [exist] = await pool.query('SELECT id FROM doctor WHERE id = ?', [req.params.id]);
    if (exist.length === 0) {
      return res.json({ code: 404, message: '医生不存在', data: null });
    }

    await pool.query(
      `UPDATE doctor SET name = ?, title = ?, specialty = ?, rating = ?, work_hours = ?, work_days = ?, description = ? WHERE id = ?`,
      [name || null, title || null, specialty || null, rating || 0, work_hours || null, work_days || null, description || null, req.params.id]
    );

    const [rows] = await pool.query('SELECT * FROM doctor WHERE id = ?', [req.params.id]);
    res.json({ code: 200, message: '修改成功', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

module.exports = router;
module.exports.doctorRouter = doctorRouter;
