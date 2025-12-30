import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/geo_api_client.dart';
import 'core/router.dart';
import 'data/services/auth_service.dart';
import 'data/services/listing_service.dart';
import 'data/services/bid_service.dart';
import 'data/services/vendor_service.dart';
import 'data/services/place_service.dart';
import 'data/services/google_places_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/listing_provider.dart';
import 'presentation/providers/bid_provider.dart';
import 'presentation/providers/vendor_provider.dart';
import 'presentation/providers/place_provider.dart';
import 'presentation/providers/google_places_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final authService = AuthService(apiClient);

    final listingService = ListingService(apiClient);
    final bidService = BidService(apiClient);
    final vendorService = VendorService(apiClient);
    final geoApiClient = GeoApiClient();
    final placeService = PlaceService(geoApiClient);
    final googlePlacesService = GooglePlacesService(geoApiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => ListingProvider(listingService)),
        ChangeNotifierProvider(create: (_) => BidProvider(bidService)),
        ChangeNotifierProvider(create: (_) => VendorProvider(vendorService)),
        ChangeNotifierProvider(create: (_) => PlaceProvider(placeService)),
        ChangeNotifierProvider(
          create: (_) => GooglePlacesProvider(googlePlacesService),
        ),
      ],
      child: MaterialApp.router(
        title: 'MekanBudur',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0F1116),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF151922),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardColor: const Color(0xFF1B1F2A),
          textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1F2533),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF6C63FF)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          listTileTheme: const ListTileThemeData(
            iconColor: Colors.white70,
            textColor: Colors.white,
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}
