const { AppDataSource } = require('./dist/config/database');

const operatingHours = JSON.stringify({
  mon: { open: true, from: '07:00', to: '22:00' },
  tue: { open: true, from: '07:00', to: '22:00' },
  wed: { open: true, from: '07:00', to: '22:00' },
  thu: { open: true, from: '07:00', to: '22:00' },
  fri: { open: true, from: '07:00', to: '22:00' },
  sat: { open: true, from: '07:00', to: '23:00' },
  sun: { open: true, from: '07:00', to: '23:00' }
});

const storesData = [
  {
    tenquan: 'Bánh Mì Huỳnh Hoa - Lê Thị Riêng',
    diachi: '26 Lê Thị Riêng, P. Bến Thành, Quận 1, TP.HCM',
    lat: 10.7712,
    lng: 106.6917,
    sdt: '02839250885',
    danhmuc: 'Bánh Mì & Ăn Nhẹ',
    dishes: [
      { name: 'Bánh Mì Đặc Biệt Huỳnh Hoa', price: 68000, desc: 'Bánh mì đầy ắp 5 loại thịt nguội, pate bơ tươi gia truyền giòn rụm' },
      { name: 'Bánh Mì Pate Chả Lụa', price: 45000, desc: 'Bánh mì giòn nóng với pate béo ngậy và chả lụa loại 1' },
      { name: 'Bánh Mì Xíu Mại Trứng Muối', price: 50000, desc: 'Xíu mại sốt cà chua đậm đà kèm trứng muối bùi béo' },
      { name: 'Bánh Mì Thịt Nguội Bơ Tươi', price: 48000, desc: 'Thịt nguội cao cấp kèm dưa leo, đồ chua giòn ngọt' },
      { name: 'Trà Tắc Hạt Chia Mát Lạnh', price: 25000, desc: 'Trà tắc thanh mát giải nhiệt kèm hạt chia bổ dưỡng' }
    ]
  },
  {
    tenquan: 'Phở Hòa Pasteur - Quận 1',
    diachi: '260C Pasteur, P. Võ Thị Sáu / P. 8, Quận 1, TP.HCM',
    lat: 10.7852,
    lng: 106.6896,
    sdt: '02838297943',
    danhmuc: 'Phở & Bún Mì',
    dishes: [
      { name: 'Phở Tái Nạm Gầu Bò', price: 70000, desc: 'Nước dùng ninh xương 12 tiếng thơm ngát thảo mộc với bò tươi mềm' },
      { name: 'Phở Bò Viên Đặc Biệt', price: 65000, desc: 'Bò viên giòn sần sật kèm phở mềm mượt thơm ngon' },
      { name: 'Phở Gà Xé Lá Chanh', price: 60000, desc: 'Gà ta thả vườn thịt chắc ngọt rắc lá chanh tươi thái sợi' },
      { name: 'Quẩy Giòn Nóng', price: 15000, desc: 'Đĩa 2 quẩy chiên vàng ruộm ăn kèm phở nóng hổi' },
      { name: 'Nước Mía Tươi Tắc', price: 20000, desc: 'Nước mía ép tươi tại chỗ chua ngọt sảng khoái' }
    ]
  },
  {
    tenquan: 'Cơm Tấm Mộc - Mạc Thị Bưởi',
    diachi: '85 Mạc Thị Bưởi, P. Bến Nghé, Quận 1, TP.HCM',
    lat: 10.7745,
    lng: 106.7042,
    sdt: '02838248561',
    danhmuc: 'Cơm & Món Mặn',
    dishes: [
      { name: 'Cơm Tấm Sườn Bì Chả Trứng', price: 65000, desc: 'Sườn nướng mật ong vàng óng kèm bì thính, chả trứng hấp mềm' },
      { name: 'Cơm Tấm Ba Rọi Nướng Muối Ớt', price: 58000, desc: 'Thịt ba rọi ướp muối ớt nướng than hoa thơm lừng' },
      { name: 'Cơm Tấm Đùi Gà Nướng Mật Ong', price: 55000, desc: 'Đùi gà góc tư nướng mềm ngọt ngấm vị mật ong' },
      { name: 'Canh Khổ Qua Nhồi Thịt', price: 25000, desc: 'Tô canh khổ qua thanh nhiệt nhân thịt băm mộc nhĩ' },
      { name: 'Trà Atiso Đỏ Hạt Sen', price: 28000, desc: 'Trà hoa atiso đỏ chua dịu thanh lọc cơ thể' }
    ]
  },
  {
    tenquan: 'Bún Đậu Mắm Tôm Cô Khàn - Cống Quỳnh',
    diachi: '102/26 Cống Quỳnh, P. Phạm Ngũ Lão, Quận 1, TP.HCM',
    lat: 10.7678,
    lng: 106.6879,
    sdt: '0908882468',
    danhmuc: 'Đặc Sản Bắc',
    dishes: [
      { name: 'Mẹt Bún Đậu Thập Cẩm Đầy Đủ', price: 68000, desc: 'Đậu mơ rán giòn, thịt bắp giò luộc, chả cốm, nem rán, dồi sụn' },
      { name: 'Bún Đậu Chả Cốm Nem Rán', price: 55000, desc: 'Mẹt vừa gồm bún lá, đậu mơ béo và chả cốm dẻo thơm' },
      { name: 'Bún Chả Hà Nội Truyền Thống', price: 60000, desc: 'Chả viên và chả miếng nướng than hoa ngâm nước mắm đu đủ' },
      { name: 'Chả Cốm Mễ Trì Chiên Giòn', price: 35000, desc: 'Đĩa chả cốm chiên vàng giòn rụm bên ngoài dẻo ngọt bên trong' },
      { name: 'Nước Mơ Ngâm Hà Nội', price: 25000, desc: 'Mơ chùa Hương ngâm đường phèn chua ngọt mát lạnh' }
    ]
  },
  {
    tenquan: 'Hủ Tiếu Nam Vang Thành Đạt - Cô Bắc',
    diachi: '22 Cô Bắc, P. Cầu Ông Lãnh, Quận 1, TP.HCM',
    lat: 10.7635,
    lng: 106.6968,
    sdt: '0973686868',
    danhmuc: 'Hủ Tiếu & Mì Xào',
    dishes: [
      { name: 'Hủ Tiếu Nam Vang Khô Đặc Biệt', price: 65000, desc: 'Sợi hủ tiếu dai trộn sốt tương tỏi ớt kèm tôm tươi, tim cật, thịt băm' },
      { name: 'Hủ Tiếu Nam Vang Nước Tôm Mực', price: 62000, desc: 'Nước lèo trong ngọt thanh từ xương ống và củ cải trắng' },
      { name: 'Hủ Tiếu Xương Ống Tủy Béo', price: 58000, desc: 'Tô hủ tiếu kèm khúc xương ống to nhiều tủy béo ngọt lịm' },
      { name: 'Bánh Canh Bột Gạo Tôm Thịt', price: 52000, desc: 'Sợi bánh canh bột gạo mềm mại nước dùng đậm đà' },
      { name: 'Sữa Bắp Nếp Tươi Nấu Mới', price: 22000, desc: 'Sữa bắp nếp nguyên chất ngọt thanh béo ngậy' }
    ]
  },
  {
    tenquan: 'The Alley Trà Sữa - Hồ Tùng Mậu',
    diachi: '68 Hồ Tùng Mậu, P. Bến Nghé, Quận 1, TP.HCM',
    lat: 10.7728,
    lng: 106.7049,
    sdt: '02838210388',
    danhmuc: 'Trà Sữa & Đồ Uống',
    dishes: [
      { name: 'Sữa Tươi Trân Châu Đường Đen', price: 65000, desc: 'Trân châu đường đen nóng dẻo kết hợp sữa tươi Meiji thanh trùng' },
      { name: 'Trà Sữa Mầm Cây Hoàng Gia', price: 58000, desc: 'Trà sữa đậm vị phủ lớp vụn bánh oreo bùi thơm lạ miệng' },
      { name: 'Lục Trà Chanh Leo Macchiato', price: 52000, desc: 'Lục trà hoa nhài chanh leo kèm lớp kem sữa mặn béo ngậy' },
      { name: 'Trà Đào Cam Sả Tươi', price: 48000, desc: 'Miếng đào giòn ngọt thơm lừng hương sả và cam tươi' },
      { name: 'Bánh Mì Que Phô Mai Nướng', price: 30000, desc: 'Bánh mì que giòn tan nhân phô mai béo ngậy kéo sợi' }
    ]
  },
  {
    tenquan: 'Bún Chả 145 - Bùi Viện',
    diachi: '145 Bùi Viện, P. Phạm Ngũ Lão, Quận 1, TP.HCM',
    lat: 10.7675,
    lng: 106.6924,
    sdt: '02838373474',
    danhmuc: 'Bún & Bánh Canh',
    dishes: [
      { name: 'Bún Chả Nướng Than Hoa Phố Tây', price: 60000, desc: 'Thịt ba chỉ ướp gia vị đậm đà nướng than hoa thơm nức mũi' },
      { name: 'Nem Cua Bể Hải Phòng', price: 45000, desc: 'Nem vuông nhân thịt cua bể tươi giòn rụm chấm mắm giấm ớt' },
      { name: 'Chả Que Nướng Lá Lốt Thơm Nức', price: 40000, desc: 'Thịt bò cuốn lá lốt nướng xém cạnh ăn kèm bún tươi' },
      { name: 'Bún Nem Nướng Hà Nội', price: 55000, desc: 'Phần bún kèm nem rán giòn tan rau sống tươi sạch' },
      { name: 'Trà Chanh Phố Cổ Hà Nội', price: 20000, desc: 'Trà lài đậm vị chanh tươi mát lạnh sảng khoái' }
    ]
  },
  {
    tenquan: 'Gà Nướng Ò Ó O - Đinh Tiên Hoàng',
    diachi: '111 Đinh Tiên Hoàng, P. Đa Kao, Quận 1, TP.HCM',
    lat: 10.7892,
    lng: 106.6987,
    sdt: '1900636730',
    danhmuc: 'Gà Rán & Đồ Nướng',
    dishes: [
      { name: 'Gà Nướng Ớt Cay Địa Ngục (Nửa Con)', price: 75000, desc: 'Gà ta nướng da giòn sốt ớt đỏ cay nồng quyến rũ' },
      { name: 'Gà Nướng Tiêu Rừng Tây Bắc (Nửa Con)', price: 75000, desc: 'Vị cay the dịu của hạt tiêu rừng mắc khén thơm lừng' },
      { name: 'Cơm Lam Ống Tre Chấm Muối Vừng', price: 25000, desc: 'Gạo nếp nương nướng trong ống tre dẻo ngọt thơm phức' },
      { name: 'Xôi Chiên Phồng Dẻo Giòn', price: 30000, desc: 'Miếng xôi chiên vàng giòn rụm bên ngoài dẻo mềm bên trong' },
      { name: 'Salad Rong Biển Sốt Mè Rang', price: 35000, desc: 'Rong biển giòn ngọt kèm rau tươi sốt mè béo bùi thanh nhẹ' }
    ]
  },
  {
    tenquan: 'Bánh Canh Cua Trần Khắc Chân',
    diachi: '87 Trần Khắc Chân, P. Tân Định, Quận 1, TP.HCM',
    lat: 10.7925,
    lng: 106.6885,
    sdt: '0903338787',
    danhmuc: 'Bánh Canh & Hủ Tiếu',
    dishes: [
      { name: 'Bánh Canh Cua Giò Heo Đầy Đủ', price: 55000, desc: 'Nước dùng sền sệt ngọt thanh từ gạch cua kèm giò heo béo mềm' },
      { name: 'Bánh Canh Cua Tôm Tươi Thịt Nạc', price: 50000, desc: 'Thịt cua xé và tôm sú tươi ngon ngọt tự nhiên' },
      { name: 'Bánh Canh Chả Cua Huyết Nóng', price: 45000, desc: 'Chả cua hấp béo ngọt kèm huyết mềm mượt' },
      { name: 'Quẩy Nóng Giòn Ăn Kèm', price: 12000, desc: 'Quẩy giòn rụm chấm nước sốt bánh canh cua cực bắt vị' },
      { name: 'Nước Sâm Rong Biển Mía Lau', price: 18000, desc: 'Nấu từ mía lau lá dứa và rong biển ngọt thanh mát gan' }
    ]
  },
  {
    tenquan: 'Trà Trái Cây & Bánh Morico - Lê Thánh Tôn',
    diachi: '30 Lê Thánh Tôn, P. Bến Nghé, Quận 1, TP.HCM',
    lat: 10.7794,
    lng: 106.7032,
    sdt: '02838277898',
    danhmuc: 'Bánh Ngọt & Trà Nhật',
    dishes: [
      { name: 'Trà Xanh Matcha Latte Nhật Bản', price: 62000, desc: 'Bột matcha Uji nguyên chất đánh bọt mịn hòa quyện sữa tươi thơm ngậy' },
      { name: 'Trà Bưởi Hồng Nhiệt Đới', price: 55000, desc: 'Trà xanh lài kết hợp tép bưởi hồng tươi thanh mát ngọt dịu' },
      { name: 'Bánh Mousse Dâu Tây Tươi', price: 52000, desc: 'Lớp mousse mịn màng kèm mứt dâu tây tươi chua ngọt tinh tế' },
      { name: 'Bánh Crepe Ngàn Lớp Matcha', price: 58000, desc: 'Từng lớp crepe mỏng tang xen kẽ kem tươi trà xanh thanh nhẹ' },
      { name: 'Parfait Trái Cây Kem Sữa Hokkaido', price: 65000, desc: 'Kem tươi Hokkaido kèm dâu tây, kiwi và vụn bánh giòn' }
    ]
  }
];

async function run() {
  await AppDataSource.initialize();
  const queryRunner = AppDataSource.createQueryRunner();
  await queryRunner.connect();
  await queryRunner.startTransaction();

  try {
    let insertedStoreCount = 0;
    let insertedDishCount = 0;

    for (const s of storesData) {
      const storeRes = await queryRunner.query(
        'INSERT INTO cuahang (tenquan, diachi, trangthai, lat, lng, sdt, giohoatdong, thoigianchuanbi, cochodattruoc, tienich, danhgiatrungbinh, soluongdanhgia, is_deleted, mota, danhmuc) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15) RETURNING maquan',
        [
          s.tenquan,
          s.diachi,
          'mở cửa',
          s.lat,
          s.lng,
          s.sdt,
          operatingHours,
          15,
          true,
          'Có chỗ ngồi, Máy lạnh, Wifi miễn phí',
          4.80,
          15,
          false,
          '[TEST_Q1] Quán ăn thử nghiệm khu vực Quận 1',
          s.danhmuc
        ]
      );

      const maQuan = storeRes[0].maquan;
      insertedStoreCount++;

      for (const d of s.dishes) {
        await queryRunner.query(
          'INSERT INTO monan (maquan, tenmonan, giamonan, soluongmon, img, diemdanhgiatb, soluotdanhgia, trangthaimon, mota, dactinh) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)',
          [
            maQuan,
            d.name,
            d.price,
            20,
            null,
            4.80,
            12,
            'DANG_BAN',
            d.desc,
            'Món nóng, Chế biến nhanh'
          ]
        );
        insertedDishCount++;
      }
    }

    await queryRunner.commitTransaction();
    console.log(`SUCCESS: Đã chèn thành công ${insertedStoreCount} quán ăn và ${insertedDishCount} món ăn vào database!`);
    await queryRunner.release();
    process.exit(0);
  } catch (err) {
    await queryRunner.rollbackTransaction();
    await queryRunner.release();
    console.error('ERROR chèn dữ liệu:', err);
    process.exit(1);
  }
}

run();
