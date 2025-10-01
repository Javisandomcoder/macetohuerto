import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/care_log.dart';
import '../models/plant.dart';
import '../providers/care_log_provider.dart';
import '../providers/plant_provider.dart';

class CareHistoryPage extends ConsumerStatefulWidget {
  final Plant plant;

  const CareHistoryPage({super.key, required this.plant});

  @override
  ConsumerState<CareHistoryPage> createState() => _CareHistoryPageState();
}

class _CareHistoryPageState extends ConsumerState<CareHistoryPage> {
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddCareLogDialog(
        plantId: widget.plant.id,
        onAdd: (log) {
          ref.read(careLogsProvider(widget.plant.id).notifier).add(log);

          // Update last watered if it's a watering log
          if (log.careType == CareType.watering) {
            ref.read(plantsProvider.notifier).markWatered(
                  widget.plant.id,
                  log.performedAt,
                );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final careLogs = ref.watch(careLogsProvider(widget.plant.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de ${widget.plant.name}'),
      ),
      body: careLogs.when(
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sin registros',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Registra los cuidados de tu planta',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _CareLogTile(
                log: log,
                onDelete: () {
                  ref.read(careLogsProvider(widget.plant.id).notifier).remove(log.id);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CareLogTile extends StatelessWidget {
  final CareLog log;
  final VoidCallback onDelete;

  const _CareLogTile({
    required this.log,
    required this.onDelete,
  });

  IconData _getIcon() {
    switch (log.careType) {
      case CareType.watering:
        return Icons.water_drop;
      case CareType.fertilizing:
        return Icons.grass;
      case CareType.pruning:
        return Icons.content_cut;
      case CareType.transplanting:
        return Icons.change_circle;
      case CareType.pestControl:
        return Icons.bug_report;
      case CareType.other:
        return Icons.more_horiz;
    }
  }

  String _getLabel() {
    switch (log.careType) {
      case CareType.watering:
        return 'Riego';
      case CareType.fertilizing:
        return 'Abonado';
      case CareType.pruning:
        return 'Poda';
      case CareType.transplanting:
        return 'Trasplante';
      case CareType.pestControl:
        return 'Control de plagas';
      case CareType.other:
        return 'Otro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(_getIcon()),
        ),
        title: Text(_getLabel()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFmt.format(log.performedAt)),
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                log.notes!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Eliminar registro'),
                content: const Text('¿Seguro que quieres eliminar este registro?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              onDelete();
            }
          },
        ),
      ),
    );
  }
}

class _AddCareLogDialog extends StatefulWidget {
  final String plantId;
  final void Function(CareLog) onAdd;

  const _AddCareLogDialog({
    required this.plantId,
    required this.onAdd,
  });

  @override
  State<_AddCareLogDialog> createState() => _AddCareLogDialogState();
}

class _AddCareLogDialogState extends State<_AddCareLogDialog> {
  CareType _selectedType = CareType.watering;
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (time == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _save() {
    final log = CareLog(
      id: const Uuid().v4(),
      plantId: widget.plantId,
      careType: _selectedType,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      performedAt: _selectedDate,
    );

    widget.onAdd(log);
    Navigator.pop(context);
  }

  String _getCareTypeLabel(CareType type) {
    switch (type) {
      case CareType.watering:
        return 'Riego';
      case CareType.fertilizing:
        return 'Abonado';
      case CareType.pruning:
        return 'Poda';
      case CareType.transplanting:
        return 'Trasplante';
      case CareType.pestControl:
        return 'Control de plagas';
      case CareType.other:
        return 'Otro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return AlertDialog(
      title: const Text('Registrar cuidado'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<CareType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo de cuidado',
                border: OutlineInputBorder(),
              ),
              items: CareType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getCareTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDateTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha y hora',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(dateFmt.format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
