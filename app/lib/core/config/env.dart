class Env {
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://common-pantry-api.onrender.com',
  );
}
