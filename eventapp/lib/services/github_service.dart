import 'package:http/http.dart' as http;
import 'dart:math';

class GitHubService {
  // Replace with a raw link to a text file containing Bible verses, one per line.
  // Example: A public GitHub Gist or a repository's raw file.
  // For demonstration, I'll use a placeholder. You'll need to create this file.
  static const String _bibleVersesRawUrl =
      'https://github.com/Jokku-gamma/MACE-EU/tree/main/daily-verses/bible_verse_2025-06-16.html';
      // **IMPORTANT: Replace this URL with your actual public raw text file URL**
      // Example of a simple Gist raw URL: https://gist.githubusercontent.com/yourusername/yourgistid/raw/bible_verses.txt


  Future<String?> fetchRandomBibleVerse() async {
    try {
      final response = await http.get(Uri.parse(_bibleVersesRawUrl));

      if (response.statusCode == 200) {
        final verses = response.body.split('\n').where((line) => line.trim().isNotEmpty).toList();
        if (verses.isNotEmpty) {
          final random = Random();
          return verses[random.nextInt(verses.length)];
        } else {
          return "No verses found in the file.";
        }
      } else {
        print('Failed to load Bible verses: ${response.statusCode}');
        return "Failed to load Bible verses. Status: ${response.statusCode}";
      }
    } catch (e) {
      print('Error fetching Bible verses: $e');
      return "Error fetching Bible verses: $e";
    }
  }
}
