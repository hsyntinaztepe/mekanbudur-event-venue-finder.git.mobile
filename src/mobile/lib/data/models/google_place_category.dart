class GooglePlaceCategory {
  static const String weddingHalls = 'weddingHalls';
  static const String bakeries = 'bakeries';
  static const String photographers = 'photographers';
  static const String florists = 'florists';
  static const String music = 'music';

  static const List<String> values = [
    weddingHalls,
    bakeries,
    photographers,
    florists,
    music,
  ];

  static const Map<String, String> _labels = {
    weddingHalls: 'Düğün Salonları',
    bakeries: 'Pastaneler',
    photographers: 'Fotoğrafçılar',
    florists: 'Çiçekçiler',
    music: 'Müzik / DJ',
  };

  static const Map<String, String> _endpoints = {
    weddingHalls: '/google-places/golbasi',
    bakeries: '/google-places/bakeries',
    photographers: '/google-places/photographers',
    florists: '/google-places/florists',
    music: '/google-places/music',
  };

  static String labelFor(String category) => _labels[category] ?? category;

  static String? endpointFor(String category) => _endpoints[category];
}
