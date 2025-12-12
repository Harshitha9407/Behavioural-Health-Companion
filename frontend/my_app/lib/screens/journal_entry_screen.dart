import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositories/journal_repository.dart';
import '../models/journal_entry.dart';

class MentalHealthJournalScreen extends StatefulWidget {
  const MentalHealthJournalScreen({super.key});

  @override
  State<MentalHealthJournalScreen> createState() => _MentalHealthJournalScreenState();
}

class _MentalHealthJournalScreenState extends State<MentalHealthJournalScreen> with TickerProviderStateMixin {
  final JournalRepository _repository = JournalRepository();
  List<JournalEntry> _journalEntries = [];
  bool _isLoading = false;
  
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  
  // Mental health tracking variables
  int? _moodRating;
  double _stressLevel = 5.0;
  final List<String> _selectedEmotions = [];
  final List<String> _selectedMoodTags = [];
  int _currentStep = 0;
  String _searchQuery = '';
  String _selectedFilterMood = 'All';
  
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  final List<String> _emotions = [
    'Happy', 'Sad', 'Anxious', 'Excited', 'Tired', 'Grateful', 
    'Frustrated', 'Hopeful', 'Overwhelmed', 'Peaceful', 'Angry', 
    'Content', 'Confident', 'Lonely', 'Motivated', 'Stressed'
  ];

  final List<String> _moodTags = [
    'Work', 'Family', 'Health', 'Relationships', 'Personal Growth',
    'Exercise', 'Sleep', 'Social', 'Academic', 'Financial', 'Spiritual'
  ];

  final Map<int, String> _moodLabels = {
    1: 'Very Low', 2: 'Low', 3: 'Below Average', 4: 'Average', 5: 'Good',
    6: 'Above Average', 7: 'Very Good', 8: 'Great', 9: 'Excellent', 10: 'Amazing'
  };

  final Map<int, String> _moodEmojis = {
    1: '😢', 2: '😔', 3: '😕', 4: '😐', 5: '🙂',
    6: '😊', 7: '😄', 8: '😁', 9: '🤗', 10: '🌟'
  };

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressAnimationController, curve: Curves.easeInOut),
    );
    
    _fetchJournalEntries();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchJournalEntries() async {
    setState(() => _isLoading = true);
    
    try {
      final entries = await _repository.getAllJournalEntries();
      
      if (mounted) {
        setState(() {
          _journalEntries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading entries: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading entries: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<JournalEntry> get _filteredEntries {
    return _journalEntries.where((entry) {
      final matchesSearch = _searchQuery.isEmpty || 
          entry.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (entry.emotions?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (entry.moodTags?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesMoodFilter = _selectedFilterMood == 'All' ||
          (_selectedFilterMood == 'High' && (entry.moodRating ?? 0) >= 7) ||
          (_selectedFilterMood == 'Medium' && (entry.moodRating ?? 0) >= 4 && (entry.moodRating ?? 0) < 7) ||
          (_selectedFilterMood == 'Low' && (entry.moodRating ?? 0) < 4);
      
      return matchesSearch && matchesMoodFilter;
    }).toList();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_currentStep == 0 && _entryController.text.trim().isEmpty) {
        _showErrorSnackBar('Please write your thoughts before continuing.');
        return;
      }
      if (_currentStep == 1 && _moodRating == null) {
        _showErrorSnackBar('Please rate your mood before continuing.');
        return;
      }
      
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
    } else {
      _saveEntry();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
    }
  }

  void _updateProgress() {
    double progress = (_currentStep + 1) / 3;
    _progressAnimationController.animateTo(progress);
  }

  Future<void> _saveEntry() async {
    String content = _entryController.text.trim();
    
    if (content.isEmpty || _moodRating == null) {
      _showErrorSnackBar('Please complete all required fields.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newEntry = JournalEntry(
        content: content,
        moodRating: _moodRating,
        stressRating: _stressLevel.round(),
        emotions: _selectedEmotions.isNotEmpty ? _selectedEmotions.join(',') : null,
        moodTags: _selectedMoodTags.isNotEmpty ? _selectedMoodTags.join(',') : null,
      );

      final success = await _repository.saveJournalEntry(newEntry);
      
      if (success) {
        print('✅ Journal entry saved');
        
        if (mounted) {
          Navigator.pop(context);
        }
        
        await _fetchJournalEntries();
        
        _resetForm();
        
        if (mounted) {
          _showSuccessSnackBar('Mental health check-in saved successfully!');
        }
      } else {
        throw Exception('Failed to save entry');
      }
    } catch (e) {
      print('❌ Error saving entry: $e');
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        _showErrorSnackBar('Failed to save entry: $e');
      }
    }
  }

  Future<void> _deleteEntry(int? entryId) async {
    if (entryId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final success = await _repository.deleteJournalEntry(entryId);
      
      if (success) {
        await _fetchJournalEntries();
        
        if (mounted) {
          _showSuccessSnackBar('Entry deleted successfully');
        }
      } else {
        throw Exception('Failed to delete entry');
      }
    } catch (e) {
      print('❌ Error deleting entry: $e');
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        _showErrorSnackBar('Failed to delete entry: $e');
      }
    }
  }

  void _resetForm() {
    _entryController.clear();
    _moodRating = null;
    _stressLevel = 5.0;
    _selectedEmotions.clear();
    _selectedMoodTags.clear();
    _currentStep = 0;
    _progressAnimationController.reset();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2E8B82),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showGuidedCheckIn() {
    _resetForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildModalHeader(setModalState),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setModalState(() => _currentStep = index);
                    _updateProgress();
                  },
                  children: [
                    _buildThoughtsStep(setModalState),
                    _buildMoodAndStressStep(setModalState),
                    _buildEmotionsAndTagsStep(setModalState),
                  ],
                ),
              ),
              _buildModalFooter(setModalState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(StateSetter setModalState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E8B82).withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mental Health Check-in',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A5A54),
                ),
              ),
              Row(
                children: [
                  Text(
                    '${_currentStep + 1}/3',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E8B82)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModalFooter(StateSetter setModalState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () {
                _previousStep();
                setModalState(() {});
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E8B82),
                side: const BorderSide(color: Color(0xFF2E8B82)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Previous'),
            )
          else
            const SizedBox(),
          ElevatedButton(
            onPressed: _isLoading ? null : () {
              _nextStep();
              setModalState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B82),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_currentStep == 2 ? 'Complete Check-in' : 'Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildThoughtsStep(StateSetter setModalState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.psychology,
            size: 48,
            color: Color(0xFF2E8B82),
          ),
          const SizedBox(height: 20),
          const Text(
            'What\'s on your mind today?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A5A54),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Share your thoughts, experiences, or anything significant from today. This is your safe space to express yourself.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: _entryController,
              maxLines: 8,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Today I felt...\n\nThe most challenging part was...\n\nSomething positive that happened...\n\nI\'m grateful for...',
                hintStyle: TextStyle(color: Colors.grey[400], height: 1.4),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
                counterStyle: TextStyle(color: Colors.grey[500]),
              ),
              onChanged: (value) => setModalState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodAndStressStep(StateSetter setModalState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sentiment_satisfied,
            size: 48,
            color: Color(0xFF2E8B82),
          ),
          const SizedBox(height: 20),
          const Text(
            'Rate your overall mood and stress',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A5A54),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Use the sliders to track your current mood and stress levels. Be honest with yourself.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
          _buildEnhancedMoodSlider(setModalState),
          const SizedBox(height: 40),
          _buildLevelSlider('Stress Level', _stressLevel, (value) {
            setModalState(() => _stressLevel = value);
          }),
        ],
      ),
    );
  }

  Widget _buildEmotionsAndTagsStep(StateSetter setModalState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.favorite,
            size: 48,
            color: Color(0xFF2E8B82),
          ),
          const SizedBox(height: 20),
          const Text(
            'What emotions did you experience?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A5A54),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Select emotions you felt today. It\'s normal to experience multiple emotions.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          _buildSelectionChips('Emotions', _emotions, _selectedEmotions, setModalState),
          const SizedBox(height: 30),
          const Text(
            'What areas of life influenced your mood?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A5A54),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tag the areas that had an impact on how you felt today.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          _buildSelectionChips('Mood Tags', _moodTags, _selectedMoodTags, setModalState),
        ],
      ),
    );
  }

  Widget _buildEnhancedMoodSlider(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mood Rating',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_moodRating != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B82).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _moodEmojis[_moodRating!] ?? '❓',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _moodLabels[_moodRating!] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E8B82),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF2E8B82),
            inactiveTrackColor: const Color(0xFF2E8B82).withOpacity(0.3),
            thumbColor: const Color(0xFF2E8B82),
            overlayColor: const Color(0xFF2E8B82).withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: _moodRating?.toDouble() ?? 5.0,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) {
              setModalState(() => _moodRating = value.round());
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('😢 Very Low', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('🌟 Amazing', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B82).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '${value.round()}/10',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E8B82),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF2E8B82),
            inactiveTrackColor: const Color(0xFF2E8B82).withOpacity(0.3),
            thumbColor: const Color(0xFF2E8B82),
            overlayColor: const Color(0xFF2E8B82).withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Low', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('High', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionChips(String title, List<String> items, List<String> selected, StateSetter setModalState) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: items.map((item) {
        final isSelected = selected.contains(item);
        return GestureDetector(
          onTap: () {
            setModalState(() {
              if (isSelected) {
                selected.remove(item);
              } else {
                selected.add(item);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2E8B82) : Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? const Color(0xFF2E8B82) : Colors.grey[300]!,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: const Color(0xFF2E8B82).withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Text(
              item,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search your entries...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF2E8B82)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2E8B82)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Filter by mood:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A5A54),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'High', 'Medium', 'Low'].map((filter) {
                      final isSelected = _selectedFilterMood == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedFilterMood = filter);
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(0xFF2E8B82).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF2E8B82) : Colors.grey[600],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_outline,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'Start tracking your mental health',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your first check-in helps establish baseline patterns for better self-awareness',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    if (_journalEntries.isEmpty) return const SizedBox();

    final recentEntries = _journalEntries.take(7).toList();
    final moodEntries = recentEntries.where((e) => e.moodRating != null).toList();
    final stressEntries = recentEntries.where((e) => e.stressRating != null).toList();
    
    final avgMood = moodEntries.isNotEmpty
        ? moodEntries.map((e) => e.moodRating!).fold(0, (a, b) => a + b) / moodEntries.length
        : 0.0;
    final avgStress = stressEntries.isNotEmpty
        ? stressEntries.map((e) => e.stressRating!).fold(0, (a, b) => a + b) / stressEntries.length
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E8B82).withOpacity(0.1),
            const Color(0xFF2E8B82).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E8B82).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: Color(0xFF2E8B82), size: 24),
              SizedBox(width: 8),
              Text('7-Day Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A5A54)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Avg Mood', '${avgMood.toStringAsFixed(1)}/10', _moodEmojis[avgMood.round()] ?? '❓', Colors.blue)),
              Container(width: 12),
              Expanded(child: _buildStatCard('Avg Stress', '${avgStress.toStringAsFixed(1)}/10', avgStress > 7 ? '🔴' : avgStress > 4 ? '🟡' : '🟢', Colors.orange)),
              Container(width: 12),
              Expanded(child: _buildStatCard('Entries', '${_journalEntries.length}', '📝', Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedEntryCard(JournalEntry entry) {
    String moodEmoji = _moodEmojis[entry.moodRating] ?? '❓';
    String emotions = entry.emotions ?? 'Not specified';
    String moodTags = entry.moodTags ?? 'Not specified';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(moodEmoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.timestamp != null
                                  ? DateFormat('MMM dd, yyyy').format(entry.timestamp!)
                                  : 'Just now',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A5A54),
                              ),
                            ),
                            if (entry.timestamp != null)
                              Text(
                                DateFormat('jm').format(entry.timestamp!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (entry.id != null)
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: ListTile(
                              leading: const Icon(Icons.delete, color: Colors.red),
                              title: const Text('Delete'),
                              contentPadding: EdgeInsets.zero,
                              onTap: () {
                                Navigator.pop(context);
                                _deleteEntry(entry.id);
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  entry.content,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildInfoGrid(entry),
              ],
            ),
          ),
          if (emotions != 'Not specified' || moodTags != 'Not specified')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (emotions != 'Not specified') ...[
                    Text('Emotions',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: emotions.split(',').map((emotion) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E8B82).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(emotion.trim(),
                          style: const TextStyle(
                            fontSize: 11, color: Color(0xFF2E8B82), fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                  if (emotions != 'Not specified' && moodTags != 'Not specified') const SizedBox(height: 12),
                  if (moodTags != 'Not specified') ...[
                    Text('Life Areas',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: moodTags.split(',').map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(tag.trim(),
                          style: TextStyle(
                            fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(JournalEntry entry) {
    return Row(
      children: [
        if (entry.moodRating != null)
          Expanded(
            child: _buildInfoItem('Mood', '${entry.moodRating}/10', Icons.sentiment_satisfied, const Color(0xFF2E8B82)),
          ),
        if (entry.moodRating != null && entry.stressRating != null)
          Container(width: 1, height: 40, color: Colors.grey[300]),
        if (entry.stressRating != null)
          Expanded(
            child: _buildInfoItem('Stress', '${entry.stressRating}/10', Icons.psychology, Colors.orange),
          ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          children: [
            Text(value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyCheckInButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2E8B82), const Color(0xFF2E8B82).withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E8B82).withOpacity(0.3),
            spreadRadius: 0, blurRadius: 15, offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.psychology, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          const Text('Daily Mental Health Check-in',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _journalEntries.isEmpty 
                ? 'Track your thoughts, emotions, and wellbeing journey'
                : '${_journalEntries.length} entries tracked',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showGuidedCheckIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2E8B82),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: const Text('Start Check-in',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEntriesFound() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No entries found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('Try adjusting your search or filter criteria',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E8B82),
        elevation: 0,
        title: const Text('Mental Health Journal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchJournalEntries,
          ),
        ],
      ),
      body: _isLoading && _journalEntries.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E8B82),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF2E8B82),
              onRefresh: _fetchJournalEntries,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDailyCheckInButton(),
                    const SizedBox(height: 32),
                    _buildStatsOverview(),
                    if (_journalEntries.isNotEmpty) ...[
                      _buildSearchAndFilter(),
                      const SizedBox(height: 20),
                    ],
                    const Text('Your Mental Health Journey',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A5A54)),
                    ),
                    const SizedBox(height: 16),
                    if (_filteredEntries.isEmpty && _journalEntries.isNotEmpty)
                      _buildNoEntriesFound()
                    else if (_journalEntries.isEmpty)
                      _buildEmptyState()
                    else
                      Column(
                        children: _filteredEntries.map(_buildDetailedEntryCard).toList(),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }
}