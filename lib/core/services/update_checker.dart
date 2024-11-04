import 'dart:convert';
import 'dart:io';
import 'package:campus_saga/core/constants/update_constants.dart';
import 'package:campus_saga/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
Future<String> checkUpdateFromGithub(BuildContext context) async {
  try {
    // Check internet connectivity first
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network.'),
          ),
        );
      }
      return "No internet connection";
    }

    // If connected, proceed to check for updates
    String url = "https://api.github.com/repos/$OWNER_NAME/$REPO_NAME/releases/latest";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      String latestVersion = data['tag_name'];
      String downloadUrl = data['assets'][0]['browser_download_url'];
      String releaseNote = data['body'];
      
      if (latestVersion != CURRENT_VERSION) {
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Update Available'),
                content: Text(
                  'A new version of the app is available. Please update to the latest version.\n\n'
                  'Please uninstall the old version before installing the new version\n\n'
                  'Release Note:\n$releaseNote'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Update Later'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      launchURL(downloadUrl);
                    },
                    child: const Text('Update'),
                  ),
                ],
              );
            },
          );
        }
        return "Update available: $latestVersion";
      }
      return "App is up to date";
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch data: HTTP ${response.statusCode}'),
          ),
        );
      }
      return "Update check failed: HTTP ${response.statusCode}";
    }
  } on SocketException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error: Could not connect to the server'),
        ),
      );
    }
    return "Network error: ${e.message}";
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $error'),
        ),
      );
    }
    return "Update check failed: $error";
  }
}

/*
this code always shows, this exception, 
SocketException (SocketException: Failed host lookup: •api.github.com• (OS Error. No such hos
is known.
, errno = 11001))
it is not catch by the catch block
*/