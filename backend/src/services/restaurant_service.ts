import { AppDataSource } from '../config/database';
import { CuaHangModel } from '../models/cua_hang_model';
import { DanhMucModel } from '../models/danh_muc_model';
import { MonAnModel } from '../models/mon_an_model';

export class RestaurantService {
  private cuaHangRepo = AppDataSource.getRepository(CuaHangModel);
  private danhMucRepo = AppDataSource.getRepository(DanhMucModel);
  private monAnRepo = AppDataSource.getRepository(MonAnModel);

  async getAllRestaurants() {
    return await this.cuaHangRepo.find();
  }

  async getRestaurantById(maQuan: number) {
    return await this.cuaHangRepo.findOne({
      where: { maQuan },
    });
  }

  async getAllCategories() {
    const categories = await this.danhMucRepo.find();
    const items = await this.monAnRepo.find();
    return categories.map((cat) => {
      const catItems = items.filter((item) => item.maDanhMuc === cat.maDanhMuc);
      return {
        maDanhMuc: cat.maDanhMuc,
        id: cat.maDanhMuc,
        tenDanhMuc: cat.tenDanhMuc,
        name: cat.tenDanhMuc,
        maQuan: cat.maQuan,
        soLuongMon: catItems.length,
        itemsCount: catItems.length,
      };
    });
  }

  async getRestaurantMenu(maQuan: number) {
    const res = await this.cuaHangRepo.findOne({
      where: { maQuan },
    });

    const categories = await this.danhMucRepo.find({
      where: { maQuan },
    });

    const items = await this.monAnRepo.find({
      where: { maQuan },
    });

    return categories.map((cat) => {
      const catItems = items.filter((item) => item.maDanhMuc === cat.maDanhMuc);
      return {
        id: cat.maDanhMuc,
        name: cat.tenDanhMuc,
        maQuan: cat.maQuan,
        lat: res?.lat ? Number(res.lat) : 10.762622,
        lng: res?.lng ? Number(res.lng) : 106.682029,
        tenQuan: res?.tenQuan || '',
        itemsCount: catItems.length,
        items: catItems.map((i) => ({
          id: i.maMonAn,
          name: i.tenMonAn,
          price: Number(i.giaMonAn),
          quantity: i.soLuongMon,
          image: i.img || '',
          rating: Number(i.diemDanhGiaTB || 5.0),
          ratingCount: i.soLuotDanhGia || 0,
          maQuan: cat.maQuan,
          lat: res?.lat ? Number(res.lat) : 10.762622,
          lng: res?.lng ? Number(res.lng) : 106.682029,
          tenQuan: res?.tenQuan || '',
        })),
      };
    });
  }
}
