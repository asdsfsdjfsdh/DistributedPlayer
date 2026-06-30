import { relationalStore } from '@kit.ArkData'
import { BusinessError } from '@kit.BasicServicesKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'DatabaseHelper'

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'distributed_player.db',
  securityLevel: relationalStore.SecurityLevel.S1
}

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

export class DatabaseHelper {
  private static store: relationalStore.RdbStore | null = null

  static getStore(): relationalStore.RdbStore | null {
    return DatabaseHelper.store
  }

  static async initDatabase(context: Context): Promise<relationalStore.RdbStore> {
    if (DatabaseHelper.store !== null) {
      return DatabaseHelper.store
    }
    try {
      const store = await relationalStore.getRdbStore(context, STORE_CONFIG)
      DatabaseHelper.store = store
      await DatabaseHelper.createTables(store)
      hilog.info(DOMAIN, TAG, 'Database initialized successfully.')
      return store
    } catch (err) {
      const error = err as BusinessError
      hilog.error(DOMAIN, TAG, 'Failed to initialize database. Code: %{public}d, message: %{public}s',
        error.code, error.message)
      throw error
    }
  }

  private static async createTables(store: relationalStore.RdbStore): Promise<void> {
    try {
      await store.executeSql(SQL_CREATE_USER_PROFILE)
      hilog.info(DOMAIN, TAG, 'Table user_profile created successfully.')
    } catch (err) {
      const error = err as BusinessError
      hilog.error(DOMAIN, TAG, 'Failed to create table. Code: %{public}d, message: %{public}s',
        error.code, error.message)
      throw error
    }
  }

  static close(): void {
    if (DatabaseHelper.store !== null) {
      DatabaseHelper.store.close()
      DatabaseHelper.store = null
      hilog.info(DOMAIN, TAG, 'Database closed.')
    }
  }
}
