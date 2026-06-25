const express = require('express');
const pool = require('../config/db');

const router = express.Router();

// GET /api/pets?userId=xx - 获取用户宠物列表
router.get('/', async (req, res) => {
  try {
    const { userId } = req.query;
    let sql = 'SELECT * FROM pet';
    let params = [];
    if (userId) {
      sql += ' WHERE user_id = ?';
      params.push(userId);
    }
    sql += ' ORDER BY created_at DESC';
    const [rows] = await pool.query(sql, params);
    res.json({ code: 200, message: 'success', data: rows });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// GET /api/pets/:id - 获取单个宠物
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM pet WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      return res.json({ code: 404, message: '宠物不存在', data: null });
    }
    res.json({ code: 200, message: 'success', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// POST /api/pets - 添加宠物
router.post('/', async (req, res) => {
  try {
    const { userId, name, species, breed, age, weight, gender, neutered, notes, avatar, isExotic } = req.body;
    if (!userId || !name || !species) {
      return res.json({ code: 400, message: '用户ID、宠物名、类型不能为空', data: null });
    }

    const [result] = await pool.query(
      `INSERT INTO pet (user_id, name, species, breed, age, weight, gender, neutered, notes, avatar, is_exotic)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId, name, species, breed || null,
        age || null, weight || null, gender || null,
        neutered === null || neutered === undefined ? null : (neutered ? 1 : 0),
        notes || null, avatar || null, isExotic ? 1 : 0
      ]
    );

    const [rows] = await pool.query('SELECT * FROM pet WHERE id = ?', [result.insertId]);
    res.json({ code: 200, message: '添加成功', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// PUT /api/pets - 修改宠物
router.put('/', async (req, res) => {
  try {
    const { id, userId, name, species, breed, age, weight, gender, neutered, notes, avatar, isExotic } = req.body;
    if (!id) {
      return res.json({ code: 400, message: '宠物ID不能为空', data: null });
    }

    const [exist] = await pool.query('SELECT id FROM pet WHERE id = ?', [id]);
    if (exist.length === 0) {
      return res.json({ code: 404, message: '宠物不存在', data: null });
    }

    await pool.query(
      `UPDATE pet SET name = ?, species = ?, breed = ?, age = ?, weight = ?, gender = ?, neutered = ?, notes = ?, avatar = ?, is_exotic = ? WHERE id = ?`,
      [
        name || null, species || null, breed || null,
        age || null, weight || null, gender || null,
        neutered === null || neutered === undefined ? null : (neutered ? 1 : 0),
        notes || null, avatar || null, isExotic ? 1 : 0,
        id
      ]
    );

    const [rows] = await pool.query('SELECT * FROM pet WHERE id = ?', [id]);
    res.json({ code: 200, message: '修改成功', data: rows[0] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

// DELETE /api/pets/:id?userId=xx - 删除宠物
router.delete('/:id', async (req, res) => {
  try {
    const { userId } = req.query;
    const [exist] = await pool.query('SELECT id FROM pet WHERE id = ?', [req.params.id]);
    if (exist.length === 0) {
      return res.json({ code: 404, message: '宠物不存在', data: null });
    }

    if (userId) {
      const [owner] = await pool.query('SELECT id FROM pet WHERE id = ? AND user_id = ?', [req.params.id, userId]);
      if (owner.length === 0) {
        return res.json({ code: 403, message: '无权删除该宠物', data: null });
      }
    }

    await pool.query('DELETE FROM pet WHERE id = ?', [req.params.id]);
    res.json({ code: 200, message: '删除成功', data: null });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message, data: null });
  }
});

module.exports = router;
