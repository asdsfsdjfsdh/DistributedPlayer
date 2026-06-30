export enum AuthType {
  HUAWEI = 0,
  EMAIL = 1
}

export class UserProfile {
  user_id: string = ''
  auth_type: AuthType = AuthType.HUAWEI
  openid: string = ''
  email: string = ''
  password_hash: string = ''
  nickname: string = ''
  avatar_url: string = ''
  theme: number = 0
  sync_time: number = 0

  constructor() {
  }

  static fromResultSet(row: Record<string, Object>): UserProfile {
    const profile = new UserProfile()
    profile.user_id = row['user_id'] as string ?? ''
    profile.auth_type = row['auth_type'] as AuthType ?? AuthType.HUAWEI
    profile.openid = row['openid'] as string ?? ''
    profile.email = row['email'] as string ?? ''
    profile.password_hash = row['password_hash'] as string ?? ''
    profile.nickname = row['nickname'] as string ?? ''
    profile.avatar_url = row['avatar_url'] as string ?? ''
    profile.theme = row['theme'] as number ?? 0
    profile.sync_time = row['sync_time'] as number ?? 0
    return profile
  }

  toValuesBucket(): Record<string, Object> {
    const bucket: Record<string, Object> = {
      'user_id': this.user_id,
      'auth_type': this.auth_type,
      'nickname': this.nickname,
      'avatar_url': this.avatar_url,
      'theme': this.theme,
      'sync_time': this.sync_time
    }
    if (this.openid.length > 0) {
      bucket['openid'] = this.openid
    }
    if (this.email.length > 0) {
      bucket['email'] = this.email
    }
    if (this.password_hash.length > 0) {
      bucket['password_hash'] = this.password_hash
    }
    return bucket
  }
}
