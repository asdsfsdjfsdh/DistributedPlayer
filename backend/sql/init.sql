-- 鸿蒙悦音 - 分布式音乐播放器 数据库初始化脚本
-- 执行方式: mysql -u root -p < backend/sql/init.sql

CREATE DATABASE IF NOT EXISTS distributed_player
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE distributed_player;

-- 用户表
CREATE TABLE IF NOT EXISTS t_user (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    openid      VARCHAR(128)  COMMENT '华为账号OpenID',
    email       VARCHAR(255)  COMMENT '邮箱',
    password    VARCHAR(255)  COMMENT '密码哈希(BCrypt)',
    auth_type   TINYINT       COMMENT '0=华为 1=邮箱',
    nickname    VARCHAR(100)  COMMENT '昵称',
    avatar_url  VARCHAR(500)  COMMENT '头像URL',
    theme       TINYINT       DEFAULT 0 COMMENT '主题偏好',
    status      TINYINT       DEFAULT 0 COMMENT '0=正常 1=封禁',
    created_at  DATETIME      DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at  DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY uk_openid (openid),
    UNIQUE KEY uk_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 在线歌曲表
CREATE TABLE IF NOT EXISTS t_song (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    song_id     VARCHAR(128)  COMMENT '在线歌曲唯一ID',
    title       VARCHAR(255)  NOT NULL COMMENT '歌名',
    artist      VARCHAR(255)  COMMENT '歌手',
    album       VARCHAR(255)  COMMENT '专辑',
    duration    INT           COMMENT '时长（秒）',
    cover_url   VARCHAR(500)  COMMENT '封面URL',
    lyrics_url  VARCHAR(500)  COMMENT '歌词文件URL',
    play_url    VARCHAR(500)  COMMENT '播放地址',
    status      TINYINT       DEFAULT 0 COMMENT '0=正常 1=下架',
    created_at  DATETIME      DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UNIQUE KEY uk_song_id (song_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='在线歌曲表';

-- 歌单表
CREATE TABLE IF NOT EXISTS t_playlist (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    name        VARCHAR(100)  NOT NULL COMMENT '歌单名称',
    cover_url   VARCHAR(500)  COMMENT '封面图',
    description VARCHAR(500)  COMMENT '歌单简介',
    user_id     BIGINT        COMMENT '创建者 FK→t_user',
    status      TINYINT       DEFAULT 0 COMMENT '0=正常 1=下架',
    created_at  DATETIME      DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at  DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='歌单表';

-- 歌单歌曲关联表
CREATE TABLE IF NOT EXISTS t_playlist_song (
    playlist_id BIGINT        COMMENT 'FK→t_playlist',
    song_id     BIGINT        COMMENT 'FK→t_song',
    sort_order  INT           DEFAULT 0 COMMENT '排序序号',
    added_at    DATETIME      DEFAULT CURRENT_TIMESTAMP COMMENT '添加时间',
    PRIMARY KEY (playlist_id, song_id),
    INDEX idx_song_id (song_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='歌单歌曲关联表';

-- 收藏表
CREATE TABLE IF NOT EXISTS t_favorite (
    user_id     BIGINT        COMMENT 'FK→t_user',
    song_id     BIGINT        COMMENT 'FK→t_song',
    created_at  DATETIME      DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
    PRIMARY KEY (user_id, song_id),
    INDEX idx_song_id (song_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='收藏表';

-- 播放历史表
CREATE TABLE IF NOT EXISTS t_play_history (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id     BIGINT        COMMENT 'FK→t_user',
    song_id     BIGINT        COMMENT 'FK→t_song',
    progress    INT           DEFAULT 0 COMMENT '播放进度（秒）',
    played_at   DATETIME      DEFAULT CURRENT_TIMESTAMP COMMENT '播放时间',
    INDEX idx_user_id (user_id),
    INDEX idx_song_id (song_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='播放历史表';

-- 管理员表
CREATE TABLE IF NOT EXISTS t_admin (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    username    VARCHAR(50)   NOT NULL COMMENT '管理员账号',
    password    VARCHAR(255)  NOT NULL COMMENT '密码哈希(BCrypt)',
    created_at  DATETIME      DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    UNIQUE KEY uk_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员表';

-- 初始化默认管理员账号 (admin / admin123)
INSERT IGNORE INTO t_admin (username, password) VALUES
('admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi');
