import 'package:flutter/material.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';

class ContactItem extends StatelessWidget {
  final EmergencyContact contact;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;
  final bool isDisabled;
  final bool showPriority;

  const ContactItem({
    super.key,
    required this.contact,
    required this.isSelected,
    required this.onChanged,
    this.isDisabled = false,
    this.showPriority = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isSelected ? Colors.green : Colors.blue,
        child:
            contact.imageUrl.isNotEmpty
                ? ClipOval(
                  child: Image.network(contact.imageUrl, fit: BoxFit.cover),
                )
                : Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
      title: Text(
        contact.name,
        style: TextStyle(
          color: isDisabled ? Colors.grey : Colors.black,
          fontWeight:
              showPriority && contact.priority > 0
                  ? FontWeight.bold
                  : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contact.phone,
            style: TextStyle(color: isDisabled ? Colors.grey : Colors.blue),
          ),
          if (showPriority && contact.priority > 0)
            Text(
              'Prioridade: ${contact.priority}',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: isDisabled ? null : onChanged,
      ),
      enabled: !isDisabled,
      selected: isSelected,
      selectedTileColor: Colors.green.withValues(alpha: 0.1),
    );
  }
}
