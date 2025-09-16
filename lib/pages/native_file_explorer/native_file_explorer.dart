import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../generated/l10n.dart';
import '../../models/file_item.dart';
import '../../services/openlist_api_service.dart';
import '../../contant/native_bridge.dart';

class NativeFileExplorerScreen extends StatelessWidget {
  const NativeFileExplorerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FileExplorerController());
    
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.currentPath.value)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshCurrentFolder(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPathBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (controller.files.isEmpty) {
                return const Center(child: Text('Empty folder'));
              }
              
              return ListView.builder(
                itemCount: controller.files.length,
                itemBuilder: (context, index) {
                  final file = controller.files[index];
                  return _FileListTile(file: file, controller: controller);
                },
              );
            }),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              S.current.poweredByOpenListMobile,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathBar() {
    return GetBuilder<FileExplorerController>(
      builder: (controller) {
        final pathParts = controller.currentPath.value.split('/').where((p) => p.isNotEmpty).toList();
        
        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                InkWell(
                  onTap: () => controller.navigateToPath('/'),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.home),
                  ),
                ),
                for (int i = 0; i < pathParts.length; i++) ...[
                  const Icon(Icons.chevron_right),
                  InkWell(
                    onTap: () {
                      final path = '/' + pathParts.sublist(0, i + 1).join('/');
                      controller.navigateToPath(path);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(pathParts[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FileListTile extends StatelessWidget {
  final FileItem file;
  final FileExplorerController controller;

  const _FileListTile({required this.file, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(file.icon),
      title: Text(file.name),
      subtitle: file.isDir ? null : Text(file.formattedSize),
      onTap: () {
        if (file.isDir) {
          controller.navigateToPath(file.path);
        }
      },
      onLongPress: () => _showContextMenu(context),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!file.isDir)
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(S.current.download),
              onTap: () {
                Navigator.pop(context);
                controller.downloadFile(file);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final textController = TextEditingController(text: file.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(labelText: 'New name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.current.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.renameFile(file, textController.text);
            },
            child: Text(S.current.confirm),
          ),
        ],
      ),
    );
  }
}

class FileExplorerController extends GetxController {
  final OpenListApiService _apiService = OpenListApiService();
  
  final RxList<FileItem> files = <FileItem>[].obs;
  final RxString currentPath = '/'.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  void _initializeService() async {
    final port = await NativeBridge.android.getOpenListHttpPort();
    _apiService.init('http://127.0.0.1:$port');
    
    final loginSuccess = await _apiService.login('admin', '');
    if (loginSuccess) {
      isLoggedIn.value = true;
      loadFolder('/');
    } else {
      _showLoginDialog();
    }
  }

  void _showLoginDialog() {
    final usernameController = TextEditingController(text: 'admin');
    final passwordController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final success = await _apiService.login(
                usernameController.text,
                passwordController.text,
              );
              if (success) {
                isLoggedIn.value = true;
                Get.back();
                loadFolder('/');
              } else {
                Get.snackbar('Error', 'Login failed');
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void loadFolder(String path) async {
    if (!isLoggedIn.value) return;
    
    isLoading.value = true;
    final response = await _apiService.listFiles(path);
    
    if (response != null) {
      files.value = response.content;
      currentPath.value = path;
    }
    
    isLoading.value = false;
  }

  void navigateToPath(String path) {
    loadFolder(path);
  }

  void refreshCurrentFolder() {
    loadFolder(currentPath.value);
  }

  void downloadFile(FileItem file) async {
    final downloadUrl = await _apiService.getDownloadUrl(file.path);
    if (downloadUrl != null) {
      Get.snackbar('Download', 'Starting download: ${file.name}');
    }
  }

  void renameFile(FileItem file, String newName) async {
    final success = await _apiService.rename(file.path, newName);
    if (success) {
      refreshCurrentFolder();
      Get.snackbar('Success', 'File renamed successfully');
    } else {
      Get.snackbar('Error', 'Failed to rename file');
    }
  }
}