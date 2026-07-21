import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:millennium_capital/game/dynamic_news.dart';

void main() {
  const request = DynamicNewsRequest(
    year: 2007,
    companyName: '애플',
    action: '경영권을 인수하고 혁신형 CEO를 선임함',
    megaTrend: '스마트폰 시대의 도래',
  );

  test('동적 뉴스 JSON 응답을 안전하게 해석한다', () async {
    final client = DynamicNewsClient(
      endpoint: Uri.parse('https://example.test/api/news'),
      client: MockClient((incoming) async {
        expect(incoming.method, 'POST');
        expect(jsonDecode(incoming.body), request.toJson());
        return http.Response(
          jsonEncode({
            'headline': '애플, 새 경영진과 모바일 승부수',
            'content': '새 경영진이 통합형 휴대기기 전략을 밝혔다. 시장은 실행력에 주목하고 있다.',
            'marketSentiment': 'POSITIVE',
            'stockImpactScore': 18.5,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(client.close);

    final article = await client.generate(request);
    expect(article?.headline, contains('애플'));
    expect(article?.marketSentiment, 'POSITIVE');
    expect(article?.stockImpactScore, 18.5);
  });

  test('서버 오류가 나면 기존 신문을 위해 null로 폴백한다', () async {
    final client = DynamicNewsClient(
      endpoint: Uri.parse('https://example.test/api/news'),
      client: MockClient((_) async => http.Response('unavailable', 503)),
    );
    addTearDown(client.close);

    expect(await client.generate(request), isNull);
  });

  test('허용 범위를 벗어난 영향 점수는 거부한다', () {
    expect(
      () => DynamicNewsArticle.fromJson({
        'headline': '제목',
        'content': '본문',
        'marketSentiment': 'POSITIVE',
        'stockImpactScore': 80,
      }),
      throwsFormatException,
    );
  });
}
