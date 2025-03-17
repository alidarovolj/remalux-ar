class Faq {
  final int id;
  final Map<String, String> question;
  final Map<String, String> answer;

  Faq({
    required this.id,
    required this.question,
    required this.answer,
  });

  factory Faq.fromJson(Map<String, dynamic> json) {
    return Faq(
      id: json['id'] as int,
      question: Map<String, String>.from(json['question'] as Map),
      answer: Map<String, String>.from(json['answer'] as Map),
    );
  }

  String getLocalizedQuestion(String locale) {
    return question[locale] ?? question['ru'] ?? '';
  }

  String getLocalizedAnswer(String locale) {
    return answer[locale] ?? answer['ru'] ?? '';
  }
}
