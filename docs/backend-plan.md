# 鸿蒙悦音 - 后端服务 实现计划

## 项目概述
为鸿蒙悦音音乐播放器提供后端 API 服务与后台管理界面。负责用户认证、在线歌曲管理、歌单/收藏/播放历史的数据持久化与同步。

- **技术栈**: Java 17 + Spring Boot 3.x + MyBatis-Plus + MySQL 8.0
- **安全**: Spring Security + JWT
- **后台页面**: Thymeleaf + Bootstrap 5
- **API文档**: Knife4j (Swagger)
- **构建工具**: Maven

---

## 整体架构

```
┌─────────────────────────────────────────────┐
│           HarmonyOS App (liyang)             │
│  本地DB: 离线缓存 + 本地歌曲 + cloudSwitch    │
│  NetworkService → HTTP REST API 调用         │
└──────────────────┬──────────────────────────┘
                   │ HTTPS + JWT
┌──────────────────▼──────────────────────────┐
│           Backend (Spring Boot)              │
│  ┌─────────┐ ┌──────────┐ ┌──────────────┐ │
│  │ api/    │ │ admin/   │ │  Service     │ │
│  │ REST    │ │ 管理页面  │ │  业务逻辑     │ │
│  └────┬────┘ └──┬───────┘ └──────┬───────┘ │
│       └─────────┴────────────────┘          │
└────────────────────┬────────────────────────┘
                     │
┌────────────────────▼────────────────────────┐
│              MySQL 8.0                      │
│  t_user | t_song | t_playlist |            │
│  t_playlist_song | t_favorite |            │
│  t_play_history | t_admin                   │
└─────────────────────────────────────────────┘
```

---

## 目录结构

```
backend/
├── pom.xml
├── src/
│   ├── main/java/com/distributedplayer/
│   │   ├── DistributedPlayerApplication.java   # Spring Boot 启动入口
│   │   ├── config/                             # 配置类
│   │   │   ├── SecurityConfig.java             # Spring Security + JWT 过滤器
│   │   │   ├── CorsConfig.java                 # CORS 跨域配置
│   │   │   └── SwaggerConfig.java              # Knife4j API 文档
│   │   ├── controller/                         # 控制器层
│   │   │   ├── api/                            # REST API（供鸿蒙App调用）
│   │   │   │   ├── AuthController.java         # 注册/登录/华为授权
│   │   │   │   ├── UserController.java         # 用户资料
│   │   │   │   ├── SongController.java         # 在线歌曲
│   │   │   │   ├── PlaylistController.java     # 歌单CRUD
│   │   │   │   ├── FavoriteController.java     # 收藏
│   │   │   │   └── HistoryController.java      # 播放历史
│   │   │   └── admin/                          # 后台管理页面路由
│   │   │       ├── AdminIndexController.java   # 仪表盘
│   │   │       ├── AdminUserController.java    # 用户管理
│   │   │       ├── AdminSongController.java    # 歌曲管理
│   │   │       └── AdminPlaylistController.java # 歌单管理
│   │   ├── model/                              # 数据模型
│   │   │   ├── entity/                         # 数据库实体
│   │   │   │   ├── User.java
│   │   │   │   ├── Song.java
│   │   │   │   ├── Playlist.java
│   │   │   │   ├── PlaylistSong.java
│   │   │   │   ├── Favorite.java
│   │   │   │   ├── PlayHistory.java
│   │   │   │   └── Admin.java
│   │   │   ├── dto/                            # 请求/响应传输对象
│   │   │   │   ├── LoginRequest.java
│   │   │   │   ├── RegisterRequest.java
│   │   │   │   └── ...
│   │   │   └── vo/                             # 视图对象
│   │   │       └── ...
│   │   ├── service/                            # 业务逻辑层
│   │   │   ├── UserService.java
│   │   │   ├── SongService.java
│   │   │   ├── PlaylistService.java
│   │   │   ├── FavoriteService.java
│   │   │   └── HistoryService.java
│   │   ├── repository/                         # 数据访问层（MyBatis-Plus Mapper）
│   │   │   ├── UserMapper.java
│   │   │   ├── SongMapper.java
│   │   │   ├── PlaylistMapper.java
│   │   │   ├── PlaylistSongMapper.java
│   │   │   ├── FavoriteMapper.java
│   │   │   ├── PlayHistoryMapper.java
│   │   │   └── AdminMapper.java
│   │   ├── security/                           # 安全模块
│   │   │   ├── JwtTokenProvider.java           # JWT 生成与验证
│   │   │   ├── JwtAuthenticationFilter.java    # 请求拦截器
│   │   │   └── UserDetailsServiceImpl.java     # 用户信息加载
│   │   ├── common/                             # 通用模块
│   │   │   ├── Result.java                     # 统一响应封装
│   │   │   ├── ResultCode.java                 # 响应状态码枚举
│   │   │   └── GlobalExceptionHandler.java     # 全局异常处理
│   │   └── util/                               # 工具类
│   │       └── PasswordEncoderUtil.java        # BCrypt 密码编码
│   └── main/resources/
│       ├── application.yml                     # 主配置
│       ├── application-dev.yml                 # 开发环境配置
│       ├── application-prod.yml                # 生产环境配置
│       ├── db/migration/                       # Flyway 数据库迁移
│       │   └── V1__init.sql                    # 初始建表脚本
│       ├── templates/                          # Thymeleaf 后台页面模板
│       │   ├── admin/
│       │   │   ├── login.html                  # 管理员登录页
│       │   │   ├── index.html                  # 仪表盘
│       │   │   ├── users.html                  # 用户管理
│       │   │   ├── songs.html                  # 歌曲管理
│       │   │   └── playlists.html              # 歌单管理
│       │   └── fragments/
│       │       ├── header.html                 # 公共头部
│       │       └── sidebar.html                # 侧边导航栏
│       └── static/
│           ├── css/admin.css                   # 后台样式
│           └── js/admin.js                     # 后台交互
└── sql/
    └── init.sql                                # 手动初始化SQL（含管理员账号）
```

---

## REST API 设计

### 认证模块 `/api/auth`

| 方法 | 路径 | 说明 |
|---|---|---|
| POST | `/api/auth/register` | 邮箱注册 |
| POST | `/api/auth/login` | 邮箱登录，返回JWT |
| POST | `/api/auth/huawei` | 华为账号授权登录 |

### 用户模块 `/api/user`

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/user/profile` | 获取当前用户资料 |
| PUT | `/api/user/profile` | 更新用户资料 |

### 歌曲模块 `/api/songs`

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/songs` | 歌曲列表（分页/搜索） |
| GET | `/api/songs/{id}` | 歌曲详情 |
| GET | `/api/songs/{id}/lyrics` | 歌词内容 |

### 歌单模块 `/api/playlists`

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/playlists` | 歌单列表 |
| GET | `/api/playlists/{id}` | 歌单详情（含歌曲） |
| POST | `/api/playlists` | 创建歌单 |
| PUT | `/api/playlists/{id}` | 编辑歌单 |
| DELETE | `/api/playlists/{id}` | 删除歌单 |
| POST | `/api/playlists/{id}/songs` | 向歌单添加歌曲 |
| DELETE | `/api/playlists/{id}/songs/{songId}` | 从歌单移除歌曲 |

### 收藏模块 `/api/favorites`

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/favorites` | 收藏列表 |
| POST | `/api/favorites` | 添加收藏 |
| DELETE | `/api/favorites/{songId}` | 取消收藏 |

### 播放历史 `/api/history`

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/api/history` | 播放历史列表 |
| POST | `/api/history` | 记录播放 |

### 统一响应格式

```json
{
  "code": 200,
  "message": "success",
  "data": {}
}
```

---

## MySQL 数据库设计

### t_user — 用户表
| 字段 | 类型 | 说明 |
|---|---|---|
| id (PK) | BIGINT | 自增主键 |
| openid | VARCHAR(128) | 华为账号OpenID，unique |
| email | VARCHAR(255) | 邮箱，unique |
| password | VARCHAR(255) | 密码哈希 (BCrypt) |
| auth_type | TINYINT | 0=华为 1=邮箱 |
| nickname | VARCHAR(100) | 昵称 |
| avatar_url | VARCHAR(500) | 头像URL |
| theme | TINYINT | 主题偏好 0=默认 1=深色 |
| status | TINYINT | 0=正常 1=封禁 |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |

### t_song — 在线歌曲表
| 字段 | 类型 | 说明 |
|---|---|---|
| id (PK) | BIGINT | 自增主键 |
| song_id | VARCHAR(128) | 在线歌曲唯一ID，unique |
| title | VARCHAR(255) | 歌名 |
| artist | VARCHAR(255) | 歌手 |
| album | VARCHAR(255) | 专辑 |
| duration | INT | 时长（秒） |
| cover_url | VARCHAR(500) | 封面URL |
| lyrics_url | VARCHAR(500) | 歌词文件URL |
| play_url | VARCHAR(500) | 播放地址 |
| status | TINYINT | 0=正常 1=下架 |
| created_at | DATETIME | 创建时间 |

### t_playlist — 歌单表
| 字段 | 类型 | 说明 |
|---|---|---|
| id (PK) | BIGINT | 自增主键 |
| name | VARCHAR(100) | 歌单名称 |
| cover_url | VARCHAR(500) | 封面图 |
| description | VARCHAR(500) | 歌单简介 |
| user_id | BIGINT | 创建者 FK→t_user |
| status | TINYINT | 0=正常 1=下架 |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |

### t_playlist_song — 歌单歌曲关联表
| 字段 | 类型 | 说明 |
|---|---|---|
| playlist_id (PK) | BIGINT | FK→t_playlist |
| song_id (PK) | BIGINT | FK→t_song |
| sort_order | INT | 排序序号 |
| added_at | DATETIME | 添加时间 |

### t_favorite — 收藏表
| 字段 | 类型 | 说明 |
|---|---|---|
| user_id (PK) | BIGINT | FK→t_user |
| song_id (PK) | BIGINT | FK→t_song |
| created_at | DATETIME | 收藏时间 |

### t_play_history — 播放历史表
| 字段 | 类型 | 说明 |
|---|---|---|
| id (PK) | BIGINT | 自增主键 |
| user_id | BIGINT | FK→t_user |
| song_id | BIGINT | FK→t_song |
| progress | INT | 播放进度（秒） |
| played_at | DATETIME | 播放时间 |

### t_admin — 管理员表
| 字段 | 类型 | 说明 |
|---|---|---|
| id (PK) | BIGINT | 自增主键 |
| username | VARCHAR(50) | 管理员账号，unique |
| password | VARCHAR(255) | 密码哈希 (BCrypt) |
| created_at | DATETIME | 创建时间 |

---

## 后台管理页面

| 页面 | 路径 | 说明 |
|---|---|---|
| 管理员登录 | `/admin/login` | 独立管理员登录页 |
| 仪表盘 | `/admin/index` | 用户/歌曲/歌单统计、今日活跃 |
| 用户管理 | `/admin/users` | 用户列表、封禁/解封、查看详情 |
| 歌曲管理 | `/admin/songs` | 歌曲列表、添加/编辑/删除、歌词管理 |
| 歌单管理 | `/admin/playlists` | 歌单列表、审核/下架 |

---

## 与鸿蒙 App 的数据职责划分

| 存储位置 | 职责 |
|---|---|
| **后端 MySQL** | 用户主数据、密码、在线歌曲元数据、歌单/收藏/历史主数据 |
| **HarmonyOS 本地 DB** | 本地扫描歌曲（source=0）、云端数据的离线缓存副本、用户偏好设置 |
| **HarmonyOS cloudSwitch** | playlist / favorite / history 离线副本的多设备同步 |

> App 端不再在本地存储 `user_profile`。用户身份由后端 JWT 鉴定，所有用户操作走后端 API。

---

## 实现阶段

### 第一阶段：基础骨架
- [ ] Maven 项目初始化（pom.xml + 目录结构）
- [ ] application.yml 配置（MySQL / 端口 / JWT密钥 / CORS）
- [ ] 数据库建表脚本（V1__init.sql / init.sql）
- [ ] 实体类定义（entity 包）
- [ ] MyBatis-Plus Mapper 接口
- [ ] Spring Security + JWT 基础配置
- [ ] 统一响应封装（Result / GlobalExceptionHandler）

### 第二阶段：认证与用户
- [ ] AuthController（注册 / 邮箱登录 / 华为授权）
- [ ] UserService（用户注册、密码验证、JWT签发）
- [ ] JwtTokenProvider + JwtAuthenticationFilter
- [ ] UserController（获取/更新资料）

### 第三阶段：核心业务 API
- [ ] SongController（歌曲CRUD、搜索、歌词）
- [ ] PlaylistController（歌单CRUD、添加/移除歌曲）
- [ ] FavoriteController（收藏/取消收藏）
- [ ] HistoryController（播放历史记录/查询）

### 第四阶段：后台管理页面
- [ ] 管理员登录页 + 认证
- [ ] 仪表盘页面
- [ ] 用户管理页面
- [ ] 歌曲管理页面
- [ ] 歌单管理页面

### 第五阶段：联调与优化
- [ ] 与鸿蒙 App API 联调
- [ ] 分页查询优化
- [ ] 异常边界处理
- [ ] API 文档完善
