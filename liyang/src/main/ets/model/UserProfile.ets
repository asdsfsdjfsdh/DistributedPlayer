// 用户认证类型枚举
export enum AuthType {
  HUAWEI = 0,  // 华为账号登录
  EMAIL = 1     // 邮箱登录
}

// 用户资料数据契约（来自后端API的只读数据）
export interface UserProfileData {
  readonly userId: string
  readonly authType: AuthType
  readonly openid: string
  readonly email: string
  readonly nickname: string
  readonly avatarUrl: string
  readonly theme: number
}

/**
 * 用户资料模型
 * - 数据来源：后端 REST API（不存储在本地 DB）
 * - 身份鉴定：后端 JWT Token
 * - 适用于：个人信息展示、资料编辑、注册/登录响应
 */
export class UserProfile implements UserProfileData {
  private _userId: string = ''
  private _authType: AuthType = AuthType.HUAWEI
  private _openid: string = ''
  private _email: string = ''
  private _nickname: string = ''
  private _avatarUrl: string = ''
  private _theme: number = 0

  get userId(): string { return this._userId }
  set userId(value: string) { this._userId = value }

  get authType(): AuthType { return this._authType }
  set authType(value: AuthType) { this._authType = value }

  get openid(): string { return this._openid }
  set openid(value: string) { this._openid = value }

  get email(): string { return this._email }
  set email(value: string) { this._email = value }

  get nickname(): string { return this._nickname }
  set nickname(value: string) { this._nickname = value }

  get avatarUrl(): string { return this._avatarUrl }
  set avatarUrl(value: string) { this._avatarUrl = value }

  get theme(): number { return this._theme }
  set theme(value: number) { this._theme = value }

  // 工厂方法：从部分数据创建用户实例
  static create(data: Partial<UserProfileData>): UserProfile {
    const profile = new UserProfile()
    if (data.userId !== undefined) { profile.userId = data.userId }
    if (data.authType !== undefined) { profile.authType = data.authType }
    if (data.openid !== undefined) { profile.openid = data.openid }
    if (data.email !== undefined) { profile.email = data.email }
    if (data.nickname !== undefined) { profile.nickname = data.nickname }
    if (data.avatarUrl !== undefined) { profile.avatarUrl = data.avatarUrl }
    if (data.theme !== undefined) { profile.theme = data.theme }
    return profile
  }

  // 序列化为纯数据对象
  toObject(): UserProfileData {
    return {
      userId: this._userId,
      authType: this._authType,
      openid: this._openid,
      email: this._email,
      nickname: this._nickname,
      avatarUrl: this._avatarUrl,
      theme: this._theme
    }
  }

  // 从后端 API JSON 响应反序列化
  static fromResponse(data: Record<string, Object>): UserProfile {
    const profile = new UserProfile()
    profile.userId = (data['userId'] as string) ?? (data['user_id'] as string) ?? ''
    profile.authType = (data['authType'] as AuthType) ?? (data['auth_type'] as AuthType) ?? AuthType.EMAIL
    profile.openid = (data['openid'] as string) ?? ''
    profile.email = (data['email'] as string) ?? ''
    profile.nickname = (data['nickname'] as string) ?? ''
    profile.avatarUrl = (data['avatarUrl'] as string) ?? (data['avatar_url'] as string) ?? ''
    profile.theme = (data['theme'] as number) ?? 0
    return profile
  }

  // 序列化为 API 请求体（用于注册 / 更新资料等 POST/PUT 请求）
  toRequestBody(): Record<string, Object> {
    const body: Record<string, Object> = {
      'authType': this._authType,
      'nickname': this._nickname,
      'avatarUrl': this._avatarUrl,
      'theme': this._theme
    }
    if (this._openid.length > 0) {
      body['openid'] = this._openid
    }
    if (this._email.length > 0) {
      body['email'] = this._email
    }
    return body
  }
}
