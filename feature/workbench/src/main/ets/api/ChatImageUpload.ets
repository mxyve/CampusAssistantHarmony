import promptAction from '@ohos.promptAction';
import http from '@ohos.net.http';
import { storageUtil } from 'storage';
import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';

interface ChatUploadResponse {
  code: number;
  message?: string;
  data?: string[]; // 图片 URL 数组
}

/* 1 把单文件读数据函数直接搬过来 */
async function readImageToUint8Array(imageUri: string): Promise<Uint8Array | null> {
  try {
    const file = await fs.open(imageUri, fs.OpenMode.READ_ONLY);
    const stat = await fs.stat(file.fd);
    const max = 5 * 1024 * 1024;
    if (stat.size <= 0 || stat.size > max) {
      promptAction.showToast({ message: '图片需 0-5MB' });
      await fs.close(file);
      return null;
    }
    const buf = new ArrayBuffer(stat.size);
    const read = await fs.read(file.fd, buf);
    await fs.close(file);
    if (read !== stat.size) {
      return null;
    }
    return new Uint8Array(buf);
  } catch (e) {
    console.error('读图失败', e);
    return null;
  }
}

/* 2 上传函数：入参 uri 数组，出参 URL 数组 */
export async function uploadChatImages(uris: string[]): Promise<string[]> {
  const token = await storageUtil.get('token').then(v => v?.toString() ?? '');
  if (!token) {
    promptAction.showToast({ message: '请先登录' });
    return [];
  }

  const client = http.createHttp();
  const url = 'http://192.168.0.102:6060/api/v1/messages/me/image/chat';

  /* 2.1 把每个 uri 转成 MultiFormData */
  const list: http.MultiFormData[] = [];
  for (const uri of uris) {
    const data = await readImageToUint8Array(uri);
    if (!data) {
      continue;
    }
    list.push({
      name: 'files', // 后端参数名：@RequestParam List<MultipartFile> files
      contentType: uri.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg',
      remoteFileName: uri.split('/').pop() ?? 'chat.jpg',
      data: data.buffer
    });
  }

  if (list.length === 0) {
    promptAction.showToast({ message: '没有可用图片' });
    return [];
  }

  /* 2.2 发请求 */
  return new Promise<string[]>((resolve) => {
    client.request(
      url,
      {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'multipart/form-data'
        },
        multiFormDataList: list
      },
      (err: BusinessError, res: http.HttpResponse) => {
        client.destroy();
        if (err || res.responseCode >= 400) {
          promptAction.showToast({ message: '上传失败' });
          resolve([]);
          return;
        }
        try {
          const body = JSON.parse(res.result as string) as ChatUploadResponse;
          if (body.code === 200 && Array.isArray(body.data)) {
            resolve(body.data as string[]);
          } else {
            promptAction.showToast({ message: body.message ?? '上传异常' });
            resolve([]);
          }
        } catch {
          promptAction.showToast({ message: '解析失败' });
          resolve([]);
        }
      }
    );
  });
}