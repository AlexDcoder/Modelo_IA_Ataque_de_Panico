import 'package:flutter/material.dart';
import 'package:plenimind_app/components/terms_conditions/section.dart';

class TermsContent extends StatelessWidget {
  final double screenWidth;

  const TermsContent({super.key, required this.screenWidth});

  static final List<Map<String, String>> _sections = [
    {
      'title':
          'ANEXO I – TERMO DE CONSENTIMENTO PARA TRATAMENTO DE DADOS PESSOAIS',
      'content':
          'Pelo presente Termo, o Usuário, identificado no contrato principal de prestação de serviços do aplicativo móvel para detecção precoce de ataques de pânico, declara ter pleno conhecimento das práticas de coleta, uso, armazenamento e tratamento de seus dados pessoais e sensíveis, autorizando expressamente a Desenvolvedora, nos termos da Lei nº 13.709/2018 – Lei Geral de Proteção de Dados Pessoais (LGPD), a realizar o tratamento de seus dados conforme descrito neste documento.',
    },
    {
      'title': '1. FINALIDADE DO TRATAMENTO',
      'content':
          '1.1. Os dados pessoais e sensíveis coletados serão utilizados exclusivamente para:\n'
          'a) Monitoramento e análise de sinais fisiológicos visando à detecção precoce de ataques de pânico;\n'
          'b) Emissão de notificações automáticas ao Usuário em caso de detecção de episódio de pânico;\n'
          'c) Realização de chamadas de emergência para contatos previamente cadastrados pelo Usuário;\n'
          'd) Aprimoramento contínuo do desempenho do aplicativo por meio de técnicas de aprendizado de máquina (machine learning);\n'
          'e) Cumprimento de obrigações legais ou regulatórias, quando aplicável.',
    },
    {
      'title': '2. DADOS COLETADOS',
      'content':
          '2.1. Para execução das finalidades acima, poderão ser coletados os seguintes dados:\n'
          'a) Dados pessoais de identificação (nome, data de nascimento, CPF, e-mail, número de telefone);\n'
          'b) Dados sensíveis de saúde (frequência cardíaca, variações fisiológicas, histórico de episódios de pânico);\n'
          'c) Dados técnicos e de uso do aplicativo (horários de acesso, logs de atividade, informações de dispositivo e localização aproximada);\n'
          'd) Contatos de emergência indicados pelo Usuário, incluindo nome e telefone.',
    },
    {
      'title': '3. COMPARTILHAMENTO DE DADOS',
      'content':
          '3.1. Os dados pessoais e sensíveis poderão ser compartilhados apenas:\n'
          'a) Com prestadores de serviços de suporte técnico vinculados à Desenvolvedora, sob cláusulas de confidencialidade e segurança;\n'
          'b) Com serviços de telecomunicação necessários para execução de chamadas de emergência;\n'
          'c) Com autoridades públicas competentes, quando houver obrigação legal, judicial ou administrativa devidamente fundamentada.\n\n'
          '3.2. Nenhum dado será compartilhado com terceiros para fins comerciais, publicitários ou de marketing.',
    },
    {
      'title': '4. SEGURANÇA E PROTEÇÃO DOS DADOS',
      'content':
          '4.1. A Desenvolvedora adota medidas técnicas e administrativas adequadas à proteção dos dados pessoais e sensíveis, incluindo:\n'
          'a) Criptografia de dados armazenados e transmitidos;\n'
          'b) Controle restrito de acesso interno por autenticação;\n'
          'c) Registro de logs e rastreabilidade de acessos;\n'
          'd) Treinamento periódico de colaboradores sobre sigilo e privacidade.\n\n'
          '4.2. Em caso de incidente de segurança que possa acarretar risco ou dano relevante ao Usuário, este será comunicado em prazo razoável, nos termos do art. 48 da LGPD.',
    },
    {
      'title': '5. DIREITOS DO USUÁRIO',
      'content':
          '5.1. O Usuário poderá, a qualquer tempo, exercer seus direitos previstos nos arts. 17 a 22 da LGPD, incluindo:\n'
          'a) Confirmação da existência de tratamento de dados pessoais;\n'
          'b) Acesso, correção ou atualização de dados incompletos, inexatos ou desatualizados;\n'
          'c) Solicitação de anonimização, bloqueio ou eliminação de dados desnecessários ou tratados em desconformidade;\n'
          'd) Portabilidade dos dados pessoais, conforme regulamentação da Autoridade Nacional de Proteção de Dados (ANPD);\n'
          'e) Eliminação de dados pessoais tratados com base no consentimento;\n'
          'f) Revogação do consentimento, sem prejuízo da legalidade do tratamento anteriormente realizado.\n\n'
          '5.2. A solicitação de quaisquer desses direitos deverá ser formalizada por escrito, mediante contato com o Encarregado de Proteção de Dados (DPO) indicado pela Desenvolvedora.',
    },
    {
      'title': '6. RETENÇÃO E EXCLUSÃO DOS DADOS',
      'content':
          '6.1. Os dados pessoais serão mantidos pelo período necessário ao cumprimento das finalidades informadas, observando-se:\n'
          'a) As obrigações legais e regulatórias aplicáveis;\n'
          'b) O legítimo interesse da Desenvolvedora em manter registros para fins de segurança, auditoria e prevenção de fraudes;\n'
          'c) O prazo máximo de retenção de 05 (cinco) anos após o encerramento da relação contratual, salvo disposição legal em contrário.\n\n'
          '6.2. Após o término do período de retenção, os dados serão eliminados de forma segura e irreversível, por meios técnicos adequados.',
    },
    {
      'title': '7. BASE LEGAL DO TRATAMENTO',
      'content':
          '7.1. O tratamento dos dados pessoais e sensíveis do Usuário se fundamenta nas seguintes hipóteses legais:\n'
          'a) Consentimento do titular (art. 7º, I e art. 11, I da LGPD);\n'
          'b) Execução de contrato ou de procedimentos preliminares relacionados (art. 7º, V);\n'
          'c) Cumprimento de obrigação legal ou regulatória (art. 7º, II);\n'
          'd) Proteção da vida ou da incolumidade física do titular ou de terceiro (art. 7º, VII e art. 11, II, "e").',
    },
    {
      'title': '8. REVOGAÇÃO DO CONSENTIMENTO',
      'content':
          '8.1. O Usuário poderá revogar este consentimento a qualquer tempo, mediante solicitação expressa enviada à Desenvolvedora.\n'
          '8.2. A revogação implicará a suspensão do uso do aplicativo e o consequente encerramento do contrato principal, quando o tratamento de dados for essencial para sua operação.',
    },
    {
      'title': '9. DISPOSIÇÕES FINAIS',
      'content':
          '9.1. Este termo integra e complementa o Contrato de Prestação de Serviços firmado entre as partes, prevalecendo, em caso de conflito, as disposições mais restritivas à utilização e tratamento de dados pessoais.\n'
          '9.2. O Usuário declara ter lido, compreendido e aceitado integralmente o conteúdo deste termo, consentindo expressamente com o tratamento de seus dados pessoais e sensíveis conforme as condições aqui estabelecidas.\n\n'
          '[Local], [Data]\n\n'
          '[Nome do Usuário / Contratante]\n\n'
          '[Nome da Contratada / Desenvolvedora]',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                _sections
                    .map(
                      (section) => Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.04),
                        child: TermsSection(
                          title: section['title']!,
                          content: section['content']!,
                          screenWidth: screenWidth,
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }
}
