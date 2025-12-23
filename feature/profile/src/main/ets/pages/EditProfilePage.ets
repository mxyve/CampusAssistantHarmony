import promptAction from '@ohos.promptAction';
import { UserApi } from '../api/UserApi';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { PictureApi } from '../api/PictureApi';
import util from '@ohos.util';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { storageUtil } from 'storage';

// 显式定义所有必要接口（解决类型报错）
interface PhotoSelectOptions {
  MIMEType: photoAccessHelper.PhotoViewMIMETypes; // 适配新API类型
  maxSelectNumber: number;
}

interface FileInfo {
  path: string;
  name: string;
  size: number;
  type: string;
}

interface UpdateProfileDTO {
  nickname?: string;
  email?: string;
  gender?: number;
  avatar?: string;
}

interface GenderOption {
  label: string;
  value: string;
}

interface OpenModeInterface {
  READ_ONLY: number;
  WRITE_ONLY: number;
  READ_WRITE: number;
  CREATE: number;
}


const OpenMode: OpenModeInterface = {
  READ_ONLY: 0o000000, // 对应fs.OpenMode.READ_ONLY
  WRITE_ONLY: 0o000001,
  READ_WRITE: 0o000002,
  CREATE: 0o000100
};

// 无任何typeof/unknown/索引类型的工具函数（完全符合ArkTS规范）
function getFileFd(path: string, mode: number): number {
  // 直接调用，无类型断言（绕开unknown/any）
  const fd = fs.openSync(path, mode);
  // 运行时校验（确保是数字，无类型断言）
  if (typeof fd !== 'number' || isNaN(fd)) {
    throw new Error('文件句柄必须为有效数字');
  }
  return fd;
}

@Builder
export function EditProfilePageBuilder() {
  EditProfilePage()
}

@Component
export struct EditProfilePage {
  @State nickname: string = '';
  @State email: string = '';
  @State gender: string = '0';
  @State avatarUrl: string = 'app.media.ic_default_avatar';
  @State loading: boolean = true;
  @State isSaving: boolean = false;
  @State private imageBuffer: ArrayBuffer | null = null;
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private originalAvatarUrl: string = '';
  private selectedImageUri: string | null = null;

  aboutToAppear() {
    this.loadUserInfo();
  }

  private async loadUserInfo() {
    try {
      this.loading = true;
      const userInfo = await UserApi.getUserInfo();
      if (userInfo) {
        this.nickname = userInfo.nickname || '';
        this.email = userInfo.email || '';
        this.gender = userInfo.gender?.toString() || '0';
        this.avatarUrl = userInfo.avatar || 'app.media.ic_default_avatar';
        this.originalAvatarUrl = this.avatarUrl;
      } else {
        promptAction.showToast({ message: '加载用户信息失败' });
        this.originalAvatarUrl = 'app.media.ic_default_avatar';
      }
    } catch (error) {
      console.error('加载用户信息异常:', error);
      promptAction.showToast({ message: '加载用户信息异常' });
      this.originalAvatarUrl = 'app.media.ic_default_avatar';
    } finally {
      this.loading = false;
    }
  }

  // ========== 核心重构：完全对齐华为文档方案 ==========
  private async selectAvatar() {
    try {
      // 1. 极简权限申请（无tokenId，无BundleInfo报错）
      const context = this.context;
      const permission = 'ohos.permission.READ_IMAGEVIDEO';
      try {
        const atManager = abilityAccessCtrl.createAtManager();
        const result = await atManager.requestPermissionsFromUser(context, [permission]);
        if (result.authResults[0] !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          promptAction.showToast({ message: '需要授予相册权限才能选择图片' });
          return;
        }
      } catch (err) {
        console.error('权限申请失败:', err);
        promptAction.showToast({ message: '权限申请失败，请手动开启相册权限' });
        return;
      }

      // 2. API12+ 选择图片（显式类型，无无类型字面量报错）
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const selectOptions: PhotoSelectOptions = {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      };
      const pickResult = await photoPicker.select(selectOptions);
      if (!pickResult || !pickResult.photoUris || pickResult.photoUris.length === 0) {
        promptAction.showToast({ message: '未选择图片' });
        return;
      }

      // 3. 华为文档兜底方案：直接通过URI打开图片（绕开所有Predicates/FetchOptions报错）
      const imageUri = pickResult.photoUris[0];
      this.selectedImageUri = imageUri;

      // 核心修复：直接打开URI对应的文件（无需getAssets/条件查询）
      let file: fs.File;
      try {
        // 鸿蒙API12+ 直接通过URI打开媒体文件（华为文档推荐）
        file = await fs.open(imageUri, fs.OpenMode.READ_ONLY);
      } catch (openErr) {
        console.error('直接打开图片失败:', openErr);
        promptAction.showToast({ message: '图片读取失败，请换一张' });
        return;
      }

      // 4. 读取文件字节（无fileFd类型报错）
      const fileStat = await fs.stat(file.fd);
      const maxSize = 5 * 1024 * 1024; // 5MB限制
      if (fileStat.size <= 0 || fileStat.size > maxSize) {
        await fs.close(file);
        promptAction.showToast({ message: '图片大小不能超过5MB' });
        return;
      }

      // 读取字节（显式类型，无any/unknown）
      const buffer: ArrayBuffer = new ArrayBuffer(fileStat.size);
      await fs.lseek(file.fd, 0, 0); // 0 = SEEK_SET
      let readLen = 0;
      while (readLen < fileStat.size) {
        const once = await fs.read(file.fd, buffer, { offset: readLen, length: fileStat.size - readLen });
        readLen += once;
      }
      console.log('🔥 读到字节数:', buffer.byteLength);
      console.log('🔍 close前file对象:', {
        fd: file.fd,
        isValid: file.fd > 0,
        fileType: typeof file
      });
      try {
        await fs.close(file); // 单独try-catch，确认是否是close触发报错
        console.log('✅ fs.close 执行成功');
      } catch (closeErr) {
        console.error('❌ fs.close 失败:', closeErr.message, closeErr.stack);
      }

      console.log('🔍 准备赋值imageBuffer:', {
        bufferValid: buffer.byteLength > 0,
        imageBufferCurrent: this.imageBuffer // 确认当前状态值
      });

      try {
        this.imageBuffer = buffer; // 单独try-catch
        console.log('✅ imageBuffer 赋值成功');
      } catch (assignErr) {
        console.error('❌ imageBuffer 赋值失败:', assignErr.message, assignErr.stack);
      }
      this.avatarUrl = imageUri;
      promptAction.showToast({ message: '图片已选择，点击保存生效' });

    } catch (err) {
      console.error('选图/读取失败:', err);
      promptAction.showToast({ message: '图片选择失败，请重试' });
    }
  }

  // 修复saveProfile的finalAvatar类型报错
  private async saveProfile() {
    if (this.isSaving) {
      return;
    }
    if (!this.nickname.trim()) {
      promptAction.showToast({ message: '请输入昵称' });
      return;
    }

    this.isSaving = true;
    try {
      let finalAvatar = this.originalAvatarUrl;
      // 核心修改1：非空断言 + 类型校验，确保传入的是字符串
      if (this.selectedImageUri) {
        promptAction.showToast({ message: '正在上传头像…' });
        // 核心修改2：! 非空断言，告诉编译器selectedImageUri一定是字符串（已通过if校验）
        const uploadResult = await PictureApi.uploadAvatar(this.selectedImageUri!);
        if (!uploadResult) {
          promptAction.showToast({ message: '头像上传失败' });
          this.isSaving = false;
          return;
        }
        finalAvatar = uploadResult;
        this.imageBuffer = null; // 清空冗余二进制缓存
      }

      const updateData: UpdateProfileDTO = {
        nickname: this.nickname.trim(),
        email: this.email.trim() || undefined,
        gender: parseInt(this.gender) || 0,
        avatar: finalAvatar
      };

      const updateResult = await UserApi.updateProfile(updateData);
      if (updateResult) {
        promptAction.showToast({ message: '保存成功' });
        this.originalAvatarUrl = finalAvatar;
        this.imageBuffer = null;
        const latestUser = await UserApi.getUserInfo();
        AppStorage.setOrCreate('currentUserInfo', latestUser); // 全局状态
        await storageUtil.setObject('userInfo', latestUser); // 本地缓存
        if (latestUser) {
          this.avatarUrl = latestUser.avatar || this.avatarUrl;
        }
      } else {
        promptAction.showToast({ message: '保存失败，请重试' });
      }

    } catch (saveErr) {
      console.error('保存失败:', saveErr);
      promptAction.showToast({ message: '网络异常/保存失败' });
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 保存按钮（文档推荐的禁用态处理）
        Row() {
          Text(this.isSaving ? '保存中...' : '保存')
            .fontSize(16)
            .fontColor(this.isSaving ? '#999999' : '#1890FF')
            .onClick(() => !this.isSaving && this.saveProfile())
        }
        .padding(16)
        .backgroundColor('#FFFFFF')
        .width('100%')

        // 加载状态
        if (this.loading) {
          Column() {
            Text('加载中...')
              .fontSize(14)
              .fontColor('#999999')
          }
        } else {
          Scroll() {
            Column({ space: 20 }) {

              // 头像区域（文档推荐的UI布局）
              Column({ space: 12 }) {
                Text('头像').fontSize(16).textAlign(TextAlign.Start)
                Row({ space: 16 }) {
                  Image(this.avatarUrl.startsWith('app.media') ? $r(this.avatarUrl) : this.avatarUrl)
                    .width(80)
                    .height(80)
                    .borderRadius(40)
                    .objectFit(ImageFit.Cover)
                  Button('选择头像')
                    .width(120)
                    .height(40)
                    .borderRadius(8)
                    .backgroundColor('#F5F5F5')
                    .onClick(() => this.selectAvatar())
                }
              }

              // 昵称
              Column({ space: 8 }) {
                Text('昵称').fontSize(16).textAlign(TextAlign.Start)
                TextInput({ placeholder: '请输入昵称', text: this.nickname })
                  .width('100%')
                  .height(56)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(12)
                  .padding(16)
                  .onChange((v) => this.nickname = v)
              }

              // 邮箱
              Column({ space: 8 }) {
                Text('邮箱').fontSize(16).textAlign(TextAlign.Start)
                TextInput({ placeholder: '请输入邮箱', text: this.email })
                  .width('100%')
                  .height(56)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(12)
                  .padding(16)
                  .onChange((v) => this.email = v)
              }

              // 性别选择（文档推荐的ForEach写法）
              Column({ space: 8 }) {
                Text('性别').fontSize(16).textAlign(TextAlign.Start)
                Row({ space: 20 }) {
                  ForEach(
                    [
                      { label: '男', value: '1' },
                      { label: '女', value: '2' },
                      { label: '保密', value: '0' }
                    ],
                    (item: GenderOption) => {
                      Row() {
                        Radio({ value: item.value, group: 'gender' })
                          .checked(this.gender === item.value)
                          .onChange((c: boolean) => c && (this.gender = item.value))
                        Text(item.label).fontSize(14)
                      }
                    },
                    (item: GenderOption) => item.value
                  )
                }
              }
            }
          }
          .scrollBar(BarState.Off)
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .title('编辑资料')
  }
}