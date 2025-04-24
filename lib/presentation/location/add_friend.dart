import 'package:flutter/material.dart';
import 'package:group33_dart/services/api_service_adapter.dart';
import '../../globals.dart';

final ApiServiceAdapter apiServiceAdapter =
    ApiServiceAdapter(backendUrl: backendUrl);

class AddFriend extends StatefulWidget {
  final String userId;

  const AddFriend({Key? key, required this.userId});

  @override
  State<AddFriend> createState() => _AddFriendState();
}

class _AddFriendState extends State<AddFriend> {
  final TextEditingController _emailController = TextEditingController();
  String _message = '';
  bool _isLoading = false;

  Future<void> _sendRequest() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final receiverEmail = _emailController.text.trim();

      if (receiverEmail.isEmpty) {
        setState(() {
          _message = 'Please enter a valid email.';
          _isLoading = false;
        });
        return;
      }

      await apiServiceAdapter.sendFriendRequest(widget.userId, receiverEmail);

      setState(() {
        _message = 'Friend request sent!';
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to send request: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Friend',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w400,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Friend\'s email',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                shadowColor: Colors.grey.withOpacity(0.4),
                elevation: 6,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Send Friend Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                _message,
                style: TextStyle(
                  color: _message.contains('Failed') ? Colors.red : Colors.green,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
