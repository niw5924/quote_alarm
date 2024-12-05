import 'package:flutter/material.dart';
import 'package:flutter_alarm_app_2/services/naver_news_service.dart';
import 'package:url_launcher/url_launcher.dart'; // URL 열기 위한 패키지
import 'package:html_unescape/html_unescape.dart'; // HTML 엔티티 디코딩 패키지

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final NaverNewsService _newsService = NaverNewsService();
  final HtmlUnescape _unescape = HtmlUnescape(); // HTML 엔티티 변환기
  List<News> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    try {
      final news = await _newsService.fetchNews(query: '오늘');
      setState(() {
        _newsList = news;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('뉴스를 불러오는데 실패했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      itemCount: _newsList.length,
      itemBuilder: (context, index) {
        final news = _newsList[index];
        final decodedTitle = _unescape.convert(news.title); // HTML 디코딩
        final decodedDescription = _unescape.convert(news.description); // HTML 디코딩

        return Card(
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              decodedTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(decodedDescription),
            onTap: () => _openNewsLink(news.link),
          ),
        );
      },
    );
  }

  void _openNewsLink(String url) async {
    final uri = Uri.parse(url); // String을 Uri로 변환

    await launchUrl(uri);

    // if (await canLaunchUrl(uri)) { // canLaunchUrl이 무조건 false를 반환함. 이상함. 오늘은 true를 반환함.
    //   await launchUrl(uri);
    // } else {
    //   throw 'Could not launch $url';
    // }
  }
}
