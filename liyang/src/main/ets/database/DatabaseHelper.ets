import { relationalStore } from '@kit.ArkData'
import { BusinessError } from '@kit.BasicServicesKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'DatabaseHelper'

// 数据库配置：启用云端协同，多设备数据自动同步
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'distributed_player.db',
  securityLevel: relationalStore.SecurityLevel.S1
}

// 云端同步表名列表（在建表后调用 setDistributedTables 注册）
// 这些表存储后端数据的离线缓存副本，同一华为账号多设备自动同步
const CLOUD_SYNC_TABLES: string[] = [
  'playlist',
  'playlist_song',
  'favorite',
  'play_history'
]

// 建表SQL：本地歌曲元数据表（仅存储 source=0 的本地扫描歌曲，不参与云同步）
const SQL_CREATE_SONG = `
  CREATE TABLE IF NOT EXISTS song (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    artist TEXT,
    album TEXT,
    duration INTEGER,
    file_path TEXT,
    cover_url TEXT,
    source INTEGER DEFAULT 0,
    scan_time INTEGER DEFAULT 0
  )
`

/**
 * 本地数据库初始化与管理助手
 * - 单例模式管理 RdbStore 实例
 * - 启用 cloudSwitch 实现云端协同
 * - 本地仅存储离线缓存与本地歌曲元数据
 * - 用户身份由后端 JWT 鉴定，用户数据不在本地存储
 */
export class DatabaseHelper {
  // 全局唯一 RdbStore 实例
  private static store: relationalStore.RdbStore | null = null

  /** 获取当前 RdbStore 实例（可能为 null） */
  static getStore(): relationalStore.RdbStore | null {
    return DatabaseHelper.store
  }

  /**
   * 初始化本地数据库
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
      // 执行建表（仅本地表，同步表后续按需创建）
      await DatabaseHelper.createTables(store)
      // 注册参与云端同步的表（后端数据的离线缓存副本）
      await DatabaseHelper.enableCloudSync(store)
      hilog.info(DOMAIN, TAG, 'Local database initialized successfully.')
      return store
    } catch (err) {
      const error = err as BusinessError
      hilog.error(DOMAIN, TAG, 'Failed to initialize database. Code: %{public}d, message: %{public}s',
        error.code, error.message)
      throw new Error(`Database init failed: ${error.message}`)
    }
  }

  // 执行所有纯本地表的建表语句
  private static async createTables(store: relationalStore.RdbStore): Promise<void> {
    try {
      // 本地歌曲元数据表（仅 source=0 的本地扫描歌曲）
      await store.executeSql(SQL_CREATE_SONG)
      hilog.info(DOMAIN, TAG, 'Local table song created successfully.')
    } catch (err) {
      const error = err as BusinessError
      hilog.error(DOMAIN, TAG, 'Failed to create table. Code: %{public}d, message: %{public}s',
        error.code, error.message)
      throw new Error(`Create table failed: ${error.message}`)
    }
  }

  /**
   * 注册云端同步表
   * - 标记后端数据的离线缓存表参与云端协同
   * - 本地歌曲表（song）不参与云同步
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
