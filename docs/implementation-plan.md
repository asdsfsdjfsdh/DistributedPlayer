# 鸿蒙悦音 - 分布式音乐播放器 实现计划

## 项目背景
打造基于鸿蒙系统的一站式音乐播放应用，覆盖本地音乐扫描管理、在线歌单推荐、歌词同步展示、后台播放控制等核心能力，依托鸿蒙分布式能力实现多设备无缝音乐流转，为用户提供全场景、沉浸式的音乐收听体验。

- **Bundle**: `com.example.distributedplayer`
- **目标SDK**: 26
- **语言**: ArkTS
- **构建工具**: DevEco Studio + Hvigor

---

## 技术要点

| 技术点 | 关键API | 说明 |
|---|---|---|
| 本地音乐扫描 | `@ohos.file.fs` + mediaLibrary | 扫描本地音频文件，按歌手/专辑分类 |
| 在线歌单 | `@ohos.net.http` | 请求公开音乐API获取歌单/歌曲/歌词 |
| 音频播放 | `@ohos.multimedia.media` AVPlayer | 后台播放、倍速播放、进度控制、播放列表 |
| 分布式流转 | `@ohos.distributedHardware.deviceManager` + continuationManager | 跨设备无缝音乐流转 |
| 服务卡片 | `FormExtensionAbility` + `@bundle` widget | 桌面快捷播放控制卡片 |
| 页面导航 | `Navigation` + `NavPathStack` | 首页/歌单详情/播放页/收藏页导航 |
| 列表优化 | `LazyForEach` + `IDataSource` | 虚拟渲染歌曲列表，关键词搜索 |
| 云数据库 | `@ohos.data.relationalStore` + cloudSwitch | 歌单/收藏/历史多端自动同步 |
| 华为账号登录 | `@ohos.account.appAccount` Account Kit | 静默登录 / 授权弹窗 |
| 邮箱认证 | 本地密码哈希 + Token | 邮箱注册 / 登录 |

---

## 目录结构

```
liyang/src/main/ets/
  ├── model/           # 数据模型
  │   ├── Song.ets
  │   ├── Playlist.ets
  │   ├── Lyric.ets
  │   └── UserProfile.ets
  ├── database/        # 数据库层
  │   └── DatabaseHelper.ets
  ├── service/         # 服务层
  │   ├── AudioService.ets        # AVPlayer 封装
  │   ├── FileScanService.ets     # 本地音频扫描
  │   ├── NetworkService.ets      # 在线API请求
  │   ├── DatabaseService.ets     # 数据库CRUD
  │   ├── AuthService.ets         # 认证服务（华为+邮箱）
  │   └── DistributedService.ets  # 分布式流转
  ├── viewmodel/       # 视图模型
  │   ├── MusicViewModel.ets
  │   └── PlayerViewModel.ets
  ├── components/      # 可复用UI组件
  │   ├── MusicItem.ets
  │   ├── PlayControlBar.ets
  │   ├── LyricsView.ets
  │   ├── SearchBar.ets
  │   └── LoginDialog.ets         # 华为登录授权弹窗
  ├── pages/           # 页面
  │   ├── Index.ets               # 音乐首页
  │   ├── PlaylistPage.ets        # 歌单详情
  │   ├── PlayerPage.ets          # 播放页（歌词+控制）
  │   ├── FavoritesPage.ets       # 我的收藏
  │   ├── SearchPage.ets          # 搜索页
  │   ├── LocalMusicPage.ets      # 本地音乐
  │   ├── UserProfilePage.ets     # 个人中心（设置/主题/账号管理）
  │   ├── LoginPage.ets           # 邮箱登录
  │   └── RegisterPage.ets        # 邮箱注册
  ├── widget/          # 服务卡片
  │   └── MusicCard.ets
  ├── liyangability/   # UIAbility 入口
  └── liyangbackupability/
```

---

## 用户认证方案

### 登录方式

| 方式 | 页面/组件 | 说明 |
|---|---|---|
| 华为账号登录 | `LoginDialog.ets` 组件弹窗 | 静默优先，失败时弹出授权 |
| 邮箱登录 | `LoginPage.ets` 独立页面 | 邮箱 + 密码 |
| 邮箱注册 | `RegisterPage.ets` 独立页面 | 邮箱 + 密码 + 昵称 |
| 账号关联 | `UserProfilePage.ets` 内处理 | 已登录后可绑定另一种方式 |

### 认证流程

```
应用启动
  ├── 检查本地是否有已登录的 user_id
  │     ├── 华为账号：静默获取 openid → 匹配到 user → 自动登录
  │     ├── 邮箱：token 有效 → 自动登录
  │     ├── 邮箱：token 过期 → 跳转 LoginPage
  │     └── 无记录 → 进入游客模式（可浏览，不可收藏/评论）
  └── 用户手动操作
        ├── 点击"华为登录" → LoginDialog 弹窗
        ├── 点击"邮箱登录" → pushUrl LoginPage
        └── 点击"注册" → pushUrl RegisterPage
```

---

## 数据库设计

### 概述
- 本地数据库: RelationalStore（6张表）
- 用户唯一标识: `user_id`（本地UUID），所有业务表关联此字段
- 云数据库以 `user_id` 为分区键实现多端同步

### user_profile
| 字段 | 类型 | 说明 |
|---|---|---|
| user_id (PK) | TEXT | 本地生成UUID，统一标识 |
| auth_type | INTEGER | 0=华为账号 1=邮箱 |
| openid | TEXT | 华为OpenID（auth_type=0时有效） |
| email | TEXT | 邮箱地址（auth_type=1时有效） |
| password_hash | TEXT | 密码哈希（auth_type=1时有效） |
| nickname | TEXT | 用户昵称 |
| avatar_url | TEXT | 头像地址 |
| theme | INTEGER | 0=默认 1=深色 |
| sync_time | INTEGER | 最后同步时间戳 |

### playlist
| 字段 | 类型 | 说明 |
|---|---|---|
| id (PK) | INTEGER | 自增主键 |
| name | TEXT | 歌单名称 |
| cover_url | TEXT | 封面图 |
| is_local | INTEGER | 0=在线 1=本地创建 |
| owner_user_id | TEXT | FK → user_profile.user_id |
| create_time | INTEGER | 创建时间戳 |
| update_time | INTEGER | 更新时间戳 |

### song
| 字段 | 类型 | 说明 |
|---|---|---|
| id (PK) | TEXT | song_id (本地路径/在线ID) |
| title | TEXT | 歌曲名 |
| artist | TEXT | 歌手 |
| album | TEXT | 专辑 |
| duration | INTEGER | 时长(ms) |
| file_path | TEXT | 本地文件路径(可为空) |
| cover_url | TEXT | 封面图 |
| lyrics_url | TEXT | 歌词地址 |
| source | INTEGER | 0=本地 1=在线 |

### playlist_song（多对多关联）
| 字段 | 类型 | 说明 |
|---|---|---|
| playlist_id | INTEGER | FK → playlist |
| song_id | TEXT | FK → song |
| sort_order | INTEGER | 排序序号 |
| add_time | INTEGER | 添加时间 |
| PK: (playlist_id, song_id) |

### favorite
| 字段 | 类型 | 说明 |
|---|---|---|
| user_id | TEXT | FK → user_profile.user_id |
| song_id | TEXT | FK → song |
| favorite_time | INTEGER | 收藏时间 |
| PK: (user_id, song_id) |

### play_history
| 字段 | 类型 | 说明 |
|---|---|---|
| id (PK) | INTEGER | 自增 |
| user_id | TEXT | FK → user_profile.user_id |
| song_id | TEXT | FK → song |
| play_time | INTEGER | 播放时间戳 |
| progress | INTEGER | 播放进度(ms) |

### 云数据库同步策略
- 以 **user_id 为分区键** 实现用户数据隔离
- 同步表：playlist, playlist_song, favorite, play_history
- 不同步：user_profile 密码字段、song 表中 source=0 的本地记录
- 离线变更在设备联网后自动合并

---

## 实现阶段

### 第一阶段：基础架构
- [ ] 数据模型定义（Song, Playlist, Lyric）
- [x] 数据模型定义（UserProfile）
- [x] 数据库初始化（DatabaseHelper — 建表 + cloudSwitch + setDistributedTables 云端协同）
- [ ] 认证服务（AuthService — 华为静默登录 + 邮箱注册/登录 + 游客模式）
- [ ] 页面导航框架（Navigation + NavPathStack + 所有页面占位骨架）
- [ ] LoginPage / RegisterPage / LoginDialog 组件
- [ ] 修改 module.json5（权限/路由/服务卡片配置）

### 第二阶段：核心功能 P0（MVP）
- [ ] 本地音乐扫描服务（FileScanService）
- [ ] AVPlayer 播放控制（AudioService — 播放/暂停/切歌/进度）
- [ ] 播放页 UI（封面图/进度条/歌词同步展示）
- [ ] 首页音乐列表（LazyForEach + 本地数据源）

### 第三阶段：在线功能 P1
- [ ] 在线歌单请求（NetworkService + 公开音乐API）
- [ ] 收藏管理（本地 + 云端双向同步）
- [ ] 歌单创建/编辑
- [ ] 搜索功能（本地过滤 + 在线搜索）
- [ ] 播放历史记录
- [ ] UserProfilePage 个人中心

### 第四阶段：鸿蒙特色 P2
- [ ] 分布式流转（设备发现 + continuationManager 接力播放）
- [ ] 服务卡片（FormExtensionAbility 桌面快捷控制）
- [ ] 后台播放（AVSession / 通知栏常驻控制）
- [ ] 倍速播放控制

---

## 交付成果
- 分布式音乐播放器完整代码
- 本地音乐扫描、在线歌单、歌词同步播放全功能
- 鸿蒙分布式音乐跨设备流转效果展示
- 服务卡片快捷播放控制效果
- 多设备适配与后台播放功能
- 自定义歌单与收藏管理功能
- 播放历史记录与歌词同步展示
- 华为账号 + 邮箱双认证用户管理
