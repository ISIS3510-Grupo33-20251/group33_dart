import 'package:flutter/material.dart';
import 'package:group33_dart/services/api_service_adapter.dart';
import '../../globals.dart';

final ApiServiceAdapter apiServiceAdapter =
    ApiServiceAdapter(backendUrl: backendUrl);

class PendingRequests extends StatefulWidget {
  const PendingRequests({Key? key}) : super(key: key);

  @override
  State<PendingRequests> createState() => _PendingRequestsState();
}

class _PendingRequestsState extends State<PendingRequests> {
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
  final hasConnection = await hasInternetConnection();
  if (!hasConnection) {
    setState(() {
      _error = 'No internet connection. Please try again later.';
      _isLoading = false;
    });
    return;
  }

  try {
    final data = await apiServiceAdapter.getPendingRequests(userId);
    List<Map<String, dynamic>> enriched = [];

    for (var req in data) {
      final senderId = req['sender_id'];
      try {
        final senderData = await apiServiceAdapter.fetchUserById(senderId);
        req['name'] = senderData['name'] ?? 'Unknown';
        req['email'] = senderData['email'] ?? 'unknown@example.com';
      } catch (_) {
        req['name'] = 'Unknown';
        req['email'] = 'unknown@example.com';
      }
      enriched.add(req);
    }

    setState(() {
      _pendingRequests = enriched;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _error = 'Error loading requests: $e';
      _isLoading = false;
    });
  }
}

  Future<void> _respondToRequest(String requestId, bool accept) async {
    try {
      if (accept) {
        await apiServiceAdapter.acceptFriendRequest(requestId);
      } else {
        await apiServiceAdapter.rejectFriendRequest(requestId);
      }

      setState(() {
        _pendingRequests.removeWhere((r) => r['_id'] == requestId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to respond to request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // fondo blanco
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pending Requests',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _pendingRequests.isEmpty
                  ? const Center(
                      child: Text(
                        'No pending requests.',
                        style: TextStyle(fontSize: 16, color: Colors.grey,fontWeight: FontWeight.bold),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _pendingRequests.length,
                      itemBuilder: (context, index) {
                        final request = _pendingRequests[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            title: Text(
                              request['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              request['email'] ?? '',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 14),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  onPressed: () => _respondToRequest(
                                      request['_id'], true),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  onPressed: () => _respondToRequest(
                                      request['_id'], false),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
