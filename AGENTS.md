# AGENTS.md

## Project overview
- HarmonyOS (OpenHarmony) application, bundle `com.example.distributedplayer`, target SDK 26.
- Built with **DevEco Studio** and **Hvigor** (not npm, not Gradle).
- Language: **ArkTS** (`.ets` files) — TypeScript-like but HarmonyOS-specific; do not treat as standard TypeScript.
- Config files use **JSON5** format (supports comments, trailing commas).

## Build & dev commands
There is no `package.json` scripts section. All commands run through DevEco Studio or `hvigorw`:
- `hvigorw assembleHap` — build debug HAP
- `hvigorw assembleHap -p buildMode=release` — build release HAP
- Do **not** run `npm install`, `npm test`, `npm run build`, `gradle`, or `cmake` here.

## Module structure
- Single module: **`liyang`** (`entry` type, stage mode).
- Source: `liyang/src/main/ets/`
  - `liyangability/LiyangAbility.ets` — main UIAbility entry
  - `liyangbackupability/LiyangBackupAbility.ets` — backup extension
  - `pages/Index.ets` — main page (`@Entry @Component struct Index`)
- Resources: `liyang/src/main/resources/` (strings, media, profiles).
- App-level config: `AppScope/app.json5`, module config: `liyang/src/main/module.json5`.

## Testing
- **Local unit tests**: `liyang/src/test/` — uses `@ohos/hypium` (`describe`/`it`/`expect`). No device needed.
- **Device integration tests**: `liyang/src/ohosTest/` — runs on device/emulator.
- **Mock config**: `liyang/src/mock/mock-config.json5` (uses `@ohos/hamock`).
- Tests are registered via `List.test.ets` files that import and call individual test suites.

## Linting
- Config: `code-linter.json5` — lints `**/*.ets`, uses `@performance/recommended` + `@typescript-eslint/recommended`.
- Ignores `ohosTest/`, `test/`, `mock/`, `build/`, `oh_modules/`, `.preview/`.

## 项目长期规划
CRITICAL: 在开始任何新 session 或实现功能前，先读取项目实现计划：
@docs/implementation-plan.md
该文件包含完整的项目目标、技术架构、数据库设计、目录结构和分阶段实现计划。
按照计划中的阶段顺序逐步实现，每个阶段完成后再进入下一阶段。

CRITICAL: 每个阶段功能实现完成后，必须及时更新 docs/implementation-plan.md，
将该阶段中已完成的项标记为 [x]。如果实现过程中发现计划需要调整（如新增/删除/修改功能点），
必须同步更新计划文件，确保计划始终反映项目真实状态。

CRITICAL: docs/implementation-plan.md、opencode.json、AGENTS.md 三个文件必须
纳入 git 版本管理，保证团队协作时计划同步。

## 代码规范

### Model 设计规范
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
