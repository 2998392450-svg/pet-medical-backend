const express = require('express');
const pool = require('../config/db');
const { verifyToken, requireMerchant } = require('../utils/auth');

const router = express.Router();

// POST /api/appointments - 创建预约（status='pending'）
router.post('/', async (req, res) => {
  try {
    const { userId, petId, hospitalId, doctorId, petName, petBreed, petWeight, userName, appointmentDate, timeSlot, reason, notes, contactPhone } = req.body;
    if (!userId || !hospitalId || !appointmentDate || !timeSlot) {
      return res.json({ code: 400, message: '缺少必填字段', data: null });
    }

    const [result] = await pool.query(
      `INSERT INTO appointment (user_id, hospital_id, doctor_id, pet_id, pet_name, pet_breed, pet_weight, user_name, appointment_date, time_slot, reason, notes, contact_phone, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')`,
      [userId, hospitalId, doctorId || null, petId || null, petName || null, petBreed || null, petWeight || null, userName || null, appointmentDate, timeSlot, reason || null, notes || null, contactPhone || null]
    );

    const [rows] = await pool.query('SELECT * FROM appointment WHERE id = ?', [result.insertId]);
    res.json({ code: 200, message: '预约创建成功', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// GET /api/appointments/merchant/stats - 商家统计数据（必须放在 /:id 之前避免路由冲突）
router.get('/merchant/stats', async (req, res) => {
  try {
    const { hospitalId } = req.query;
    if (!hospitalId) {
      return res.json({ code: 400, message: '缺少 hospitalId 参数', data: null });
    }

    const today = new Date();
    const todayStr = today.toISOString().slice(0, 10);
    const monthStr = todayStr.slice(0, 7);

    const [todayRows] = await pool.query('SELECT COUNT(*) AS count FROM appointment WHERE hospital_id = ? AND appointment_date = ?', [hospitalId, todayStr]);
    const [pendingRows] = await pool.query("SELECT COUNT(*) AS count FROM appointment WHERE hospital_id = ? AND status = 'pending'", [hospitalId]);
    const [monthRows] = await pool.query('SELECT COUNT(*) AS count FROM appointment WHERE hospital_id = ? AND appointment_date LIKE ?', [hospitalId, monthStr + '%']);

    res.json({
      code: 200,
      message: 'success',
      data: {
        todayCount: todayRows[0].count,
        pendingCount: pendingRows[0].count,
        monthCount: monthRows[0].count
      }
    });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// GET /api/appointments/merchant - 商家获取本医院所有预约
router.get('/merchant', async (req, res) => {
  try {
    const { hospitalId, status } = req.query;
    if (!hospitalId) {
      return res.json({ code: 400, message: '缺少 hospitalId 参数', data: null });
    }

    let sql = `SELECT a.*, h.name AS hospital_name
               FROM appointment a
               LEFT JOIN hospital h ON a.hospital_id = h.id
               WHERE a.hospital_id = ?`;
    let params = [hospitalId];
    if (status) {
      sql += ' AND a.status = ?';
      params.push(status);
    }
    sql += ' ORDER BY a.appointment_date DESC, a.created_at DESC';

    const [rows] = await pool.query(sql, params);
    res.json({ code: 200, message: 'success', data: rows });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// GET /api/appointments?userId=xx - 获取用户预约列表
router.get('/', async (req, res) => {
  try {
    const { userId, status } = req.query;
    if (!userId) {
      return res.json({ code: 400, message: '缺少 userId 参数', data: null });
    }

    let sql = `SELECT a.*, h.name AS hospital_name, h.address AS hospital_address, h.phone AS hospital_phone,
               d.name AS doctor_name, d.title AS doctor_title
               FROM appointment a
               LEFT JOIN hospital h ON a.hospital_id = h.id
               LEFT JOIN doctor d ON a.doctor_id = d.id
               WHERE a.user_id = ?`;
    let params = [userId];
    if (status) {
      sql += ' AND a.status = ?';
      params.push(status);
    }
    sql += ' ORDER BY a.appointment_date DESC, a.created_at DESC';

    const [rows] = await pool.query(sql, params);
    res.json({ code: 200, message: 'success', data: rows });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// GET /api/appointments/:id - 获取预约详情
router.get('/:id', async (req, res) => {
  try {
    const sql = `SELECT a.*, h.name AS hospital_name, h.address AS hospital_address, h.phone AS hospital_phone,
                 h.business_hours AS hospital_hours, h.night_service, h.exotic_accept, h.emergency_support,
                 d.name AS doctor_name, d.title AS doctor_title, d.specialty AS doctor_specialty,
                 u.nickname AS user_nickname, u.phone AS user_phone
                 FROM appointment a
                 LEFT JOIN hospital h ON a.hospital_id = h.id
                 LEFT JOIN doctor d ON a.doctor_id = d.id
                 LEFT JOIN user u ON a.user_id = u.id
                 WHERE a.id = ?`;
    const [rows] = await pool.query(sql, [req.params.id]);
    if (rows.length === 0) {
      return res.json({ code: 404, message: '预约不存在', data: null });
    }
    res.json({ code: 200, message: 'success', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// PUT /api/appointments/:id/status - 修改预约状态（confirm/cancel/complete）
router.put('/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    const validStatus = ['pending', 'confirmed', 'completed', 'cancelled', 'confirm', 'cancel', 'complete'];
    if (!validStatus.includes(status)) {
      return res.json({ code: 400, message: '无效的预约状态', data: null });
    }

    const statusMap = { confirm: 'confirmed', cancel: 'cancelled', complete: 'completed' };
    const finalStatus = statusMap[status] || status;

    const [exist] = await pool.query('SELECT id FROM appointment WHERE id = ?', [req.params.id]);
    if (exist.length === 0) {
      return res.json({ code: 404, message: '预约不存在', data: null });
    }

    await pool.query('UPDATE appointment SET status = ? WHERE id = ?', [finalStatus, req.params.id]);
    const [rows] = await pool.query('SELECT * FROM appointment WHERE id = ?', [req.params.id]);
    res.json({ code: 200, message: '状态更新成功', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// PUT /api/appointments/:id/reschedule - 改期
router.put('/:id/reschedule', async (req, res) => {
  try {
    const { appointmentDate, timeSlot, notes } = req.body;
    if (!appointmentDate || !timeSlot) {
      return res.json({ code: 400, message: '日期和时段不能为空', data: null });
    }

    const [exist] = await pool.query('SELECT id, status FROM appointment WHERE id = ?', [req.params.id]);
    if (exist.length === 0) {
      return res.json({ code: 404, message: '预约不存在', data: null });
    }

    if (exist[0].status === 'completed' || exist[0].status === 'cancelled') {
      return res.json({ code: 400, message: '已完成的预约不能改期', data: null });
    }

    await pool.query('UPDATE appointment SET appointment_date = ?, time_slot = ?, notes = ?, status = ? WHERE id = ?',
      [appointmentDate, timeSlot, notes || null, 'pending', req.params.id]);
    const [rows] = await pool.query('SELECT * FROM appointment WHERE id = ?', [req.params.id]);
    res.json({ code: 200, message: '改期成功', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// POST /api/appointments/:id/review - 评价预约
router.post('/:id/review', async (req, res) => {
  try {
    const { rating, content } = req.body;
    const [exist] = await pool.query('SELECT id, status FROM appointment WHERE id = ?', [req.params.id]);
    if (exist.length === 0) {
      return res.json({ code: 404, message: '预约不存在', data: null });
    }
    if (exist[0].status !== 'completed') {
      return res.json({ code: 400, message: '只能评价已完成的预约', data: null });
    }

    const feedback = JSON.stringify({ rating, content, time: new Date().toLocaleString() });
    await pool.query('UPDATE appointment SET hospital_feedback = ? WHERE id = ?', [feedback, req.params.id]);
    const [rows] = await pool.query('SELECT * FROM appointment WHERE id = ?', [req.params.id]);
    res.json({ code: 200, message: '评价成功', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

module.exports = router;
