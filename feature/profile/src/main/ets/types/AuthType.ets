// 账号密码登录dto
export interface LoginDTO {
  username: string;
  password: string;
}

// 短信登录、绑定手机号、换绑手机号dto
export interface SmsDTO {
  mobile: string;
  code: string;
}

// 登录返回token
export interface TokenVO {
  token: string;
  expiresIn: number;
}


/**
 * 用户信息视图对象（对应后端 UserVO）
 */
export interface UserVO {
  id: number;
  username: string;
  email?: string;
  mobile?: string;
  avatar?: string;
  nickname?: string;
  gender?: number;
  status?: number;
  createTime?: string;
}
