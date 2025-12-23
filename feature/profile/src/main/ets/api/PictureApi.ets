import promptAction from '@ohos.promptAction';
import http from '@ohos.net.http';
import { storageUtil } from 'storage';
import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import util from '@ohos.util';

interface DirectUploadResponse {
  code: number;
  message?: string;
  data?: string;
}

interface RequestHeaders {
  'Authorization': string;
  'Content-Type': string;
  'Content-Length': string; // 新增：Content-Length请求头
}

interface MultipartResult {
  data: Uint8Array;
  contentType: string;
}

// 新增：根据文件URI判断图片MIME类型
function getImageMimeType(imageUri: string): string {
  const ext = imageUri.split('.').pop()?.toLowerCase() || 'jpg';
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    default:
      return 'image/jpeg'; // 默认JPG
  }
}

async function readImageToUint8Array(imageUri: string): Promise<Uint8Array | null> {
  try {
    const file = await fs.open(imageUri, fs.OpenMode.READ_ONLY);
    if (!file || !file.fd) {
      console.error('❌ 文件句柄获取失败');
      return null;
    }

    const fileStat = await fs.stat(file.fd);
    const maxSize = 5 * 1024 * 1024;
    if (fileStat.size <= 0 || fileStat.size > maxSize) {
      await fs.close(file);
      console.error('❌ 文件大小异常:', fileStat.size);
      promptAction.showToast({ message: '图片大小需在0-5MB之间' });
      return null;
    }

    await fs.lseek(file.fd, 0, 0);
    const buffer = new ArrayBuffer(fileStat.size);
    const readBytes = await fs.read(file.fd, buffer);
    if (readBytes !== fileStat.size) {
      await fs.close(file);
      console.error('❌ 图片读取不完整，预期:', fileStat.size, '实际:', readBytes);
      promptAction.showToast({ message: '图片读取不完整，请换一张' });
      return null;
    }

    await fs.close(file);
    const fileData = new Uint8Array(buffer);
    console.log('✅ 读取图片成功，大小:', fileData.length);
    return fileData;
  } catch (err) {
    console.error('❌ 读取图片失败:', err);
    promptAction.showToast({ message: '图片读取失败，请换一张' });
    return null;
  }
}

// 修改1：接收imageUri参数，动态设置MIME类型
function buildMultipartFormData(fileData: Uint8Array, imageUri: string): MultipartResult {
  const boundary = '----WebKitFormBoundary' + Date.now();
  const textEncoder = new util.TextEncoder();
  // 动态获取MIME类型
  const mimeType = getImageMimeType(imageUri);
  // 修复：文件名保留原后缀，MIME类型动态适配
  const fileName = imageUri.split('/').pop() || 'avatar.jpg';
  const headerStr = `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="file"; filename="${fileName}"\r\n` +
    `Content-Type: ${mimeType}\r\n\r\n`; // 不再硬编码jpeg
  const headerBytes = textEncoder.encode(headerStr);
  const footerStr = `\r\n--${boundary}--\r\n`;
  const footerBytes = textEncoder.encode(footerStr);

  console.log('头部大小:', headerBytes.length);
  console.log('尾部大小:', footerBytes.length);

  const totalLength = headerBytes.length + fileData.length + footerBytes.length;
  console.log('总拼接大小:', totalLength);
  const formData = new Uint8Array(totalLength);
  formData.set(headerBytes, 0);
  formData.set(fileData, headerBytes.length);
  formData.set(footerBytes, headerBytes.length + fileData.length);

  return {
    data: formData,
    contentType: `multipart/form-data; boundary=${boundary}`
  };
}

export class PictureApi {
  static async uploadAvatar(imageUri: string): Promise<string | null> {
    console.log('📱 开始上传头像，URI:', imageUri);

    const fileData = await readImageToUint8Array(imageUri);
    if (!fileData) {
      return null;
    }

    let token: string = '';
    try {
      const tokenValue = await storageUtil.get('token');
      token = tokenValue ? tokenValue.toString() : '';
      if (!token) {
        console.error('❌ Token为空');
        promptAction.showToast({ message: '登录状态失效，请重新登录' });
        return null;
      }
    } catch (tokenErr) {
      console.error('❌ 获取Token失败:', tokenErr);
      promptAction.showToast({ message: '鉴权失败' });
      return null;
    }

    // 修改2：调用buildMultipartFormData时传入imageUri
    const multipartData = buildMultipartFormData(fileData, imageUri);
    console.log('请求体总大小:', multipartData.data.length);

    return new Promise<string | null>((resolve) => {
      const httpRequest = http.createHttp();
      const uploadUrl = 'http://192.168.1.14:6060/api/v1/users/me/image';

      // 修改3：新增Content-Length请求头（Tomcat解析必需）
      const headers: RequestHeaders = {
        'Authorization': `Bearer ${token}`,
        'Content-Type': multipartData.contentType,
        'Content-Length': multipartData.data.length.toString() // 关键：告诉后端请求体总长度
      };

      // 1. 创建原生 multiFormDataList（不要手动拼 boundary）
      const multiFormDataList: Array<http.MultiFormData> = [
        {
          name: 'file',
          contentType: getImageMimeType(imageUri),
          remoteFileName: imageUri.split('/').pop() || 'avatar.jpg',
          data: fileData.buffer          // ArrayBuffer
        }
      ];

      console.log('🌐 发送上传请求到:', uploadUrl);
      httpRequest.request(
        uploadUrl,
        {
          method: http.RequestMethod.POST,
          header: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'multipart/form-data'   // 让鸿蒙自动补 boundary
          },
          multiFormDataList: multiFormDataList
        },
        (err: BusinessError, response: http.HttpResponse) => {
          httpRequest.destroy();

          if (err) {
            console.error('❌ 上传请求失败:', err);
            promptAction.showToast({
              message: `上传失败: ${err.message || '网络异常'}`
            });
            resolve(null);
            return;
          }

          try {
            console.log('✅ 上传请求响应状态码:', response.responseCode);
            let responseData: DirectUploadResponse;

            if (typeof response.result === 'string') {
              responseData = JSON.parse(response.result) as DirectUploadResponse;
            } else {
              responseData = response.result as DirectUploadResponse;
            }

            console.log('📦 上传响应数据:', responseData);

            if (responseData && responseData.code === 200 && responseData.data) {
              promptAction.showToast({ message: '头像上传成功' });
              resolve(responseData.data);
            } else {
              console.error('❌ 服务器返回失败:', responseData?.message);
              promptAction.showToast({
                message: responseData?.message || '上传失败，服务器处理异常'
              });
              resolve(null);
            }
          } catch (parseErr) {
            console.error('❌ 解析响应失败:', parseErr);
            promptAction.showToast({ message: '上传响应解析失败' });
            resolve(null);
          }
        }
      );
    });
  }
}