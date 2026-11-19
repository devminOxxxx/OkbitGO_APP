import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class OpenSourceLicenseScreen extends StatefulWidget {
  const OpenSourceLicenseScreen({Key? key}) : super(key: key);

  @override
  State<OpenSourceLicenseScreen> createState() =>
      _OpenSourceLicenseScreenState();
}

class _OpenSourceLicenseScreenState extends State<OpenSourceLicenseScreen> {
  // 앱에서 사용하는 패키지 목록
  final List<Package> packages = [
    Package(
      name: 'Flutter',
      version: '3.19.0',
      license: 'BSD-3-Clause',
      copyright: '© 2014-2025 Google LLC',
      description:
          'Flutter는 Google에서 개발한 UI 툴킷으로, 단일 코드베이스에서 모바일, 웹, 데스크톱 앱을 구축할 수 있습니다.',
      homepage: 'https://flutter.dev',
    ),
    Package(
      name: 'Provider',
      version: '6.1.1',
      license: 'MIT',
      copyright: '© 2019 Remi Rousselet',
      description: 'Provider는 Flutter 앱에서 상태 관리를 위한 라이브러리입니다.',
      homepage: 'https://pub.dev/packages/provider',
    ),
    Package(
      name: 'Intl',
      version: '0.19.0',
      license: 'BSD-3-Clause',
      copyright: '© 2013 The Dart project authors',
      description: 'Intl 패키지는 국제화 및 지역화 기능을 제공합니다.',
      homepage: 'https://pub.dev/packages/intl',
    ),
    Package(
      name: 'Firebase Core',
      version: '2.32.0',
      license: 'Apache-2.0',
      copyright: '© 2022 Google LLC',
      description: 'Firebase Core는 Firebase 서비스를 사용하기 위한 기본 패키지입니다.',
      homepage: 'https://pub.dev/packages/firebase_core',
    ),
    Package(
      name: 'Firebase Auth',
      version: '4.20.0',
      license: 'Apache-2.0',
      copyright: '© 2022 Google LLC',
      description: 'Firebase Auth는 Firebase 인증 서비스를 사용하기 위한 패키지입니다.',
      homepage: 'https://pub.dev/packages/firebase_auth',
    ),
    Package(
      name: 'Cloud Firestore',
      version: '4.17.5',
      license: 'Apache-2.0',
      copyright: '© 2022 Google LLC',
      description: 'Cloud Firestore는 Firebase의 NoSQL 클라우드 데이터베이스입니다.',
      homepage: 'https://pub.dev/packages/cloud_firestore',
    ),
    Package(
      name: 'Table Calendar',
      version: '3.1.3',
      license: 'Apache-2.0',
      copyright: '© 2019 Aleksander Woźniak',
      description: 'Table Calendar는 Flutter용 고도로 사용자 정의 가능한 달력 위젯입니다.',
      homepage: 'https://pub.dev/packages/table_calendar',
    ),
    Package(
      name: 'URL Launcher',
      version: '6.2.5',
      license: 'BSD-3-Clause',
      copyright: '© 2017 The Chromium Authors',
      description: 'URL Launcher는 모바일 플랫폼에서 URL을 실행하기 위한 Flutter 플러그인입니다.',
      homepage: 'https://pub.dev/packages/url_launcher',
    ),
    Package(
      name: 'Shared Preferences',
      version: '2.4.6',
      license: 'BSD-3-Clause',
      copyright: '© 2017 The Chromium Authors',
      description: 'Shared Preferences는 간단한 데이터를 디스크에 저장하기 위한 Flutter 플러그인입니다.',
      homepage: 'https://pub.dev/packages/shared_preferences',
    ),
    Package(
      name: 'UUID',
      version: '4.3.3',
      license: 'MIT',
      copyright: '© 2021 Yulian Kuncheff',
      description: 'UUID 패키지는 RFC4122 표준을 준수하는 UUID를 생성합니다.',
      homepage: 'https://pub.dev/packages/uuid',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          kOpenSourceLicenseTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: kSpacing),
            ...packages
                .map((package) => _buildPackageItem(context, package))
                .toList(),
            const SizedBox(height: kSpacing * 2),
            Center(
              child: Text(
                '© $kAppYear 옥빛GO!',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSpacing),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.code_outlined,
                color: kAccentColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '오픈소스 라이선스',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '옥빛GO! 앱은 다양한 오픈소스 소프트웨어를 활용하여 개발되었습니다. 각 오픈소스 소프트웨어의 라이선스 정보를 확인하실 수 있습니다.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageItem(BuildContext context, Package package) {
    return Container(
      margin: const EdgeInsets.only(bottom: kSpacing),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            package.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'v${package.version}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(kSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (package.description.isNotEmpty) ...[
                    Text(
                      package.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    '라이선스: ${package.license}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '저작권: ${package.copyright}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  if (package.homepage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          '홈페이지: ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          package.homepage,
                          style: const TextStyle(
                            color: kAccentColor,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Package {
  final String name;
  final String version;
  final String license;
  final String copyright;
  final String description;
  final String homepage;

  Package({
    required this.name,
    required this.version,
    required this.license,
    required this.copyright,
    this.description = '',
    this.homepage = '',
  });
}
