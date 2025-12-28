import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/backup_provider.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupProvider);

    ref.listen<BackupState>(backupProvider, (previous, next) {
      if (next.message != null && previous?.message != next.message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message!), backgroundColor: Colors.green),
        );
        ref.read(backupProvider.notifier).clearMessages();
      }
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(backupProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle('General'),
          _buildGeneralSection(),
          const SizedBox(height: 24),
          _buildSectionTitle('Backup & Restore'),
          const SizedBox(height: 8),
          _LocalBackupCard(backupState: backupState),
          const SizedBox(height: 12),
          _GoogleDriveCard(backupState: backupState),
          const SizedBox(height: 24),
          _buildSectionTitle('Support'),
          _buildSupportSection(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildGeneralSection() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

// Local Backup Card Widget
class _LocalBackupCard extends ConsumerWidget {
  final BackupState backupState;

  const _LocalBackupCard({required this.backupState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.folder_outlined, color: Color(0xFF6B7FD7)),
        title: const Text('Local Backup'),
        subtitle: Text(
          '${backupState.localBackups.length} backup${backupState.localBackups.length != 1 ? 's' : ''} saved',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Create Backup'),
            subtitle: const Text('Save data to device storage'),
            trailing: backupState.status == BackupStatus.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: backupState.status == BackupStatus.loading
                ? null
                : () => ref.read(backupProvider.notifier).createLocalBackup(),
          ),
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: const Text('Restore from File'),
            subtitle: const Text('Pick a backup file to restore'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showRestoreConfirmDialog(
              context,
              'Restore from File',
              'This will replace all your current data with the backup. Continue?',
              () => ref.read(backupProvider.notifier).pickAndRestoreBackup(),
            ),
          ),
          if (backupState.localBackups.isNotEmpty) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Saved Backups',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            ...backupState.localBackups.take(5).map((backup) {
              return ListTile(
                dense: true,
                title: Text(
                  backup.fileName,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  _formatDate(backup.createdAt),
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'restore',
                      child: Row(
                        children: [
                          Icon(Icons.restore, size: 18),
                          SizedBox(width: 8),
                          Text('Restore'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'restore') {
                      _showRestoreConfirmDialog(
                        context,
                        'Restore Backup',
                        'This will replace all your current data. Continue?',
                        () => ref
                            .read(backupProvider.notifier)
                            .restoreFromLocalBackup(backup.filePath),
                      );
                    } else if (value == 'delete') {
                      _showDeleteConfirmDialog(
                        context,
                        'Delete Backup',
                        'Delete this backup file?',
                        () => ref
                            .read(backupProvider.notifier)
                            .deleteLocalBackup(backup.filePath),
                      );
                    }
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM d, yyyy').format(date);
  }
}

// Google Drive Card Widget
class _GoogleDriveCard extends ConsumerWidget {
  final BackupState backupState;

  const _GoogleDriveCard({required this.backupState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ExpansionTile(
        leading: Icon(
          Icons.cloud_outlined,
          color: backupState.isGoogleSignedIn ? Colors.green : Colors.grey,
        ),
        title: const Text('Google Drive'),
        subtitle: Text(
          backupState.isGoogleSignedIn
              ? 'Signed in as ${backupState.googleUserEmail}'
              : 'Sign in to backup to cloud',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          if (!backupState.isGoogleSignedIn)
            _buildSignInTile(context, ref)
          else
            _buildSignedInContent(context, ref),
        ],
      ),
    );
  }

  Widget _buildSignInTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Text(
            'G',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4285F4),
            ),
          ),
        ),
      ),
      title: const Text('Sign in with Google'),
      subtitle: const Text('Connect to backup your data'),
      trailing: backupState.status == BackupStatus.loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: backupState.status == BackupStatus.loading
          ? null
          : () => ref.read(backupProvider.notifier).signInWithGoogle(),
    );
  }

  Widget _buildSignedInContent(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: backupState.googleUserPhotoUrl != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(
                    backupState.googleUserPhotoUrl!,
                  ),
                  radius: 16,
                )
              : const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person, size: 18),
                ),
          title: Text(backupState.googleUserName ?? 'Google User'),
          subtitle: Text(
            backupState.googleUserEmail ?? '',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: TextButton(
            onPressed: () =>
                ref.read(backupProvider.notifier).signOutFromGoogle(),
            child: const Text('Sign Out'),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.cloud_upload_outlined),
          title: const Text('Backup to Google Drive'),
          trailing: backupState.status == BackupStatus.loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: backupState.status == BackupStatus.loading
              ? null
              : () => ref.read(backupProvider.notifier).createDriveBackup(),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_download_outlined),
          title: const Text('Restore from Google Drive'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showDriveBackupsList(context, ref),
        ),
        if (backupState.driveBackups.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${backupState.driveBackups.length} backup${backupState.driveBackups.length != 1 ? 's' : ''} in Google Drive',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
      ],
    );
  }

  void _showDriveBackupsList(BuildContext context, WidgetRef ref) {
    if (backupState.driveBackups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No backups found in Google Drive')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) =>
          _DriveBackupsSheet(backupState: backupState, parentContext: context),
    );
  }
}

// Drive Backups Bottom Sheet
class _DriveBackupsSheet extends ConsumerWidget {
  final BackupState backupState;
  final BuildContext parentContext;

  const _DriveBackupsSheet({
    required this.backupState,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Google Drive Backups',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: backupState.driveBackups.length,
              itemBuilder: (context, index) {
                final backup = backupState.driveBackups[index];
                return ListTile(
                  leading: const Icon(Icons.cloud_done_outlined),
                  title: Text(backup.fileName),
                  subtitle: Text(
                    backup.modifiedTime != null
                        ? DateFormat(
                            'MMM d, yyyy • h:mm a',
                          ).format(backup.modifiedTime!)
                        : 'Unknown date',
                  ),
                  trailing: PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'restore',
                        child: Row(
                          children: [
                            Icon(Icons.restore, size: 18),
                            SizedBox(width: 8),
                            Text('Restore'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      Navigator.pop(context);
                      if (value == 'restore') {
                        _showRestoreConfirmDialog(
                          parentContext,
                          'Restore from Google Drive',
                          'This will replace all your current data. Continue?',
                          () => ref
                              .read(backupProvider.notifier)
                              .restoreFromDriveBackup(backup.fileId),
                        );
                      } else if (value == 'delete') {
                        _showDeleteConfirmDialog(
                          parentContext,
                          'Delete Drive Backup',
                          'Delete this backup from Google Drive?',
                          () => ref
                              .read(backupProvider.notifier)
                              .deleteDriveBackup(backup.fileId),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Shared Dialog Functions
void _showRestoreConfirmDialog(
  BuildContext context,
  String title,
  String message,
  VoidCallback onConfirm,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('Restore'),
        ),
      ],
    ),
  );
}

void _showDeleteConfirmDialog(
  BuildContext context,
  String title,
  String message,
  VoidCallback onConfirm,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
