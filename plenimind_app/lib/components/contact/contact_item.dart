import 'package:flutter/material.dart';
import 'package:plenimind_app/schemas/contacts/emergency_contact.dart';

class ContactItem extends StatelessWidget {
  final EmergencyContact contact;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;
  final bool isDisabled;
  final bool showPriority;
  final double screenWidth;

  const ContactItem({
    super.key,
    required this.contact,
    required this.isSelected,
    required this.onChanged,
    this.isDisabled = false,
    this.showPriority = false,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: screenWidth * 0.06,
        backgroundColor: isSelected ? Colors.green : Colors.blue,
        child:
            contact.imageUrl.isNotEmpty
                ? ClipOval(
                  child: Image.network(contact.imageUrl, fit: BoxFit.cover),
                )
                : Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.045,
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
          fontSize: screenWidth * 0.04,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contact.phone,
            style: TextStyle(
              color: isDisabled ? Colors.grey : Colors.blue,
              fontSize: screenWidth * 0.035,
            ),
          ),
          if (showPriority && contact.priority > 0)
            Text(
              'Prioridade: ${contact.priority}',
              style: TextStyle(
                color: Colors.green,
                fontSize: screenWidth * 0.03,
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
