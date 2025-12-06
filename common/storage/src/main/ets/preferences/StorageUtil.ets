import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 本地存储工具类
 * 使用 Preferences API 实现数据持久化
 */
export class StorageUtil {
  private static instance: StorageUtil;
  private dataPreferences: preferences.Preferences | null = null;
  private readonly PREF_NAME = 'app_storage';

  private constructor() {
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): StorageUtil {
    if (!StorageUtil.instance) {
      StorageUtil.instance = new StorageUtil();
    }
    return StorageUtil.instance;
  }

  /**
   * 初始化存储
   */
  public async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.dataPreferences = await preferences.getPreferences(context, this.PREF_NAME);
      hilog.info(0x0000, 'StorageUtil', '存储初始化成功');
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(0x0000, 'StorageUtil', `存储初始化失败: ${error.message}`);
    }
  }

  /**
   * 保存数据
   */
  public async set(key: string, value: string | number | boolean): Promise<void> {
    if (!this.dataPreferences) {
      hilog.error(0x0000, 'StorageUtil', '存储未初始化');
      return;
    }
    try {
      await this.dataPreferences.put(key, value);
      await this.dataPreferences.flush();
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(0x0000, 'StorageUtil', `保存数据失败: ${error.message}`);
    }
  }

  /**
   * 获取数据
   * @param key
   */
  public async get(key: string, defaultValue: preferences.ValueType = ''): Promise<preferences.ValueType> {
    if (!this.dataPreferences) {
      hilog.warn(0x0000, 'StorageUtil', '存储未初始化，返回默认值');
      return defaultValue;
    }
    try {
      return await this.dataPreferences.get(key, defaultValue);
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(0x0000, 'StorageUtil', `获取数据失败: ${error.message}`);
      return defaultValue;
    }
  }

  /**
   * 删除数据
   */
  public async delete(key: string): Promise<void> {
    if (!this.dataPreferences) {
      hilog.error(0x0000, 'StorageUtil', '存储未初始化');
      return;
    }
    try {
      await this.dataPreferences.delete(key);
      await this.dataPreferences.flush();
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(0x0000, 'StorageUtil', `删除数据失败: ${error.message}`);
    }
  }

  /**
   * 检查键是否存在
   */
  public async has(key: string): Promise<boolean> {
    if (!this.dataPreferences) {
      hilog.error(0x0000, 'StorageUtil', '存储未初始化');
      return false;
    }
    try {
      return await this.dataPreferences.has(key);
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(0x0000, 'StorageUtil', `检查键失败: ${error.message}`);
      return false;
    }
  }

  /**
   * 清空所有数据
   */
  public async clear(): Promise<void> {
    if (!this.dataPreferences) {
      hilog.error(0x0000, 'StorageUtil', '存储未初始化');
      return;
    }
    try {
      await this.dataPreferences.clear();
      await this.dataPreferences.flush();
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(0x0000, 'StorageUtil', `清空数据失败: ${error.message}`);
    }
  }

  /**
   * 保存对象 (序列化为 JSON)
   */
  public async setObject<T>(key: string, value: T): Promise<void> {
    try {
      const jsonString = JSON.stringify(value);
      await this.set(key, jsonString);
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(0x0000, 'StorageUtil', `保存对象失败: ${error.message}`);
    }
  }

  /**
   * 获取对象 (反序列化 JSON)
   */
  public async getObject<T>(key: string, defaultValue?: T): Promise<T | null> {
    try {
      const jsonString = await this.get(key, '') as string;
      if (!jsonString) {
        return defaultValue || null;
      }
      return JSON.parse(jsonString) as T;
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(0x0000, 'StorageUtil', `获取对象失败: ${error.message}`);
      return defaultValue || null;
    }
  }
}

// 导出单例实例
export const storageUtil = StorageUtil.getInstance();
