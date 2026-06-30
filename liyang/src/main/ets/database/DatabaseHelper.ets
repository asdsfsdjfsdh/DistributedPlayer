import { relationalStore } from '@kit.ArkData'
import { BusinessError } from '@kit.BasicServicesKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'DatabaseHelper'

// 数据库配置：存储名称与安全级别
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'distributed_player.db',
  securityLevel: relationalStore.SecurityLevel.S1
}

// 建表SQL：用户资料表
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
 * 数据库初始化与管理助手
 * - 单例模式管理 RdbStore 实例
 * - 负责建库与建表
 */
export class DatabaseHelper {
  // 全局唯一 RdbStore 实例
  private static store: relationalStore.RdbStore | null = null

  /** 获取当前 RdbStore 实例（可能为 null） */
  static getStore(): relationalStore.RdbStore | null {
    return DatabaseHelper.store
  }

  /**
   * 初始化数据库
   * - 如果已初始化则直接返回已有实例
   * - 否则创建数据库并执行建表操作
   * @param context 应用上下文
   * @returns 初始化完成的 RdbStore 实例
   */
  static async initDatabase(context: Context): Promise<relationalStore.RdbStore> {
    if (DatabaseHelper.store !== null) {
      return DatabaseHelper.store
    }
    try {
      // 创建或打开数据库
      const store = await relationalStore.getRdbStore(context, STORE_CONFIG)
      DatabaseHelper.store = store
      // 执行建表
      await DatabaseHelper.createTables(store)
      hilog.info(DOMAIN, TAG, 'Database initialized successfully.')
      return store
    } catch (err) {
      const error = err as BusinessError
      hilog.error(DOMAIN, TAG, 'Failed to initialize database. Code: %{public}d, message: %{public}s',
        error.code, error.message)
      throw new Error(`Database init failed: ${error.message}`)
    }
  }

  // 执行所有建表语句
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

  /** 关闭数据库连接并释放实例 */
  static close(): void {
    if (DatabaseHelper.store !== null) {
      DatabaseHelper.store.close()
      DatabaseHelper.store = null
      hilog.info(DOMAIN, TAG, 'Database closed.')
    }
  }
}
