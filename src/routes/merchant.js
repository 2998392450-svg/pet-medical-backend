const express = require('express');
const bcrypt = require('bcryptjs');
const pool = require('../config/db');
const { verifyToken, requireMerchant, requireAdmin, generateToken } = require('../utils/auth');

const router = express.Router();

// ============================================
// 商家注册相关
// ============================================

// POST /api/merchant/check-name - 检查用户名是否可用
router.post('/check-name', async (req, res) => {
  try {
    const { username } = req.body;
    if (!username) {
      return res.json({ code: 400, message: '用户名不能为空', data: null });
    }
    const [rows] = await pool.query('SELECT id FROM user WHERE username = ?', [username]);
    res.json({ code: 200, message: 'success', data: { available: rows.length === 0 } });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// POST /api/merchant/auto-auth - 自动认证（按医院名查找是否已存在）
router.post('/auto-auth', async (req, res) => {
  try {
    const { hospitalName } = req.body;
    if (!hospitalName) {
      return res.json({ code: 400, message: '医院名称不能为空', data: null });
    }
    // 模糊匹配 + 精确匹配
    const [exact] = await pool.query('SELECT id, name, address, phone FROM hospital WHERE name = ?', [hospitalName]);
    if (exact.length > 0) {
      return res.json({
        code: 200,
        message: '自动认证成功：找到同名医院',
        data: { matched: true, hospital: exact[0] }
      });
    }
    const [fuzzy] = await pool.query('SELECT id, name, address, phone FROM hospital WHERE name LIKE ?', ['%' + hospitalName + '%']);
    if (fuzzy.length > 0) {
      return res.json({
        code: 200,
        message: '找到相似医院，请确认',
        data: { matched: true, hospital: fuzzy[0], similar: fuzzy }
      });
    }
    res.json({
      code: 200,
      message: '未找到同名医院，需人工审核',
      data: { matched: false, hospital: null }
    });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// POST /api/merchant/register - 商家注册（提交入驻申请）
router.post('/register', async (req, res) => {
  try {
    const {
      hospitalName, address, phone, city, description,
      licenseUrl, contactName, contactPhone,
      username, password, hospitalId, autoMatched
    } = req.body;

    if (!hospitalName || !address || !phone || !username || !password) {
      return res.json({ code: 400, message: '医院名称、地址、电话、账号、密码不能为空', data: null });
    }

    // 校验用户名唯一
    const [userExist] = await pool.query('SELECT id FROM user WHERE username = ?', [username]);
    if (userExist.length > 0) {
      return res.json({ code: 400, message: '用户名已存在', data: null });
    }

    // 校验是否重复申请
    const [applyExist] = await pool.query(
      "SELECT id FROM merchant_application WHERE username = ? AND status = 'pending'",
      [username]
    );
    if (applyExist.length > 0) {
      return res.json({ code: 400, message: '该账号已有待审核的申请', data: null });
    }

    const hashedPassword = bcrypt.hashSync(password, 10);
    const [result] = await pool.query(
      `INSERT INTO merchant_application
       (hospital_name, address, phone, city, description, license_url, contact_name, contact_phone, username, password, hospital_id, auto_matched, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')`,
      [
        hospitalName, address, phone, city || '上海', description || null,
        licenseUrl || null, contactName || null, contactPhone || null,
        username, hashedPassword,
        hospitalId || null, autoMatched ? 1 : 0
      ]
    );

    res.json({
      code: 200,
      message: autoMatched
        ? '入驻申请已提交（自动认证通过，等待管理员审核后即可登录）'
        : '入驻申请已提交（未匹配到同名医院，需人工审核）',
      data: { applicationId: result.insertId, status: 'pending' }
    });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// GET /api/merchant/applications/status?username=xx - 查询申请状态
router.get('/applications/status', async (req, res) => {
  try {
    const { username } = req.query;
    if (!username) {
      return res.json({ code: 400, message: '用户名不能为空', data: null });
    }
    const [rows] = await pool.query(
      'SELECT id, hospital_name, status, reject_reason, created_at, reviewed_at FROM merchant_application WHERE username = ? ORDER BY created_at DESC',
      [username]
    );
    res.json({ code: 200, message: 'success', data: rows });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// ============================================
// 管理员审核相关
// ============================================

// GET /api/merchant/applications - 获取申请列表（管理员）
router.get('/applications', verifyToken, requireAdmin, async (req, res) => {
  try {
    const { status } = req.query;
    let sql = 'SELECT * FROM merchant_application';
    let params = [];
    if (status) {
      sql += ' WHERE status = ?';
      params.push(status);
    }
    sql += ' ORDER BY created_at DESC';
    const [rows] = await pool.query(sql, params);
    // 不返回密码字段
    const list = rows.map(a => ({ ...a, password: undefined }));
    res.json({ code: 200, message: 'success', data: list });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// GET /api/merchant/applications/:id - 获取申请详情（管理员）
router.get('/applications/:id', verifyToken, requireAdmin, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM merchant_application WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      return res.json({ code: 404, message: '申请不存在', data: null });
    }
    res.json({ code: 200, message: 'success', data: { ...rows[0], password: undefined } });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// PUT /api/merchant/applications/:id/approve - 审核通过（管理员）
router.put('/applications/:id/approve', verifyToken, requireAdmin, async (req, res) => {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [apps] = await conn.query('SELECT * FROM merchant_application WHERE id = ? AND status = ?', [req.params.id, 'pending']);
    if (apps.length === 0) {
      await conn.rollback();
      conn.release();
      return res.json({ code: 404, message: '申请不存在或已处理', data: null });
    }
    const app = apps[0];

    // 再次检查用户名唯一性（防止审核期间被占用）
    const [userExist] = await conn.query('SELECT id FROM user WHERE username = ?', [app.username]);
    if (userExist.length > 0) {
      await conn.rollback();
      conn.release();
      return res.json({ code: 400, message: '用户名已被占用', data: null });
    }

    // 若自动认证匹配到 hospital_id，直接关联；否则新建医院记录
    let hospitalId = app.hospital_id;
    if (!hospitalId) {
      const [hResult] = await conn.query(
        `INSERT INTO hospital (name, address, phone, city, description, license_url, verified, rating, business_hours, night_service, exotic_accept, emergency_support, services)
         VALUES (?, ?, ?, ?, ?, ?, 1, 4.5, '09:00-21:00', 0, 0, 0, '疫苗接种,常规体检,内外科')`,
        [app.hospital_name, app.address, app.phone, app.city || '上海', app.description || null, app.license_url || null]
      );
      hospitalId = hResult.insertId;
    } else {
      // 自动认证匹配的，补充营业执照
      await conn.query('UPDATE hospital SET license_url = ?, verified = 1 WHERE id = ?', [app.license_url, hospitalId]);
    }

    // 创建商家账号
    const [uResult] = await conn.query(
      'INSERT INTO user (username, password, phone, email, nickname, role, hospital_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [app.username, app.password, app.contact_phone || app.phone, null, app.hospital_name + '管理员', 'merchant', hospitalId]
    );

    // 更新申请状态
    await conn.query(
      'UPDATE merchant_application SET status = ?, hospital_id = ?, reviewer_id = ?, reviewed_at = NOW() WHERE id = ?',
      ['approved', hospitalId, req.user.id, req.params.id]
    );

    await conn.commit();
    conn.release();

    res.json({
      code: 200,
      message: '审核通过，商家账号已创建',
      data: { userId: uResult.insertId, hospitalId, username: app.username }
    });
  } catch (err) {
    try { await conn.rollback(); } catch (e) {}
    conn.release();
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// PUT /api/merchant/applications/:id/reject - 审核拒绝（管理员）
router.put('/applications/:id/reject', verifyToken, requireAdmin, async (req, res) => {
  try {
    const { reason } = req.body;
    const [exist] = await pool.query('SELECT id FROM merchant_application WHERE id = ? AND status = ?', [req.params.id, 'pending']);
    if (exist.length === 0) {
      return res.json({ code: 404, message: '申请不存在或已处理', data: null });
    }
    await pool.query(
      'UPDATE merchant_application SET status = ?, reject_reason = ?, reviewer_id = ?, reviewed_at = NOW() WHERE id = ?',
      ['rejected', reason || '资料不全', req.user.id, req.params.id]
    );
    res.json({ code: 200, message: '已拒绝申请', data: null });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// GET /api/merchant/stats - 管理员概览统计
router.get('/stats', verifyToken, requireAdmin, async (req, res) => {
  try {
    const [pending] = await pool.query("SELECT COUNT(*) AS count FROM merchant_application WHERE status = 'pending'");
    const [approved] = await pool.query("SELECT COUNT(*) AS count FROM merchant_application WHERE status = 'approved'");
    const [rejected] = await pool.query("SELECT COUNT(*) AS count FROM merchant_application WHERE status = 'rejected'");
    const [hospitals] = await pool.query('SELECT COUNT(*) AS count FROM hospital');
    const [merchants] = await pool.query("SELECT COUNT(*) AS count FROM user WHERE role = 'merchant'");
    res.json({
      code: 200, message: 'success',
      data: {
        pendingCount: pending[0].count,
        approvedCount: approved[0].count,
        rejectedCount: rejected[0].count,
        hospitalCount: hospitals[0].count,
        merchantCount: merchants[0].count
      }
    });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// ============================================
// 商家管理医生（自主添加医生）
// ============================================

// GET /api/merchant/doctors?hospitalId=xx - 商家查看本医院医生
router.get('/doctors', verifyToken, requireMerchant, async (req, res) => {
  try {
    const hospitalId = req.user.hospitalId;
    const [rows] = await pool.query('SELECT * FROM doctor WHERE hospital_id = ? ORDER BY created_at DESC', [hospitalId]);
    res.json({ code: 200, message: 'success', data: rows });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// POST /api/merchant/doctors - 商家添加医生
router.post('/doctors', verifyToken, requireMerchant, async (req, res) => {
  try {
    const { name, title, specialty, workHours, workDays, description, licenseUrl } = req.body;
    if (!name || !specialty) {
      return res.json({ code: 400, message: '医生姓名和专业领域不能为空', data: null });
    }
    const hospitalId = req.user.hospitalId;
    if (!hospitalId) {
      return res.json({ code: 403, message: '账号未关联医院', data: null });
    }
    const [result] = await pool.query(
      `INSERT INTO doctor (hospital_id, name, title, specialty, rating, work_hours, work_days, description, license_url)
       VALUES (?, ?, ?, ?, 4.5, ?, ?, ?, ?)`,
      [hospitalId, name, title || '主治医师', specialty, workHours || '09:00-18:00', workDays || '1,2,3,4,5', description || null, licenseUrl || null]
    );
    const [rows] = await pool.query('SELECT * FROM doctor WHERE id = ?', [result.insertId]);
    res.json({ code: 200, message: '医生添加成功', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// PUT /api/merchant/doctors/:id - 商家修改医生信息
router.put('/doctors/:id', verifyToken, requireMerchant, async (req, res) => {
  try {
    const { name, title, specialty, workHours, workDays, description, licenseUrl } = req.body;
    const hospitalId = req.user.hospitalId;
    const [exist] = await pool.query('SELECT id FROM doctor WHERE id = ? AND hospital_id = ?', [req.params.id, hospitalId]);
    if (exist.length === 0) {
      return res.json({ code: 404, message: '医生不存在或无权修改', data: null });
    }
    await pool.query(
      `UPDATE doctor SET name = ?, title = ?, specialty = ?, work_hours = ?, work_days = ?, description = ?, license_url = ? WHERE id = ?`,
      [name || null, title || null, specialty || null, workHours || null, workDays || null, description || null, licenseUrl || null, req.params.id]
    );
    const [rows] = await pool.query('SELECT * FROM doctor WHERE id = ?', [req.params.id]);
    res.json({ code: 200, message: '修改成功', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// DELETE /api/merchant/doctors/:id - 商家删除医生
router.delete('/doctors/:id', verifyToken, requireMerchant, async (req, res) => {
  try {
    const hospitalId = req.user.hospitalId;
    const [exist] = await pool.query('SELECT id FROM doctor WHERE id = ? AND hospital_id = ?', [req.params.id, hospitalId]);
    if (exist.length === 0) {
      return res.json({ code: 404, message: '医生不存在或无权删除', data: null });
    }
    await pool.query('DELETE FROM doctor WHERE id = ?', [req.params.id]);
    res.json({ code: 200, message: '删除成功', data: null });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// PUT /api/merchant/hospital - 商家修改本医院信息
router.put('/hospital', verifyToken, requireMerchant, async (req, res) => {
  try {
    const hospitalId = req.user.hospitalId;
    const {
      name, address, phone, description, businessHours, nightService, exoticAccept, emergencySupport, services, licenseUrl, logoUrl
    } = req.body;
    const [exist] = await pool.query('SELECT id FROM hospital WHERE id = ?', [hospitalId]);
    if (exist.length === 0) {
      return res.json({ code: 404, message: '医院不存在', data: null });
    }
    await pool.query(
      `UPDATE hospital SET name = ?, address = ?, phone = ?, description = ?, business_hours = ?, night_service = ?, exotic_accept = ?, emergency_support = ?, services = ?, license_url = ?, logo_url = ? WHERE id = ?`,
      [
        name || null, address || null, phone || null, description || null,
        businessHours || null,
        nightService ? 1 : 0, exoticAccept ? 1 : 0, emergencySupport ? 1 : 0,
        services || null, licenseUrl || null, logoUrl || null,
        hospitalId
      ]
    );
    const [rows] = await pool.query('SELECT * FROM hospital WHERE id = ?', [hospitalId]);
    res.json({ code: 200, message: '修改成功', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

module.exports = router;
