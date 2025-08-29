
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realtor_app/history_manager.dart'; // Import your history manager
import 'package:realtor_app/history_detail_screen.dart'; // Import detail screen
import 'package:flutter/scheduler.dart';
import '../utils/custom_snackbar.dart'; // <-- IMPORT THE NEW SNACKBAR HELPER

class HistoryScreen extends StatefulWidget {
  final String type; // 'Invoice' or 'Contract'

  const HistoryScreen({super.key, required this.type});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {

  Stream<List<DocumentHistoryItem>>? _historyStream;

  Future<List<DocumentHistoryItem>>? _historyFuture;
  late AnimationController _refreshController;
  late Animation<double> _rotationAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // --- STATE FOR SEARCH ---
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();

    // Add listener to rebuild the list on text change
    _searchController.addListener(() {
      setState(() {});
    });

    // Initialize animations
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rotationAnimation = CurvedAnimation(
      parent: _refreshController,
      curve: Curves.easeInOut,
    );

    _refreshController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _refreshController.reset();
      }
    });

    // Bounce animation setup
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.elasticOut,
      ),
    );

    // Load history when screen first loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory(showAnimation: false);
    });
  }




  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool showAnimation = true}) async {
    if (showAnimation) {
      // Start bounce effect
      _bounceController.forward(from: 0);

      // Start rotation after slight delay
      Future.delayed(const Duration(milliseconds: 100), () {
        _refreshController.forward();
      });
    }

    setState(() {
      _historyStream = DocumentHistoryManager.getHistoryStream(widget.type);
    });

    try {
      await _historyFuture;
    } catch (e) {
      // Handle error if needed
    }
  }

  void _confirmClearHistory() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        String confirmationText = '';
        final String requiredConfirmation = widget.type == 'Contract'
            ? 'ყველა ხელშეკრულების წაშლა'
            : 'ყველა ინვოისის წაშლა';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: const Text(
                'ისტორიის გასუფთავება',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004aad),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'დასადასტურებლად აკრიფეთ:',
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      requiredConfirmation,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          confirmationText = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: requiredConfirmation,
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF004aad)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF004aad), width: 2.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF004aad),
                  ),
                  child: const Text('გაუქმება'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: confirmationText == requiredConfirmation
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  child: const Text('დადასტურება'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm == true) {
      await DocumentHistoryManager.clearHistory(widget.type);
      if (mounted) {
        // --- MODIFIED ---
        CustomSnackBar.show(
          context: context,
          message: 'ისტორია გასუფთავდა',
        );
      }
      _loadHistory(); // Reload history after clearing
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == 'Contract' ? 'ხელ.-ების ისტორია' : 'ინვოისების ისტორია',
          style: const TextStyle(color: Colors.white,fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF004aad),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _confirmClearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isSearchVisible = !_isSearchVisible;
                      if (!_isSearchVisible) {
                        _searchController.clear();
                      }
                    });
                  },
                  icon: Icon(
                    _isSearchVisible ? Icons.close : Icons.search,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isSearchVisible ? 'ძიების დახურვა' : 'ძიება',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSearchVisible ? Colors.red : const Color(0xFF004aad),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isSearchVisible
                      ? Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: widget.type == 'Invoice'
                            ? 'ბინის მისამართი...'
                            : 'მეპატრონე, სტუმარი...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF004aad)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF004aad), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DocumentHistoryItem>>(
              stream: _historyStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(widget.type == 'Contract'
                      ? 'ხელშეკრულებების ისტორია ცარიელია.'
                      : 'ინვოისების ისტორია ცარიელია.'));
                } else {
                  final allItems = snapshot.data!;
                  final query = _searchController.text.toLowerCase();
                  final filteredItems = query.isEmpty
                      ? allItems
                      : allItems.where((item) {
                    if (widget.type == 'Invoice') {
                      final address = (item.placeholders['apartmentAddress'] as String?)?.toLowerCase() ?? '';
                      final name = item.id.split(' - ').first.toLowerCase();
                      return address.contains(query) || name.contains(query);
                    } else { // Contract
                      return item.id.toLowerCase().contains(query);
                    }
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return const Center(child: Text('შედეგი ვერ მოიძებნა.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      String titleText;
                      String subtitleText;
                      String prefix = '';

                      final displayTimestamp = DateFormat('dd-MM-yyyy HH:mm').format(item.timestamp);

                      if (item.type == 'Contract') {
                        // --- FIX START: The item.id no longer contains slashes ---
                        final parts = item.id.split(' - ');
                        // --- FIX END ---
                        final names = parts.take(2).join(' - ');
                        titleText = 'ხელშეკრულება - $names | $displayTimestamp';
                      } else {
                        final isGeorgian = item.placeholders['isGeorgian'] == true;
                        prefix = isGeorgian ? '(GE)' : '(RU)';
                        final name = item.id.split(' - ').first;
                        titleText = '$prefix $name | $displayTimestamp';
                      }

                      if (item.type == 'Contract' && item.pdfUrl != null) {
                        subtitleText = 'დააჭირეთ დეტალებისთვის';
                      } else if (item.generatedText != null) {
                        subtitleText = item.generatedText!.length > 100
                            ? '${item.generatedText!.substring(0, 100)}...'
                            : item.generatedText!;
                      } else {
                        subtitleText = 'არ არსებობს';
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              titleText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Color(0xFF004aad),
                              ),
                            ),
                          ),
                          subtitle: Text(
                            subtitleText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HistoryDetailScreen(item: item),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _bounceAnimation,
        child: FloatingActionButton(
          onPressed: _loadHistory,
          backgroundColor: const Color(0xFF004aad),
          shape: const CircleBorder(),
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * pi,
                child: const Icon(Icons.refresh, color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }
}