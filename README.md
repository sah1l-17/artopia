# Artopia 🎨

**Artopia** is a Flutter-based e-commerce application designed for artists and art enthusiasts to showcase, sell, and purchase unique artworks. The platform connects artists with potential buyers, creating a vibrant marketplace for original paintings, digital art, sculptures, and more.

## 🚀 Features

- 🖼️ Browse and purchase artwork from talented artists
- 🔍 Search and filter artworks by style, price, artist, and medium
- 👤 User profiles for artists and collectors
- 🛒 Secure checkout and payment processing
- ❤️ Save favorite artworks and follow artists

## 📁 Project Structure

```
artopia/
├── android/        # Android configuration
├── ios/            # iOS configuration
├── lib/            # Main Flutter code

├── assets/         # Images, fonts, and other assets
├── test/           # Unit and widget tests
└── README.md       # Project documentation
```

## 🔧 Installation and Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/sah1l-17/artopia.git
   cd artopia
   ```

2. **Install Flutter**

   Make sure you have Flutter installed. If not, follow the [official installation guide](https://flutter.dev/docs/get-started/install).

3. **Get dependencies**

   ```bash
   flutter pub get
   ```

4. **Run the app**

   ```bash
   flutter run
   ```

## 📱 Supported Platforms

- Android
- Web (experimental)

## 🛠️ Technologies Used

- **Frontend:**
  - Flutter
  - Dart
  - Provider/Bloc for state management
  - Flutter Material Design

- **Backend:**
  - Firebase (Authentication, Firestore)


## 🔒 Security and Privacy

- All user data is encrypted and securely stored
- User authentication is secured with Firebase Authentication

## ⚙️ Configuration

The app requires the following environment variables to be set:
- `FIREBASE_API_KEY`
- Create a `config.dart` file based on the provided `config.example.dart` template

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an Issue to suggest improvements or add new features.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

Sahil Ansari – [@sah1l-17](https://github.com/sah1l-17)
