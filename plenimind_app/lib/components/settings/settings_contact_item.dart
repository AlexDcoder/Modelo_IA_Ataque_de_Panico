import 'package:flutter/material.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';

class SettingsContactItem extends StatelessWidget {
  final EmergencyContact contact;
  final Function(String) onRemove;
  final Function(String, int) onPriorityChange;
  final Function(String) onDuplicate; // NOVO CALLBACK
  final int maxPriority;
  final double screenWidth;

  const SettingsContactItem({
    super.key,
    required this.contact,
    required this.onRemove,
    required this.onPriorityChange,
    required this.onDuplicate, // NOVO PARÂMETRO
    required this.maxPriority,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: screenWidth * 0.02),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          contact.name,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.phone,
              style: TextStyle(fontSize: screenWidth * 0.035),
            ),
            SizedBox(height: screenWidth * 0.01),
            Row(
              children: [
                Text(
                  'Prioridade: ',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.02,
                    vertical: screenWidth * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    contact.priority.toString(),
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: screenWidth * 0.05),
          onSelected: (value) {
            if (value == 'remove') {
              onRemove(contact.id);
            } else if (value == 'increase_priority' && contact.priority > 1) {
              onPriorityChange(contact.id, contact.priority - 1);
            } else if (value == 'decrease_priority' &&
                contact.priority < maxPriority) {
              onPriorityChange(contact.id, contact.priority + 1);
            } else if (value == 'duplicate') {
              // NOVA OPÇÃO
              onDuplicate(contact.id);
            }
          },
          itemBuilder:
              (context) => [
                if (contact.priority > 1)
                  PopupMenuItem(
                    value: 'increase_priority',
                    child: ListTile(
                      leading: Icon(Icons.arrow_upward),
                      title: Text('Aumentar Prioridade'),
                    ),
                  ),
                if (contact.priority < maxPriority)
                  PopupMenuItem(
                    value: 'decrease_priority',
                    child: ListTile(
                      leading: Icon(Icons.arrow_downward),
                      title: Text('Diminuir Prioridade'),
                    ),
                  ),
                // NOVA OPÇÃO DE DUPLICAR
                PopupMenuItem(
                  value: 'duplicate',
                  child: ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Duplicar Contato'),
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Remover', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
        ),
      ),
    );
  }
}
