class IranCity {
  final String name;
  final double lat;
  final double lng;

  const IranCity({
    required this.name,
    required this.lat,
    required this.lng,
  });
}

class IranCities {
  static const List<IranCity> all = [
    IranCity(name: 'تهران', lat: 35.6892, lng: 51.3890),
    IranCity(name: 'کرج', lat: 35.8400, lng: 50.9391),
    IranCity(name: 'مشهد', lat: 36.2970, lng: 59.6062),
    IranCity(name: 'اصفهان', lat: 32.6546, lng: 51.6680),
    IranCity(name: 'شیراز', lat: 29.5918, lng: 52.5837),
    IranCity(name: 'تبریز', lat: 38.0962, lng: 46.2738),
    IranCity(name: 'اهواز', lat: 31.3183, lng: 48.6706),
    IranCity(name: 'قم', lat: 34.6416, lng: 50.8746),
    IranCity(name: 'کرمانشاه', lat: 34.3142, lng: 47.0650),
    IranCity(name: 'ارومیه', lat: 37.5527, lng: 45.0761),
    IranCity(name: 'رشت', lat: 37.2808, lng: 49.5832),
    IranCity(name: 'زاهدان', lat: 29.4963, lng: 60.8629),
    IranCity(name: 'همدان', lat: 34.7983, lng: 48.5148),
    IranCity(name: 'کرمان', lat: 30.2839, lng: 57.0834),
    IranCity(name: 'یزد', lat: 31.8974, lng: 54.3569),
    IranCity(name: 'اردبیل', lat: 38.2498, lng: 48.2933),
    IranCity(name: 'بندرعباس', lat: 27.1865, lng: 56.2808),
    IranCity(name: 'اراک', lat: 34.0954, lng: 49.7013),
    IranCity(name: 'اسلام‌شهر', lat: 35.5446, lng: 51.2302),
    IranCity(name: 'زنجان', lat: 36.6736, lng: 48.4787),
    IranCity(name: 'سنندج', lat: 35.3219, lng: 46.9862),
    IranCity(name: 'قزوین', lat: 36.2797, lng: 50.0049),
    IranCity(name: 'خرم‌آباد', lat: 33.4878, lng: 48.3558),
    IranCity(name: 'گرگان', lat: 36.8456, lng: 54.4393),
    IranCity(name: 'ساری', lat: 36.5633, lng: 53.0601),
    IranCity(name: 'شهرکرد', lat: 32.3256, lng: 50.8644),
    IranCity(name: 'بوشهر', lat: 28.9234, lng: 50.8203),
    IranCity(name: 'بجنورد', lat: 37.4750, lng: 57.3333),
    IranCity(name: 'بیرجند', lat: 32.8649, lng: 59.2262),
    IranCity(name: 'ایلام', lat: 33.6374, lng: 46.4227),
    IranCity(name: 'یاسوج', lat: 30.6682, lng: 51.5880),
    IranCity(name: 'سمنان', lat: 35.5769, lng: 53.3953),
    IranCity(name: 'کیش', lat: 26.5321, lng: 53.9868),
    IranCity(name: 'قشم', lat: 26.9581, lng: 56.2719),
    IranCity(name: 'چابهار', lat: 25.2919, lng: 60.6430),
    IranCity(name: 'لاهیجان', lat: 37.2070, lng: 50.0041),
    IranCity(name: 'بابل', lat: 36.5513, lng: 52.6801),
    IranCity(name: 'آمل', lat: 36.4697, lng: 52.3507),
    IranCity(name: 'کاشان', lat: 33.9850, lng: 51.4100),
    IranCity(name: 'نجف‌آباد', lat: 32.6342, lng: 51.3668),
    IranCity(name: 'سبزوار', lat: 36.2152, lng: 57.6688),
    IranCity(name: 'نیشابور', lat: 36.2141, lng: 58.7961),
    IranCity(name: 'دزفول', lat: 32.3831, lng: 48.4236),
    IranCity(name: 'آبادان', lat: 30.3473, lng: 48.2934),
    IranCity(name: 'خرمشهر', lat: 30.4256, lng: 48.1891),
    IranCity(name: 'مراغه', lat: 37.3891, lng: 46.2370),
    IranCity(name: 'مرودشت', lat: 29.8742, lng: 52.8025),
    IranCity(name: 'شاهرود', lat: 36.4182, lng: 54.9763),
    IranCity(name: 'ساوه', lat: 35.0213, lng: 50.3566),
    IranCity(name: 'ملارد', lat: 35.6650, lng: 50.9781),
  ];

  static IranCity? findByName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final n = name.trim();
    for (final c in all) {
      if (c.name == n) return c;
    }
    return null;
  }
}