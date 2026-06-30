# AGENTS.md

## Project overview
本项目是前后端分离架构：

**前端：鸿蒙 App** (`liyang/`)
- HarmonyOS (OpenHarmony) application, bundle `com.example.distributedplayer`, target SDK 26.
- Language: **ArkTS** (`.ets` files) — TypeScript-like but HarmonyOS-specific; do not treat as standard TypeScript.
- Config files use **JSON5** format (supports comments, trailing commas).

**后端：Spring Boot 服务** (`backend/`)
- Java 17 + Spring Boot 3.x + MyBatis-Plus + MySQL 8.0
- Security: Spring Security + JWT
- 后台管理页面: Thymeleaf + Bootstrap 5
- API文档: Knife4j (Swagger)

## Build & dev commands

### 鸿蒙 App
- `hvigorw assembleHap` — build debug HAP
- `hvigorw assembleHap -p buildMode=release` — build release HAP
- Do **not** run `npm install`, `npm test`, `npm run build`, `gradle`, or `cmake` here.

### 后端
- `mvn clean compile` — 编译
- `mvn spring-boot:run` — 启动后端（开发模式，需先启动MySQL）
- `mvn test` — 运行单元测试
- `mvn package -DskipTests` — 打包 JAR

## Module structure

### 前端 `liyang/`
- Source: `liyang/src/main/ets/`
  - `liyangability/LiyangAbility.ets` — main UIAbility entry
  - `liyangbackupability/LiyangBackupAbility.ets` — backup extension
  - `pages/Index.ets` — main page (`@Entry @Component struct Index`)
- Resources: `liyang/src/main/resources/` (strings, media, profiles).
- App-level config: `AppScope/app.json5`, module config: `liyang/src/main/module.json5`.

### 后端 `backend/`
- Source: `backend/src/main/java/com/distributedplayer/`
  - `controller/api/` — REST API 控制器（供鸿蒙App调用）
  - `controller/admin/` — 后台管理页面控制器
  - `service/` — 业务逻辑层
  - `repository/` — MyBatis-Plus Mapper
  - `model/entity/` — 数据库实体
  - `model/dto/` — 请求/响应传输对象
  - `security/` — Spring Security + JWT
- Resources: `backend/src/main/resources/`
  - `application.yml` — 主配置
  - `db/migration/` — Flyway 数据库迁移
  - `templates/admin/` — Thymeleaf 后台页面

## Testing

### 鸿蒙 App
- **Local unit tests**: `liyang/src/test/` — uses `@ohos/hypium` (`describe`/`it`/`expect`). No device needed.
- **Device integration tests**: `liyang/src/ohosTest/` — runs on device/emulator.
- **Mock config**: `liyang/src/mock/mock-config.json5` (uses `@ohos/hamock`).
- Tests are registered via `List.test.ets` files that import and call individual test suites.

### 后端
- **JUnit 5 + Mockito**: `backend/src/test/` — 单元测试与集成测试
- **接口测试**: 启动后通过 Knife4j 页面 `http://localhost:8080/doc.html` 手动调试

## Linting
- **鸿蒙 App**: Config `code-linter.json5` — lints `**/*.ets`, uses `@performance/recommended` + `@typescript-eslint/recommended`.
  - Ignores `ohosTest/`, `test/`, `mock/`, `build/`, `oh_modules/`, `.preview/`.
- **后端**: 遵循标准 Java 代码规范（阿里巴巴 Java 开发手册）

## 项目长期规划
CRITICAL: 在开始任何新 session 或实现功能前，先读取项目实现计划：
- @docs/implementation-plan.md — 鸿蒙 App 实现计划
- @docs/backend-plan.md — 后端服务实现计划

两个计划分别包含各自的技术架构、数据库设计、目录结构和分阶段实现计划。
按照计划中的阶段顺序逐步实现，每个阶段完成后再进入下一阶段。

CRITICAL: 每个阶段功能实现完成后，必须及时更新对应的计划文件，
将该阶段中已完成的项标记为 [x]。如果实现过程中发现计划需要调整（如新增/删除/修改功能点），
必须同步更新计划文件，确保计划始终反映项目真实状态。

CRITICAL: docs/implementation-plan.md、docs/backend-plan.md、opencode.json、AGENTS.md 四个文件必须
纳入 git 版本管理，保证团队协作时计划同步。

## 代码规范

### Model 设计规范（鸿蒙 App）
所有数据模型必须遵循以下四层结构：

1. **接口（Interface）** — 定义对外公开的只读数据契约，命名以 `Data` 后缀结尾
2. **私有字段（Private Fields）** — 所有属性使用 `private` 字段存储，通过 `get`/`set` 访问器暴露
3. **工厂方法（Factory）** — `static create(data: Partial<T>): Model` 构造新实例
4. **序列化（Serialization）** — 必须实现以下方法：
   - `toObject(): T` — 序列化为纯数据对象
   - `fromResultSet(row): Model` — 从数据库结果集反序列化（静态方法）
   - `toValuesBucket(): Record<string, Object>` — 序列化为数据库写入格式

```typescript
// 1. 接口
export interface SongData {
  readonly id: string
  readonly title: string
}

// 2. 类 = 私有字段 + get/set
export class Song implements SongData {
  private _id: string = ''
  get id(): string { return this._id }
  set id(value: string) { this._id = value }

  // 3. 工厂方法
  static create(data: Partial<SongData>): Song { ... }

  // 4. 序列化
  toObject(): SongData { ... }
  static fromResultSet(row: Record<string, Object>): Song { ... }
  toValuesBucket(): Record<string, Object> { ... }
}
```

### 注释规范
CRITICAL: 编写代码时必须及时添加注释，注释应使用中文。
- 类、接口、枚举：必须有顶部注释说明用途
- 公共方法：必须有注释说明参数和返回值
- 复杂逻辑：关键步骤必须添加行内注释
- 私有字段：重要字段须注释其含义

### 数据库架构规范
CRITICAL: 本项目采用前后端分离的数据架构：

**后端 MySQL**（用户主数据、在线歌曲、歌单/收藏/历史主数据）
- 数据库名: `distributed_player`
- 建表脚本: `backend/src/main/resources/db/migration/V1__init.sql`
- 管理员账号: `backend/sql/init.sql` 手动执行

**鸿蒙 App 本地 DB**（RelationalStore + cloudSwitch，仅存离线缓存与本地歌曲）
- **建库必须启用 cloudSwitch**: `StoreConfig.cloudSwitch = true`
- **建库后必须调用 setDistributedTables()**: 注册业务数据表参与云同步
- **云同步失败不阻塞应用**: 降级为纯本地模式继续运行
- **同步表清单**: `playlist`, `playlist_song`, `favorite`, `play_history`
- **纯本地表**: 本地歌曲元数据 `song`（source=0）
- **不在本地存储**: `user_profile`（用户身份由后端 JWT 鉴定，所有用户操作走后端 API）
- 新增表时须评估是否需要加入 `CLOUD_SYNC_TABLES`

## Git 提交规范
CRITICAL: 所有 git commit message 必须使用中文，遵循以下模板：

```
<类型>: <简短描述>

<详细说明（可选）>
```

类型（type）必须使用以下之一：
- `feat` — 新功能
- `fix` — 修复bug
- `docs` — 文档更新
- `style` — 代码格式调整（不影响功能）
- `refactor` — 代码重构
- `test` — 测试相关
- `chore` — 构建/工具/依赖等杂项

示例：
```
feat: 新增本地音乐扫描服务
```
```
fix: 修复播放页进度条拖动卡顿问题

进度条在拖动时频繁触发onChange回调导致UI阻塞，
改为使用onChangeEnd只在拖动结束时更新进度。
```
```
docs: 更新实现计划，标记第一阶段已完成
```
