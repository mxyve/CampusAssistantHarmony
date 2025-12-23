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

/** 头像上传响应类型 */
export interface UploadResult {
  code: number;
  message: string;
  data: string; // 上传成功后返回的OSS图片URL
}

/** 头像上传请求参数 */
export interface UploadAvatarRequest {
  file: string; // Base64字符串
  filename?: string;
}

export interface BaseResponse<T> {
  code: number;
  message: string;
  data: T;
}

export interface AxiosRequestConfig {
  headers?: Record<string, string>;
  timeout?: number;
}

// 2. 定义上传响应类型（匹配后端返回）
export type UploadAvatarResponse = BaseResponse<string>;

// 3. 鸿蒙二进制数据封装接口（替代Blob）
export interface FormDataItem {
  name: string;
  data: ArrayBuffer;
  filename: string;
  contentType: string;
}