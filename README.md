# hasanaecommerce Android App

A Flutter-based Android e-commerce application shell for hasanaecommerce.

## Brand
- Name: hasanaecommerce
- Website: https://hasanaecommerce.myboneek.com/
- Payment: Cash on Delivery
- Platform: Android
- Colors: Navy / Orange / White

## Included
- Premium mobile-first UI
- Home
- Categories
- Search
- Product details
- Cart
- Checkout
- COD order flow
- Orders
- Wishlist
- Account
- Logo / splash branding
- Responsive layouts
- Local cart/wishlist persistence
- API-ready product service

## Important
The supplied website currently exposes only a "Loading store..." shell to external page retrieval, so no verified product/catalog API could be discovered automatically. The app therefore does NOT invent products or reviews.

To connect real products/orders, configure the API endpoint in:
`lib/services/api_service.dart`

Expected endpoints can be adapted once the MyBoneek backend/API details are available.

## Build
Install Flutter, then:
```bash
flutter pub get
flutter run
flutter build apk --release
```

The generated APK will be under:
`build/app/outputs/flutter-apk/app-release.apk`
