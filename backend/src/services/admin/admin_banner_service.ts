import { AppDataSource } from '../../config/database';
import { BannerModel } from '../../models/banner_model';

export class AdminBannerService {
  private bannerRepo = AppDataSource.getRepository(BannerModel);

  async getAllBanners() {
    return await this.bannerRepo.find({
      order: {
        thuTu: 'ASC',
        maBanner: 'DESC',
      },
    });
  }

  async getActiveBanners() {
    return await this.bannerRepo.find({
      where: { trangThai: 'HOAT_DONG' },
      order: {
        thuTu: 'ASC',
        maBanner: 'DESC',
      },
    });
  }

  async createBanner(data: Partial<BannerModel>) {
    if (!data.hinhAnh?.trim()) {
      throw new Error('Hình ảnh banner không được để trống');
    }

    const banner = this.bannerRepo.create({
      tieuDe: data.tieuDe?.trim() || 'Banner Ưu Đãi',
      phuDe: data.phuDe?.trim() || '',
      hinhAnh: data.hinhAnh.trim(),
      lienKet: data.lienKet?.trim() || '',
      mauSac: data.mauSac?.trim() || '#FC6011',
      thuTu: Number(data.thuTu) || 0,
      trangThai: data.trangThai || 'HOAT_DONG',
      loaiBanner: data.loaiBanner || 'TRAN_VIEN',
    });

    return await this.bannerRepo.save(banner);
  }

  async updateBanner(maBanner: number, data: Partial<BannerModel>) {
    const banner = await this.bannerRepo.findOne({ where: { maBanner } });
    if (!banner) {
      throw new Error('Không tìm thấy banner');
    }

    if (data.tieuDe !== undefined) banner.tieuDe = data.tieuDe.trim();
    if (data.phuDe !== undefined) banner.phuDe = data.phuDe?.trim() || '';
    if (data.hinhAnh !== undefined) banner.hinhAnh = data.hinhAnh.trim();
    if (data.lienKet !== undefined) banner.lienKet = data.lienKet?.trim() || '';
    if (data.mauSac !== undefined) banner.mauSac = data.mauSac?.trim() || '#FC6011';
    if (data.thuTu !== undefined) banner.thuTu = Number(data.thuTu) || 0;
    if (data.trangThai !== undefined) banner.trangThai = data.trangThai;
    if (data.loaiBanner !== undefined) banner.loaiBanner = data.loaiBanner;

    return await this.bannerRepo.save(banner);
  }

  async deleteBanner(maBanner: number) {
    const banner = await this.bannerRepo.findOne({ where: { maBanner } });
    if (!banner) {
      throw new Error('Không tìm thấy banner');
    }
    await this.bannerRepo.remove(banner);
    return { success: true, message: 'Đã xóa banner' };
  }
}
