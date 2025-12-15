import axios, { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from "@ohos/axios";
import { BaseResponse } from "../type/CommonType";
import { storageUtil } from "storage";

export const axiosInstance = axios.create({
  baseURL: 'http://192.168.43.6:6060',
  timeout: 60000,
  headers: {}
})

// 请求拦截器：添加 Authorization 头部
axiosInstance.interceptors.request.use(
  async (config: InternalAxiosRequestConfig): Promise<InternalAxiosRequestConfig> => {
    try {
      // 获取 token（兼容 storageUtil 未初始化的情况）
      const token = await storageUtil.get('token');
      if (token) {
        const tokenString = token ? token.toString() : '';
        config.headers.set('Authorization', `Bearer ${tokenString}`); // 鸿蒙 Axios 正确设置 header 方式
      }
    } catch (error) {
      console.warn('获取 token 失败，可能 storageUtil 未初始化:', error);
    }
    return config;
  },
  (error: AxiosError): Promise<AxiosError> => {
    return Promise.reject(error);
  }
);


axiosInstance.interceptors.response.use((response: AxiosResponse) => {
  console.info('✅ axios response:', response.config.url, response.status, response.data)
  return response
}, (error: AxiosError) => {
  return Promise.reject(error)
})


export type ResType<T> = AxiosResponse<BaseResponse<T>>

export class AxiosUtil {
  static get<T>(url: string, params?: object): Promise<ResType<T>> {
    return axiosInstance.get<null, ResType<T>>(url, { params })
  }

  static post<T>(url: string, data?: object): Promise<ResType<T>> {
    return axiosInstance.post<null, ResType<T>>(url, data)
  }

  static put<T>(url: string, data?: object): Promise<ResType<T>> {
    return axiosInstance.put<null, ResType<T>>(url, data)
  }

  static delete<T>(url: string, params?: object): Promise<ResType<T>> {
    return axiosInstance.delete<null, ResType<T>>(url, { params })
  }
}

