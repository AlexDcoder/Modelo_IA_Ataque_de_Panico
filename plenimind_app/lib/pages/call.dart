import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class CallPage extends StatefulWidget {
  static const String routePath = '/test-call';
  
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _callNumber() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Iniciando ligação...';
    });

    try {
      const number = '085991788561'; // set the number here
      bool? res = await FlutterPhoneDirectCaller.callNumber(number);
      
      setState(() {
        if (res == true) {
          _statusMessage = 'Ligação iniciada com sucesso!';
        } else if (res == false) {
          _statusMessage = 'Falha ao iniciar ligação';
        } else {
          _statusMessage = 'Resposta indefinida da ligação';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      // Limpa a mensagem após 3 segundos
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _statusMessage = '';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de Ligação'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phone,
                size: 80,
                color: Colors.blue.shade600,
              ),
              const SizedBox(height: 32),
              
              Text(
                'Teste de Ligação Direta',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Número: 085991788561',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: 200,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _callNumber,
                  icon: _isLoading 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.phone_in_talk),
                  label: Text(
                    _isLoading ? 'Ligando...' : 'Fazer Ligação',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              if (_statusMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _statusMessage.contains('Erro') 
                      ? Colors.red.shade50 
                      : Colors.green.shade50,
                    border: Border.all(
                      color: _statusMessage.contains('Erro') 
                        ? Colors.red.shade200 
                        : Colors.green.shade200,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusMessage.contains('Erro') 
                          ? Icons.error_outline 
                          : Icons.check_circle_outline,
                        color: _statusMessage.contains('Erro') 
                          ? Colors.red.shade600 
                          : Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _statusMessage.contains('Erro') 
                              ? Colors.red.shade800 
                              : Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 48),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, 
                             color: Colors.orange.shade600, 
                             size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Aviso:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Esta funcionalidade faz ligação direta sem passar pelo discador. '
                      'Certifique-se de ter as permissões necessárias configuradas.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}