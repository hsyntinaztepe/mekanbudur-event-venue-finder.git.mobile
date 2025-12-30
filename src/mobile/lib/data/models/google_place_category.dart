class GooglePlaceCategory {
  static const String weddingHalls = 'weddingHalls';
  static const String bakeries = 'bakeries';
  static const String photographers = 'photographers';

  static const List<String> values = [
    weddingHalls,
    bakeries,
    photographers,
  ];

  static const Map<String, String> _labels = {
    weddingHalls: 'Düğün Salonları',
    bakeries: 'Pastaneler',
    photographers: 'Fotoğrafçılar',
  };

  static const Map<String, String> _endpoints = {
    weddingHalls: '/google-places/golbasi',
    bakeries: '/google-places/bakeries',
    photographers: '/google-places/photographers',
  };

  static String labelFor(String category) => _labels[category] ?? category;

  static String? endpointFor(String category) => _endpoints[category];
}
