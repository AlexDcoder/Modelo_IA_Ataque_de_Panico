import 'package:flutter/material.dart';
import 'package:plenimind_app/schemas/contacts/contact.dart';

class ContactItem extends StatelessWidget {
  final Contact contact;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;
  final bool isDisabled;

  const ContactItem({
    super.key,
    required this.contact,
    required this.isSelected,
    required this.onChanged,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(contact.imageUrl)),
      title: Text(
        contact.name,
        style: TextStyle(color: isDisabled ? Colors.grey : Colors.black),
      ),
      subtitle: Text(
        contact.phone,
        style: TextStyle(color: isDisabled ? Colors.grey : Colors.blue),
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: isDisabled ? null : onChanged,
      ),
      enabled: !isDisabled,
    );
  }
}
