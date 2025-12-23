import { UserVO } from '../types/AuthType';
import { AxiosUtil } from 'network';
import http from '@ohos.net.http';


// 复用你的BaseResponse结构
export interface ResultMsg {
  code: number;
  message: string;
}

// 统一响应类型
export interface BaseResponse<T> {
  code: number;
  message: string;
  data: T;
}

interface ReadOptions {
  offset: number;
  length: number;
}

// 文件信息接口
interface FileInfo {
  path: string;
  name: string;
  size: number;
  type: string;
}

// HTTP请求选项接口
interface HttpRequestOptions {
  method: http.RequestMethod;
  header: Record<string, string>;
  extraData: ArrayBuffer | object | string;
  connectTimeout: number;
  readTimeout: number;
}

export class UserApi {
  /**
   * 获取当前登录用户信息
   * @returns 用户信息
   */
  static async getUserInfo(): Promise<UserVO | null> {
    try {
      const response = await AxiosUtil.get<UserVO>('/api/v1/users/me');
      if (response.data.code === 200) {
        return response.data.data;
      } else {
        console.error(`获取用户信息失败，code: ${response.data.code}, message: ${response.data.message}`);
        return null;
      }
    } catch (error) {
      console.error('获取用户信息异常：', error);
      return null;
    }
  }

  /**
   * 根据ID查询用户
   * @param id 用户ID
   * @returns 用户信息
   */
  static async getUserById(id: number): Promise<UserVO | null> {
    try {
      const response = await AxiosUtil.get<UserVO>(`/api/v1/users/${id}`);
      if (response.data.code === 200) {
        return response.data.data;
      } else {
        console.error(`查询用户失败，code: ${response.data.code}, message: ${response.data.message}`);
        return null;
      }
    } catch (error) {
      console.error('查询用户异常：', error);
      return null;
    }
  }

  /**
   * 修改当前登录用户信息
   * @param userEditDTO 用户信息
   * @returns 修改结果
   */
  static async updateProfile(userEditDTO: Partial<UserVO>): Promise<boolean> {
    try {
      const response = await AxiosUtil.put<ResultMsg>('/api/v1/users/me/profile', userEditDTO);
      if (response.data && response.data.code === 200) {
        return true;
      } else {
        console.error(`修改个人信息失败：${response.data?.message || '未知错误'}`);
        return false;
      }
    } catch (error) {
      console.error('修改个人信息异常：', error);
      return false;
    }
  }
}