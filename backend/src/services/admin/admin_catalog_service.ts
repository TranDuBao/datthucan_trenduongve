import { AppDataSource } from '../../config/database';
import { DanhMucModel } from '../../models/danh_muc_model';
import { MonAnModel } from '../../models/mon_an_model';
import { CuaHangModel } from '../../models/cua_hang_model';

export class AdminCatalogService {
  private categoryRepo = AppDataSource.getRepository(DanhMucModel);
  private foodRepo = AppDataSource.getRepository(MonAnModel);
  private storeRepo = AppDataSource.getRepository(CuaHangModel);

  async getCategories() {
    return await this.categoryRepo.find({ order: { maDanhMuc: 'ASC' } });
  }

  async createCategory(tenDanhMuc: string, maDanhMuc?: number) {
    if (maDanhMuc) {
      return await this.updateCategory(maDanhMuc, tenDanhMuc);
    }

    const trimmed = tenDanhMuc.trim();
    const existing = await this.categoryRepo.createQueryBuilder('c')
      .where('LOWER(c.tenDanhMuc) = LOWER(:name)', { name: trimmed })
      .getOne();

    if (existing) {
      throw new Error(`Tên danh mục "${existing.tenDanhMuc}" đã tồn tại trong hệ thống (không phân biệt chữ hoa/thường)!`);
    }

    const cat = this.categoryRepo.create({ tenDanhMuc: trimmed });
    return await this.categoryRepo.save(cat);
  }

  async updateCategory(maDanhMuc: number, tenDanhMuc: string) {
    const trimmed = tenDanhMuc.trim();
    const cat = await this.categoryRepo.findOne({ where: { maDanhMuc } });
    if (!cat) throw new Error('Không tìm thấy danh mục');

    const existing = await this.categoryRepo.createQueryBuilder('c')
      .where('LOWER(c.tenDanhMuc) = LOWER(:name)', { name: trimmed })
      .andWhere('c.maDanhMuc != :maDanhMuc', { maDanhMuc })
      .getOne();

    if (existing) {
      throw new Error(`Tên danh mục "${existing.tenDanhMuc}" đã tồn tại trong hệ thống (không phân biệt chữ hoa/thường)!`);
    }

    cat.tenDanhMuc = trimmed;
    return await this.categoryRepo.save(cat);
  }

  async getCategoryFoods(maDanhMuc: number) {
    const cat = await this.categoryRepo.findOne({ where: { maDanhMuc } });
    if (!cat) throw new Error('Không tìm thấy danh mục');

    const foods = await this.foodRepo.find({
      where: { maDanhMuc },
      order: { maMonAn: 'DESC' },
    });

    const enriched = [];
    for (const f of foods) {
      let storeName = 'Chưa gán quán';
      if (f.maQuan) {
        const store = await this.storeRepo.findOne({ where: { maQuan: f.maQuan } });
        if (store) storeName = store.tenQuan;
      }
      enriched.push({
        ...f,
        tenQuan: storeName,
      });
    }

    return {
      category: cat,
      foods: enriched,
    };
  }

  async getFoods(page: number = 1, limit: number = 1000, search: string = '', maQuan?: number, maDanhMuc?: number) {
    const skip = (page - 1) * limit;
    const qb = this.foodRepo.createQueryBuilder('m')
      .orderBy('m.maMonAn', 'DESC')
      .skip(skip)
      .take(limit);

    if (search.trim()) {
      qb.andWhere('m.tenMonAn ILIKE :s', { s: `%${search.trim()}%` });
    }

    if (maQuan) {
      qb.andWhere('m.maQuan = :maQuan', { maQuan });
    }

    if (maDanhMuc) {
      qb.andWhere('m.maDanhMuc = :maDanhMuc', { maDanhMuc: Number(maDanhMuc) });
    }

    const [items, total] = await qb.getManyAndCount();
    const categories = await this.categoryRepo.find();

    const enrichedItems = items.map((f) => {
      const cat = categories.find((c) => Number(c.maDanhMuc) === Number(f.maDanhMuc));
      return {
        ...f,
        tenDanhMuc: cat ? cat.tenDanhMuc : null,
      };
    });

    return { items: enrichedItems, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async updateFood(maMonAn: number, data: Partial<MonAnModel>) {
    const food = await this.foodRepo.findOne({ where: { maMonAn } });
    if (!food) throw new Error('Không tìm thấy món ăn');

    const nextQty = data.soLuongMon !== undefined ? Number(data.soLuongMon) : Number(food.soLuongMon || 0);
    let nextStatus = data.trangThaiMon || food.trangThaiMon || (nextQty > 0 ? 'DANG_BAN' : 'HET_HANG');
    if (nextQty <= 0 && nextStatus !== 'TAM_NGUNG') {
      nextStatus = 'HET_HANG';
    } else if (nextQty > 0 && nextStatus === 'HET_HANG') {
      nextStatus = 'DANG_BAN';
    }

    Object.assign(food, data, {
      soLuongMon: nextQty,
      trangThaiMon: nextStatus,
    });
    return await this.foodRepo.save(food);
  }
}
