// types/UploadType.ts（新增，仅需这一个文件）
import { BaseResponse } from './AuthType';

// 仅定义必要接口（无冗余）
export interface UploadRequestData {
  body: ArrayBuffer; // 上传的二进制数据
  contentType: string; // 请求头Content-Type（含boundary）
}

// 上传响应类型（匹配BaseResponse<string>）
export type UploadAvatarResponse = BaseResponse<string>;

