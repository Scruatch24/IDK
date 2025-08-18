// lib/history_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realtor_app/history_manager.dart'; // Import your history manager
import 'package:realtor_app/history_detail_screen.dart'; // Import detail screen
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class HistoryScreen extends StatefulWidget {
  final String type; // 'Invoice' or 'Contract'

  const HistoryScreen({super.key, required this.type});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  Future<List<DocumentHistoryItem>>? _historyFuture;
  late AnimationController _refreshController;
  late Animation<double> _rotationAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

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
      _historyFuture = DocumentHistoryManager.getHistory(widget.type);
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
                  color: Color(0xFF004aad), // primaryColor
                ),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(
                      'დასადასტურებლად აკრიფეთ "$requiredConfirmation".',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          confirmationText = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: requiredConfirmation, // Use the confirmation phrase as a hint
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF004aad)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF004aad)),
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
                    backgroundColor: const Color(0xFF004aad),
                    foregroundColor: Colors.white,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ისტორია გასუფთავდა')),
      );
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
      body: FutureBuilder<List<DocumentHistoryItem>>(
        future: _historyFuture,
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
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final item = snapshot.data?[index];
                if (item == null) {
                  return const SizedBox.shrink();
                }
                String titleText;
                String subtitleText;
                String prefix = '';

                final displayTimestamp = DateFormat('dd-MM-yyyy HH:mm').format(item.timestamp);

                if (item.type == 'Contract') {
                  final parts = item.id.split('/').last.split(' - ');
                  final names = parts.take(2).join(' - ');
                  titleText = 'ხელშეკრულება - $names | $displayTimestamp';
                } else {
                  final isGeorgian = item.placeholders['isGeorgian'] == true;
                  prefix = isGeorgian ? '(GE)' : '(RU)';
                  final name = item.id.split(' - ').first;
                  titleText = '$prefix $name | $displayTimestamp';
                }

                if (item.type == 'Contract' && item.pdfUrl != null) {
                  subtitleText = 'PDF ხელშეკრულება (დააჭირეთ დეტალებისთვის)';
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