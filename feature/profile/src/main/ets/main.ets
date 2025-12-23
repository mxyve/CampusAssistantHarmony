// main.ts（仅新增这部分代码，AxiosUtil 源码完全不动）
import { axiosInstance } from 'network'; // 导入你的axiosInstance
import util from '@ohos.util';
import { storageUtil } from 'storage';
import { InternalAxiosRequestConfig } from "@ohos/axios";


// 存储上传接口的boundary（全局唯一）
let uploadBoundary = '';

// 供PictureApi调用：设置boundary
export function setUploadBoundary(boundary: string) {
  uploadBoundary = boundary;
}

// 新增拦截器：优先处理上传接口，确保Token和Content-Type都存在
axiosInstance.interceptors.request.use(
  async (config: InternalAxiosRequestConfig) => {
    // 仅处理上传头像接口
    if (config.url === '/api/v1/users/me/image') {
      // 1. 重新设置Token（确保不被覆盖）
      const token = await storageUtil.get('token');
      if (token) {
        const tokenString = token.toString();
        config.headers.set('Authorization', `Bearer ${tokenString}`);
      }
      // 2. 设置Content-Type（含boundary）
      if (uploadBoundary) {
        config.headers.set('Content-Type', `multipart/form-data; boundary=${uploadBoundary}`);
        uploadBoundary = ''; // 用完清空
      }
    }
    return config;
  },
  (error: Error) => Promise.reject(error)
);