import { AppDataSource } from '../config/database';
import { LoaiHinhQuanModel } from '../models/loai_hinh_quan_model';
import { CuaHangModel } from '../models/cua_hang_model';

export class StoreCategoryService {
  private categoryRepo = AppDataSource.getRepository(LoaiHinhQuanModel);
  private storeRepo = AppDataSource.getRepository(CuaHangModel);

  async getAll(search?: string) {
    const qb = this.categoryRepo.createQueryBuilder('c');
    if (search && search.trim()) {
      qb.where('LOWER(c.tenLoai) LIKE LOWER(:search) OR LOWER(c.moTa) LIKE LOWER(:search)', {
        search: `%${search.trim()}%`,
      });
    }
    qb.orderBy('c.maLoai', 'ASC');
    const categories = await qb.getMany();

    // Query store counts grouped by danhmuc
    const storeCounts = await this.storeRepo
      .createQueryBuilder('s')
      .select('s.danhmuc', 'danhMuc')
      .addSelect('COUNT(*)', 'count')
      .where('s.isDeleted = false')
      .groupBy('s.danhmuc')
      .getRawMany();

    return categories.map((cat) => {
      // Find matching count by exact name or substring
      let count = 0;
      for (const sc of storeCounts) {
        if (!sc.danhMuc) continue;
        const dm = sc.danhMuc.trim().toLowerCase();
        const tl = cat.tenLoai.trim().toLowerCase();
        if (dm === tl || dm.includes(tl) || tl.includes(dm)) {
          count += parseInt(sc.count, 10) || 0;
        }
      }
      return {
        ...cat,
        soLuongQuan: count,
      };
    });
  }

  async getActive() {
    return await this.categoryRepo.find({
      where: { trangThai: 'ACTIVE' },
      order: { maLoai: 'ASC' },
    });
  }

  async getById(id: number) {
    const cat = await this.categoryRepo.findOne({ where: { maLoai: id } });
    if (!cat) throw new Error('Không tìm thấy loại hình quán');
    return cat;
  }

  async create(data: {
    tenLoai: string;
    moTa?: string;
    hinhAnh?: string;
    icon?: string;
    thuTu?: number;
    trangThai?: string;
  }) {
    const trimmed = data.tenLoai?.trim();
    if (!trimmed) throw new Error('Vui lòng nhập tên loại hình quán');

    const existing = await this.categoryRepo
      .createQueryBuilder('c')
      .where('LOWER(c.tenLoai) = LOWER(:name)', { name: trimmed })
      .getOne();

    if (existing) {
      throw new Error(`Loại hình "${existing.tenLoai}" đã tồn tại trong hệ thống!`);
    }

    const item = this.categoryRepo.create({
      tenLoai: trimmed,
      moTa: data.moTa?.trim(),
      hinhAnh: data.hinhAnh?.trim(),
      icon: data.icon?.trim() || 'Store',
      thuTu: data.thuTu !== undefined ? Number(data.thuTu) : 0,
      trangThai: data.trangThai || 'ACTIVE',
    });

    return await this.categoryRepo.save(item);
  }

  async update(
    id: number,
    data: {
      tenLoai?: string;
      moTa?: string;
      hinhAnh?: string;
      icon?: string;
      thuTu?: number;
      trangThai?: string;
    }
  ) {
    const cat = await this.getById(id);
    const oldName = cat.tenLoai;

    if (data.tenLoai !== undefined) {
      const trimmed = data.tenLoai.trim();
      if (!trimmed) throw new Error('Tên loại hình không được để trống');

      const existing = await this.categoryRepo
        .createQueryBuilder('c')
        .where('LOWER(c.tenLoai) = LOWER(:name)', { name: trimmed })
        .andWhere('c.maLoai != :id', { id })
        .getOne();

      if (existing) {
        throw new Error(`Loại hình "${existing.tenLoai}" đã tồn tại!`);
      }
      cat.tenLoai = trimmed;
    }

    if (data.moTa !== undefined) cat.moTa = data.moTa?.trim() || undefined;
    if (data.hinhAnh !== undefined) cat.hinhAnh = data.hinhAnh?.trim() || undefined;
    if (data.icon !== undefined) cat.icon = data.icon?.trim() || cat.icon;
    if (data.thuTu !== undefined) cat.thuTu = Number(data.thuTu);
    if (data.trangThai !== undefined) cat.trangThai = data.trangThai;

    const saved = await this.categoryRepo.save(cat);

    // If name changed, synchronize existing stores matching old name
    if (data.tenLoai && data.tenLoai.trim() !== oldName) {
      await this.storeRepo
        .createQueryBuilder()
        .update(CuaHangModel)
        .set({ danhMuc: data.tenLoai.trim() })
        .where('danhmuc = :oldName', { oldName })
        .execute();
    }

    return saved;
  }

  async delete(id: number) {
    const cat = await this.getById(id);

    // Check if any stores currently use this category
    const storeCount = await this.storeRepo
      .createQueryBuilder('s')
      .where('LOWER(s.danhmuc) = LOWER(:name)', { name: cat.tenLoai })
      .getCount();

    if (storeCount > 0) {
      throw new Error(
        `Không thể xóa vì đang có ${storeCount} nhà hàng thuộc loại hình "${cat.tenLoai}". Vui lòng chuyển các nhà hàng này sang loại hình khác trước khi xóa!`
      );
    }

    await this.categoryRepo.remove(cat);
    return { success: true, message: `Đã xóa loại hình "${cat.tenLoai}" thành công` };
  }

  async getRestaurantsByCategory(id: number) {
    const cat = await this.getById(id);
    const tl = cat.tenLoai.trim().toLowerCase();

    const stores = await this.storeRepo.find({
      order: { maQuan: 'DESC' },
    });

    const matched = stores.filter((s) => {
      if (!s.danhMuc) return false;
      const dm = s.danhMuc.trim().toLowerCase();
      return dm === tl || dm.includes(tl) || tl.includes(dm);
    });

    return {
      category: cat,
      stores: matched,
    };
  }
}

