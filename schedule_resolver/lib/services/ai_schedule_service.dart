import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/schedule_analysis.dart';
import '../models/task_model.dart';

class AiScheduleService extends ChangeNotifier{

  ScheduleAnalysis? _currentAnalysis;
  bool _isLoading = false;
  String? _errorMessage;

  final String _apikey = 'AIzaSyBSu1yoA1_zDPNKeDmlBBH8OvaiUdx8iP8';

  ScheduleAnalysis? get currentAnalysis => _currentAnalysis;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> analyzeSchedule(List<TaskModel> tasks) async {
    if (_apikey.isEmpty || tasks.isEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apikey);
      final taskJson = jsonEncode(tasks.map((t) => t.toMap()).toList());

      final prompt = '''
      
      You are an expert student scheduling assistant. The user has provide the following task for their day in JSON format:
      
      $taskJson
      
      Please provide exactly 4 section of markdown text:
      1. ### Detected Conflicts
      List any scheduling conflicts or state that there are none.
      2. ### Ranked Tasks
      Ranks which tasks needed attention first.
      3. ### Recommended Schedule
      Provide a revised daily timeline view adjusting the task times.
      4. ### Explanation
      Explain why this recommendation was made.
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      _currentAnalysis = _parseResponse(response.text ?? '');
    } catch (e) {

      _errorMessage = 'Error: \$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

  }

  ScheduleAnalysis _parseResponse(String fullText) {
    String conflicts = "", rankedTasks = "", recommendedSchedule = "", explanation = "";

    final sections = fullText.split('###');
    for (var section in sections) {
      if (section.trim().startsWith('Detected Conflicts')) conflicts = section.replaceFirst('Detected Conflicts', '').trim();
      else if (section.trim().startsWith('Ranked Tasks')) rankedTasks = section.replaceFirst('Ranked Tasks', '').trim();
      else if (section.trim().startsWith('Recommended Schedule')) recommendedSchedule = section.replaceFirst('Recommended Schedule', '').trim();
      else if (section.trim().startsWith('Explanation')) explanation = section.replaceFirst('Explanation', '').trim();
    }


    return ScheduleAnalysis(
        conflicts: conflicts,
        rankedTasks: rankedTasks,
        recommendedSchedule: recommendedSchedule,
        explanation: explanation
    );

  }


}