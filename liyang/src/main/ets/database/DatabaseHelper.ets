import { relationalStore } from '@kit.ArkData'
import { BusinessError } from '@kit.BasicServicesKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'DatabaseHelper'

// 数据库配置：启用云端协同，多设备数据自动同步
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'distributed_player.db',
  securityLevel: relationalStore.SecurityLevel.S1,
  cloudSwitch: true
}

// 云端同步表名列表（在建表后调用 setDistributedTables 注册）
// 这些表的数据会在同一华为账号的多设备间自动同步
const CLOUD_SYNC_TABLES: string[] = [
  'playlist',
  'playlist_song',
  'favorite',
  'play_history'
]

// 建表SQL：用户资料表（仅本地存储，不参与云同步以保护密码等敏感字段）
const SQL_CREATE_USER_PROFILE = `
  CREATE TABLE IF NOT EXISTS user_profile (
    user_id TEXT PRIMARY KEY,
    auth_type INTEGER NOT NULL DEFAULT 0,
    openid TEXT,
    email TEXT,
    password_hash TEXT,
    nickname TEXT,
    avatar_url TEXT,
    theme INTEGER DEFAULT 0,
    sync_time INTEGER DEFAULT 0
  )
`

/**
 * 云数据库初始化与管理助手
 * - 单例模式管理 RdbStore 实例
 * - 启用 cloudSwitch 实现云端协同
 * - 通过 setDistributedTables 控制参与同步的表
 * - 用户敏感信息（password_hash）所在表不参与云同步
 */
export class DatabaseHelper {
  // 全局唯一 RdbStore 实例
  private static store: relationalStore.RdbStore | null = null

  /** 获取当前 RdbStore 实例（可能为 null） */
  static getStore(): relationalStore.RdbStore | null {
    return DatabaseHelper.store
  }

  /**
   * 初始化云数据库
   * - 已初始化则直接返回已有实例
   * - 否则创建数据库，建表，并注册云端同步表
   * @param context 应用上下文
   * @returns 初始化完成的 RdbStore 实例
   */
  static async initDatabase(context: Context): Promise<relationalStore.RdbStore> {
    if (DatabaseHelper.store !== null) {
      return DatabaseHelper.store
    }
    try {
      // 创建或打开云端协同数据库
      const store = await relationalStore.getRdbStore(context, STORE_CONFIG)
      DatabaseHelper.store = store
      // 执行建表
      await DatabaseHelper.createTables(store)
      // 注册参与云端同步的表（仅非敏感数据表）
      await DatabaseHelper.enableCloudSync(store)
      hilog.info(DOMAIN, TAG, 'Cloud database initialized successfully.')
      return store
    } catch (err) {
      const error = err as BusinessError
      hilog.error(DOMAIN, TAG, 'Failed to initialize database. Code: %{public}d, message: %{public}s',
        error.code, error.message)
      throw new Error(`Database init failed: ${error.message}`)
    }
  }

  // 执行所有建表语句（当前仅 user_profile）
  private static async createTables(store: relationalStore.RdbStore): Promise<void> {
    try {
      await store.executeSql(SQL_CREATE_USER_PROFILE)
      hilog.info(DOMAIN, TAG, 'Table user_profile created successfully.')
    } catch (err) {
      const error = err as BusinessError
      hilog.error(DOMAIN, TAG, 'Failed to create table. Code: %{public}d, message: %{public}s',
        error.code, error.message)
      throw new Error(`Create table failed: ${error.message}`)
    }
  }

  /**
   * 注册云端同步表
   * - 仅标记业务数据表参与云端协同
   * - user_profile 不参与同步，避免密码哈希等敏感字段泄露
   */
  private static async enableCloudSync(store: relationalStore.RdbStore): Promise<void> {
    try {
      await store.setDistributedTables(CLOUD_SYNC_TABLES)
      hilog.info(DOMAIN, TAG, 'Cloud sync enabled for tables: %{public}s',
        CLOUD_SYNC_TABLES.join(', '))
    } catch (err) {
      const error = err as BusinessError
      hilog.warn(DOMAIN, TAG, 'Failed to enable cloud sync. Code: %{public}d, message: %{public}s',
        error.code, error.message)
      // 云同步启用失败不阻塞应用运行，降级为纯本地模式
    }
  }

  /** 关闭数据库连接并释放实例 */
  static close(): void {
    if (DatabaseHelper.store !== null) {
      DatabaseHelper.store.close()
      DatabaseHelper.store = null
      hilog.info(DOMAIN, TAG, 'Database closed.')
    }
  }
}
