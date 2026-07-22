class IdentityProvider {
  const IdentityProvider({
    required this.publicID,
    required this.slug,
    required this.name,
    this.type = 'oidc',
    this.logoURL = '',
    this.loginEnabled = true,
  });

  final String publicID;
  final String slug;
  final String name;
  final String type;
  final String logoURL;
  final bool loginEnabled;

  factory IdentityProvider.fromApi(Map<String, dynamic> json) {
    return IdentityProvider(
      publicID: '${json['publicID'] ?? json['id'] ?? ''}',
      slug: '${json['slug'] ?? json['publicID'] ?? ''}',
      name: '${json['name'] ?? ''}',
      type: '${json['type'] ?? 'oidc'}',
      logoURL: '${json['logoURL'] ?? ''}',
      loginEnabled: json['loginEnabled'] != false,
    );
  }
}
