import 'package:flutter/material.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';
import 'package:plenimind_app/pages/login.dart';
import 'package:plenimind_app/pages/splash.dart';
import 'package:plenimind_app/pages/settings.dart';
import 'package:plenimind_app/pages/status_page.dart';
import 'package:plenimind_app/service/account_service.dart';
import 'package:plenimind_app/service/auth_state_manager.dart';

class AppDrawer extends StatefulWidget {
  final String userEmail;
  final VoidCallback? onNavigate;
  final double screenWidth;
  final double screenHeight;

  const AppDrawer({
    super.key,
    required this.userEmail,
    this.onNavigate,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthManager _authManager = AuthManager();
  final AccountService _accountService = AccountService();
  final AuthStateManager _authStateManager = AuthStateManager();

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Logout'),
          content: const Text('Tem certeza que deseja sair da sua conta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      try {
        debugPrint('🔓 [DRAWER] Fazendo logout...');

        // ✅ Notificar que usuário fez logout
        _authStateManager.notifyLoggedOut();

        // ✅ 1. Parar qualquer timer/polling ativo
        debugPrint('🛑 [DRAWER] Parando polling/detecção...');

        // ✅ 2. Limpar dados sensíveis
        debugPrint('🗑️ [DRAWER] Limpando dados do aplicativo...');
        await _authManager.clearTokens();

        debugPrint('✅ [DRAWER] Logout realizado com sucesso');

        Navigator.of(context).pop(); // Fecha o drawer
        Navigator.of(context).pop(); // Fecha qualquer dialog aberto

        if (mounted) {
          Navigator.pushReplacementNamed(context, LoginPage.routePath);
        }
      } catch (e) {
        debugPrint('❌ [DRAWER] Erro ao fazer logout: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao fazer logout: $e')));
        }
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deletar Conta'),
          content: const Text(
            'Esta ação é IRREVERSÍVEL. Todos os seus dados serão deletados permanentemente.\n\n'
            'Suas permissões (contatos, notificações) serão mantidas para facilitar '
            'o recadastramento, mas seus dados pessoais serão perdidos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Deletar Permanentemente'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Row(
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Deletando conta...'),
                ],
              ),
            );
          },
        );

        await _authManager.reloadTokens();
        final token = _authManager.token;
        final userId = _authManager.userId;

        if (token == null || userId == null) {
          throw Exception('Dados de autenticação não encontrados');
        }

        final success = await _accountService.deleteAccount(userId, token);

        if (success) {
          Navigator.of(context).pop(); // Fecha dialog de carregamento

          Navigator.of(context).pop(); // Fecha o drawer

          // ✅ Notificar que conta foi deletada
          _authStateManager.notifyAccountDeleted();

          // ✅ Limpar tokens após sucesso
          debugPrint('🗑️ [DRAWER] Limpando tokens após exclusão...');
          await _authManager.clearTokens();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '✅ Conta deletada com sucesso. Suas permissões foram mantidas para recadastramento.',
                ),
                duration: Duration(seconds: 3),
              ),
            );

            await Future.delayed(const Duration(seconds: 1));
            // Voltar para Splash para permitir recadastramento
            Navigator.pushReplacementNamed(context, SplashPage.routePath);
          }
        } else {
          Navigator.of(context).pop(); // Fecha dialog de carregamento

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Erro ao deletar conta. Tente novamente.'),
              ),
            );
          }
        }
      } catch (e) {
        // Fecha dialog de carregamento se ainda estiver aberto
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        debugPrint('❌ [DRAWER] Erro ao deletar conta: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao deletar conta: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(widget.screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: widget.screenWidth * 0.1,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: widget.screenHeight * 0.02),
                Text(
                  widget.userEmail,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(Icons.home, size: widget.screenWidth * 0.06),
                  title: Text(
                    'Status',
                    style: TextStyle(fontSize: widget.screenWidth * 0.04),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                    ).pushReplacementNamed(StatusPage.routePath);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings,
                    size: widget.screenWidth * 0.06,
                  ),
                  title: Text(
                    'Configurações',
                    style: TextStyle(fontSize: widget.screenWidth * 0.04),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(SettingsPage.routePath);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.help, size: widget.screenWidth * 0.06),
                  title: Text(
                    'Sobre',
                    style: TextStyle(fontSize: widget.screenWidth * 0.04),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sobre - PleniMind v1.0')),
                    );
                  },
                ),
              ],
            ),
          ),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.screenWidth * 0.04,
              vertical: widget.screenHeight * 0.02,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: _handleLogout,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: widget.screenHeight * 0.015,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: widget.screenWidth * 0.05),
                          SizedBox(width: widget.screenWidth * 0.02),
                          Text(
                            'Fazer Logout',
                            style: TextStyle(
                              fontSize: widget.screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: widget.screenHeight * 0.015),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: _handleDeleteAccount,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.shade50,
                      foregroundColor: Colors.orange.shade700,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: widget.screenHeight * 0.015,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_forever,
                            size: widget.screenWidth * 0.05,
                          ),
                          SizedBox(width: widget.screenWidth * 0.02),
                          Text(
                            'Deletar Conta',
                            style: TextStyle(
                              fontSize: widget.screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
