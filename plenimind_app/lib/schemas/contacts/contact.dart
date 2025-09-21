// class Contact {
//   final String name;
//   final String phone;
//   final String imageUrl;
//   bool isSelected;

//   Contact(this.name, this.phone, this.imageUrl, {this.isSelected = false});
// }

// class ContactNode {
//   Contact contact;
//   ContactNode? next;

//   ContactNode(this.contact, {this.next});
// }

// class ContactLinkedList {
//   ContactNode? head;
//   int _size = 0;
//   final int maxSize;

//   ContactLinkedList({this.maxSize = 5});

//   int get size => _size;
//   bool get isEmpty => head == null;
//   bool get isFull => _size >= maxSize;

//   /// Adiciona contato no início da lista (prioridade alta)
//   bool addFirst(Contact contact) {
//     if (isFull) return false;

//     head = ContactNode(contact, next: head);
//     _size++;
//     return true;
//   }

//   /// Adiciona contato no final da lista (prioridade baixa)
//   bool addLast(Contact contact) {
//     if (isFull) return false;

//     if (isEmpty) {
//       head = ContactNode(contact);
//     } else {
//       ContactNode current = head!;
//       while (current.next != null) {
//         current = current.next!;
//       }
//       current.next = ContactNode(contact);
//     }
//     _size++;
//     return true;
//   }

//   /// Remove contato por nome
//   bool remove(String contactName) {
//     if (isEmpty) return false;

//     if (head!.contact.name == contactName) {
//       head = head!.next;
//       _size--;
//       return true;
//     }

//     ContactNode current = head!;
//     while (current.next != null) {
//       if (current.next!.contact.name == contactName) {
//         current.next = current.next!.next;
//         _size--;
//         return true;
//       }
//       current = current.next!;
//     }
//     return false;
//   }

//   /// Verifica se contato existe na lista
//   bool contains(String contactName) {
//     ContactNode? current = head;
//     while (current != null) {
//       if (current.contact.name == contactName) return true;
//       current = current.next;
//     }
//     return false;
//   }

//   /// Converte lista encadeada para List<Contact>
//   List<Contact> toList() {
//     List<Contact> result = [];
//     ContactNode? current = head;
//     while (current != null) {
//       result.add(current.contact);
//       current = current.next;
//     }
//     return result;
//   }

//   /// Limpa toda a lista
//   void clear() {
//     head = null;
//     _size = 0;
//   }

//   /// Reordena a lista baseado na nova ordem
//   void reorder(List<Contact> newOrder) {
//     clear();
//     for (Contact contact in newOrder) {
//       addLast(contact);
//     }
//   }
// }


class Contact {
  final String id;
  final String name;
  final String phone;
  final String imageUrl;
  final int priority;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.imageUrl,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'img': imageUrl,
        'priority': priority,
      };

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
        id: j['id'],
        name: j['name'],
        phone: j['phone'],
        imageUrl: j['img'],
        priority: j['priority'],
      );
}
