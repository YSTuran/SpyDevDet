import 'package:flutter/material.dart';
import 'package:spy_dev_det/features/scan/domain/device_evidence.dart';

class DeviceProfileEditResult {
  const DeviceProfileEditResult({
    required this.isKnown,
    required this.isOwned,
    required this.customName,
    required this.note,
    required this.categoryOverride,
  });

  final bool isKnown;
  final bool isOwned;
  final String? customName;
  final String? note;
  final DeviceCategory? categoryOverride;
}

Future<DeviceProfileEditResult?> showDeviceProfileEditor(
  BuildContext context, {
  required bool isKnown,
  required bool isOwned,
  String? customName,
  String? note,
  DeviceCategory? categoryOverride,
}) async {
  final nameController = TextEditingController(text: customName);
  final noteController = TextEditingController(text: note);
  var editedIsKnown = isKnown;
  var editedIsOwned = isOwned;
  var editedCategory = categoryOverride;
  try {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cihaz profilini düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Özel cihaz adı',
                    hintText: 'Örneğin: Salon televizyonu',
                  ),
                ),
                TextField(
                  controller: noteController,
                  maxLength: 240,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Not',
                    hintText: 'İsteğe bağlı yerel not',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: editedIsKnown,
                  onChanged: (value) => setDialogState(() {
                    editedIsKnown = value ?? false;
                    if (!editedIsKnown) {
                      editedIsOwned = false;
                    }
                  }),
                  title: const Text('Bu cihazı tanıyorum'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: editedIsOwned,
                  onChanged: (value) => setDialogState(() {
                    editedIsOwned = value ?? false;
                    if (editedIsOwned) {
                      editedIsKnown = true;
                    }
                  }),
                  title: const Text('Bu cihaz bana/evime ait'),
                  subtitle: const Text(
                    'Yalnızca inceleme puanını açıklamak ve profili tanımak '
                    'için cihazında saklanır.',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<DeviceCategory?>(
                  initialValue: editedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Cihaz türü düzeltmesi',
                  ),
                  items: [
                    const DropdownMenuItem<DeviceCategory?>(
                      value: null,
                      child: Text('Otomatik sınıflandırmayı kullan'),
                    ),
                    ...DeviceCategory.values.map(
                      (category) => DropdownMenuItem<DeviceCategory?>(
                        value: category,
                        child: Text(category.label),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => editedCategory = value),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uygulamanın otomatik tahmini korunur; yaptığın düzeltme '
                  'ayrı bir alan olarak gösterilir.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (shouldSave != true) {
      return null;
    }
    return DeviceProfileEditResult(
      isKnown: editedIsKnown,
      isOwned: editedIsOwned,
      customName: _normalize(nameController.text),
      note: _normalize(noteController.text),
      categoryOverride: editedCategory,
    );
  } finally {
    nameController.dispose();
    noteController.dispose();
  }
}

String? _normalize(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
