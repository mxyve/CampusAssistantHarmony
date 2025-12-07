import { UserVO } from '../types/AuthType';
import { AxiosUtil } from 'network';

/**
 * 用户相关接口调用集合
 */
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
   * 根据 ID 查询用户
   * @param id 用户 ID
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
}
