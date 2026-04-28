class EnvConfig {
  final String baseUrl;
  final String environmentName;

  EnvConfig({
    required this.baseUrl,
    required this.environmentName,
  });

  static EnvConfig dev = EnvConfig(
    baseUrl: 'http://127.0.0.1:5000/api',
    environmentName: 'Development',
  );

  static EnvConfig staging = EnvConfig(
    baseUrl: 'https://staging-api.medicheckai.com/api',
    environmentName: 'Staging',
  );

  static EnvConfig prod = EnvConfig(
    baseUrl: 'https://api.medicheckai.com/api',
    environmentName: 'Production',
  );

  // Default to dev for now
  static EnvConfig current = dev;

  static void setEnvironment(EnvConfig config) {
    current = config;
  }
}
