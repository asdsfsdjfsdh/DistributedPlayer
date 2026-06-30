// 用户认证类型枚举
export enum AuthType {
  HUAWEI = 0,  // 华为账号登录
  EMAIL = 1     // 邮箱登录
}

// 用户资料数据契约
export interface UserProfileData {
  readonly userId: string
  readonly authType: AuthType
  readonly openid: string
  readonly email: string
  readonly passwordHash: string
  readonly nickname: string
  readonly avatarUrl: string
  readonly theme: number
  readonly syncTime: number
}

// 用户资料实体
export class UserProfile implements UserProfileData {
  private _userId: string = ''
  private _authType: AuthType = AuthType.HUAWEI
  private _openid: string = ''
  private _email: string = ''
  private _passwordHash: string = ''
  private _nickname: string = ''
  private _avatarUrl: string = ''
  private _theme: number = 0
  private _syncTime: number = 0

  get userId(): string { return this._userId }
  set userId(value: string) { this._userId = value }

  get authType(): AuthType { return this._authType }
  set authType(value: AuthType) { this._authType = value }

  get openid(): string { return this._openid }
  set openid(value: string) { this._openid = value }

  get email(): string { return this._email }
  set email(value: string) { this._email = value }

  get passwordHash(): string { return this._passwordHash }
  set passwordHash(value: string) { this._passwordHash = value }

  get nickname(): string { return this._nickname }
  set nickname(value: string) { this._nickname = value }

  get avatarUrl(): string { return this._avatarUrl }
  set avatarUrl(value: string) { this._avatarUrl = value }

  get theme(): number { return this._theme }
  set theme(value: number) { this._theme = value }

  get syncTime(): number { return this._syncTime }
  set syncTime(value: number) { this._syncTime = value }

  // 工厂方法：从部分数据创建用户实例
  static create(data: Partial<UserProfileData>): UserProfile {
    const profile = new UserProfile()
    if (data.userId !== undefined) { profile.userId = data.userId }
    if (data.authType !== undefined) { profile.authType = data.authType }
    if (data.openid !== undefined) { profile.openid = data.openid }
    if (data.email !== undefined) { profile.email = data.email }
    if (data.passwordHash !== undefined) { profile.passwordHash = data.passwordHash }
    if (data.nickname !== undefined) { profile.nickname = data.nickname }
    if (data.avatarUrl !== undefined) { profile.avatarUrl = data.avatarUrl }
    if (data.theme !== undefined) { profile.theme = data.theme }
    if (data.syncTime !== undefined) { profile.syncTime = data.syncTime }
    return profile
  }

  // 序列化为纯数据对象
  toObject(): UserProfileData {
    return {
      userId: this._userId,
      authType: this._authType,
      openid: this._openid,
      email: this._email,
      passwordHash: this._passwordHash,
      nickname: this._nickname,
      avatarUrl: this._avatarUrl,
      theme: this._theme,
      syncTime: this._syncTime
    }
  }

  // 从数据库结果集反序列化
  static fromResultSet(row: Record<string, Object>): UserProfile {
    const profile = new UserProfile()
    profile.userId = (row['user_id'] as string) ?? ''
    profile.authType = (row['auth_type'] as AuthType) ?? AuthType.HUAWEI
    profile.openid = (row['openid'] as string) ?? ''
    profile.email = (row['email'] as string) ?? ''
    profile.passwordHash = (row['password_hash'] as string) ?? ''
    profile.nickname = (row['nickname'] as string) ?? ''
    profile.avatarUrl = (row['avatar_url'] as string) ?? ''
    profile.theme = (row['theme'] as number) ?? 0
    profile.syncTime = (row['sync_time'] as number) ?? 0
    return profile
  }

  // 序列化为数据库写入格式（ValuesBucket）
  toValuesBucket(): Record<string, Object> {
    const bucket: Record<string, Object> = {
      'user_id': this._userId,
      'auth_type': this._authType,
      'nickname': this._nickname,
      'avatar_url': this._avatarUrl,
      'theme': this._theme,
      'sync_time': this._syncTime
    }
    // 可选字段仅在有值时写入
    if (this._openid.length > 0) {
      bucket['openid'] = this._openid
    }
    if (this._email.length > 0) {
      bucket['email'] = this._email
    }
    if (this._passwordHash.length > 0) {
      bucket['password_hash'] = this._passwordHash
    }
    return bucket
  }
}
