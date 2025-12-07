import { LoginDTO, SmsDTO, TokenVO } from '../types/AuthType';
import { AxiosUtil } from 'network';

/**
 * 认证相关接口调用集合
 */
export class AuthApi {
  /**
   * 发送短信验证码
   * @param mobile 目标手机号
   * @returns 成功返回 message 或空字符串，失败返回 null
   */
  static async sendSmsCode(mobile: string): Promise<string | null> {
    try {
      const response = await AxiosUtil.post<string>(`/api/v1/auth/sms-codes?mobile=${mobile}`);
      if (response.data.code === 200) {
        return response.data.message || response.data.data || '';
      } else {
        console.error(`发送短信验证码失败，code: ${response.data.code}, message: ${response.data.message}`);
        return null;
      }
    } catch (error) {
      console.error('发送短信验证码异常：', error);
      return null;
    }
  }

  /**
   * 短信验证码登录
   * @param params 短信登录参数（手机号+验证码）
   * @returns 登录成功的Token信息
   */
  static async smsLogin(params: SmsDTO): Promise<TokenVO | null> {
    try {
      const response = await AxiosUtil.post<TokenVO>('/api/v1/auth/sessions/sms', params);

      if (response.data.code === 200) {
        return response.data.data;
      } else {
        console.error(`短信验证码登录失败，code: ${response.data.code}, message: ${response.data.message}`);
        return null;
      }
    } catch (error) {
      console.error('短信验证码登录异常：', error);
      return null;
    }
  }

  /**
   * 账号密码登录
   * @param params 登录参数（用户名+密码）
   * @returns 登录成功的Token信息
   */
  static async passwordLogin(params: LoginDTO): Promise<TokenVO | null> {
    try {
      const response = await AxiosUtil.post<TokenVO>('/api/v1/auth/sessions', params);

      if (response.data.code === 200) {
        return response.data.data;
      } else {
        console.error(`账号密码登录失败，code: ${response.data.code}, message: ${response.data.message}`);
        return null;
      }
    } catch (error) {
      console.error('账号密码登录异常：', error);
      return null;
    }
  }
}