# iOS-projekt

Link GitHub: https://github.com/koszatree/iOS-projekt.git

Projekt wykorzystuje serwer Tomcat jako agregator serwisów oraz aplikację natywną zaprojektowaną w Flutter.

Serwer pracuje na adresie IP 185.25.148.193, aby połączyć się z serwerem Tomcat, należy ustawić tunel SSH 127.0.0.1:8080. Wykorzystana wersja Java 21.
Uwierzytelnienie do serwera następoje poprzez zalogowanie na konto `root`.

Aplikacja jest oparta o Flutter 3.41.9, Dart 3.11.5, DevTools 2.52.2
Po pobraniu aplikacji należy skorzystać z polecenia `flutter pub get` aby pobrać i zaktualizować pakiety z pubspec.yaml. Uruchomienie aplikacji odbywa się poprzez polecenie `flutter run`

Uruchomienie testów:
1. Test jednostkowy - `flutter test test/unit/unit_test.dart` - sprawdza poprawność budowania SOAP body dla getMapTile
2. Test UI - `flutter test test/widget/widget_test.dart` - sprawdza kliknięcie pola wyszukiwania i wpisanie tekstu
