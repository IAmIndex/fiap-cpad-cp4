# Academya

Aplicativo Flutter para comunicação entre professores e alunos em instituições escolares. O MVP centraliza turmas, grupos de estudo, comunicados, materiais e atividades em uma experiência mobile navegável, componentizada e preparada para sincronização com Firebase.

## Integrantes

| Nome | RM | Funcao |
| --- | --- | --- |
| Gustavo Hackime Costa | 563751 | Desenvolvedor / Planejador |
| Luiz Henrique Macedo Graca | 564704 | Planejador / Desenvolvedor |
| Riquelme Santos da Mata | 565053 | Designer / Organizador |

## Funcionalidades implementadas

- Login e cadastro reais com Firebase Authentication (e-mail/senha).
- Cadastro com nome completo e senha de pelo menos 6 caracteres, incluindo letras e números.
- Restauração da sessão, logout real e recuperação de senha por e-mail.
- Lista rolável de turmas do usuário, com nome, criador, tipo e código.
- Modal no botão `+` para entrar por código ou criar turma/grupo de estudos.
- Tela da turma com publicações persistidas no Firestore e faixa colorida por tipo.
- Modal de expansão para visualizar o conteúdo completo da publicação.
- Criação de publicação visivel somente para o criador da turma.
- Formulário de publicação com título ate 50 caracteres, descrição ate 900 caracteres, contador e tipo.
- Perfis em `users/{uid}`, turmas e publicações com gravações pontuais no Firestore.
- Layouts adaptados para celular, tablet, desktop e orientação horizontal.
- Formulários e modais roláveis com teclado aberto e suporte a fontes ampliadas.
- Modo claro, modo escuro e opção de seguir o sistema, com preferência salva no aparelho.

## Identidade visual

| Cor | Hexadecimal | Uso |
| --- | --- | --- |
| Foreground / Primaria | `#9381FF` | Ações principais |
| Background | `#2C2C29` | Fundo da aplicação |
| Surface | `#EEEBFF` | Cards e campos |
| Accent | `#E34A6F` | Destaques e acoes flutuantes |
| Dark Accent | `#580E20` | Contraste em textos e detalhes |

## Tecnologias

- Flutter e Dart.
- Material 3.
- Firebase Core, Firebase Auth e Cloud Firestore.
- Estado local com `ChangeNotifier` e `InheritedNotifier`, sem pacote externo de state management.
- Navegação pela API nativa do Flutter com rotas nomeadas.
- Shared Preferences para persistir a preferência de aparência.

## Estrutura de pastas

```text
lib/
  app/
    app.dart
    routes.dart
    theme.dart
  core/
    firebase/
      firebase_options.dart
      firebase_sync_service.dart
  data/
    models/
    repositories/
  features/
    authentication/
    classes/
    publications/
  shared/
    widgets/
```

## Como rodar

1. Instale as dependências:

```bash
flutter pub get
```

2. Rode em uma das plataformas versionadas (Android, Windows ou web):

```bash
flutter run -d windows
```

Para abrir no navegador ou no emulador Android:

```bash
flutter run -d edge
flutter emulators --launch Pixel_9a
flutter run -d emulator-5554
```

3. Habilite **E-mail/senha** em Authentication no Console Firebase, publique `firestore.rules` e crie sua conta pela tela **Criar conta**. O passo a passo está em [docs/FIREBASE.md](docs/FIREBASE.md).

Não existem contas de demonstração no app executado. Os dados fictícios ficam apenas em `test/support`, injetados nos testes. Uma conta nova comeca sem turmas; crie uma turma e compartilhe o código gerado.

## Firebase

O `FirebaseAuthenticationService` usa Firebase Auth para cadastro, login, nome do usuário, restauração da sessão e recuperação de senha. O modelo `AppUser` não contém senha. O `FirebaseSyncService` persiste o perfil por UID e grava somente a turma ou publicação alterada.

Sem Firebase disponivel, o app informa erro e não libera login mockado. Falhas do Firestore aparecem na tela de turmas com opcao de tentar novamente; uma falha ao salvar o perfil não apaga a conta já criada em Authentication. As regras versionadas protegem perfis por UID e publicações por membro/criador. Os metadados das turmas são consultaveis por usuários autenticados para a busca por código.

A configuração gerada pelo FlutterFire está em `lib/firebase_options.dart`, para o projeto `academya-fiap-4547a`, com aplicativos Android, web e Windows. O adaptador em `lib/core/firebase/firebase_options.dart` usa esse arquivo automaticamente. Os identificadores públicos do aplicativo não substituem regras de segurança do Firestore.

### Opção 1: FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

O arquivo gerado em `lib/firebase_options.dart` já é utilizado pelo app; não é necessário substituir arquivos nem passar `--dart-define`. Após reconfigurar, encerre a execução anterior e rode novamente o aplicativo. O guia para habilitar os serviços no console e comprovar gravação está em [docs/FIREBASE.md](docs/FIREBASE.md).

### Opção 2: dart-define

```bash
flutter run \
  --dart-define=FIREBASE_API_KEY=sua_api_key \
  --dart-define=FIREBASE_APP_ID=seu_app_id \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=seu_sender_id \
  --dart-define=FIREBASE_PROJECT_ID=seu_project_id \
  --dart-define=FIREBASE_AUTH_DOMAIN=seu_project.firebaseapp.com \
  --dart-define=FIREBASE_STORAGE_BUCKET=seu_project.appspot.com
```

Os valores de `--dart-define` são uma substituição opcional da configuração gerada. Habilite **E-mail/senha** e publique as regras no projeto utilizado. Login anônimo não é mais usado. O app consulta dados ao entrar/reabrir e ao atualizar a lista; ainda não há listeners de publicações em tempo real.

## Decisões técnicas

- O app separa telas por feature para facilitar manutenção e crescimento.
- O repositório coordena a sessão real e o estado das turmas/publicações do usuário.
- Firebase Auth e Firestore ficam isolados em servicos para permitir testes sem acessar contas reais.
- A criação de publicações verifica permissão pela autoria da turma.
- O app restaura a sessão persistida pelo SDK e inicia no login quando não há uma conta real autenticada.
- As cores dos componentes derivam do `ColorScheme` de cada tema, preservando contraste.
- Nomes de turmas e metadados usam quebra de linha; as listas reservam espaco rolavel para o botao flutuante.
- Os formulários mantém todos os campos montados durante a rolagem para preservar validação.
- Os modais limitam a altura disponível acima do teclado e rolam em telas baixas.

## Instalar no celular

O passo a passo de instalação por APK e por cabo USB está em [docs/INSTALACAO.md](docs/INSTALACAO.md).

O APK universal é gerado em `build/app/outputs/flutter-apk/app-release.apk`:

```powershell
flutter build apk --release
```

O nome exibido no Android é **Academya**. O APK usa a chave de debug local para assinatura, inclusive no modo release; publicar na Play Store requer configurar uma chave de release própria.

## Testes

```bash
flutter test
flutter analyze
```

Os testes cobrem login, cadastro inválido, criação de grupo, formulário de publicação, limites de 50/900 caracteres, seleção de tipo, expansão de conteúdo e logout. Os fluxos rodam nos temas claro/escuro em 320x568, 360x800, 430x932, 800x360, 320x640 com fonte 2x, 768x1024 e 1280x800, incluindo teclado aberto. Também verificam troca de tema sem perder navegação e restauração da preferência salva.

Os testes de autenticação verificam UID real, tratamento dos erros do SDK, cadastro, recuperação de senha, restauração da sessão, prevenção de envio duplicado e troca de conta sem expor dados anteriores. Os emuladores locais de Auth/Firestore validam cadastro/login e as regras contra acesso indevido. Instruções de execução em [docs/FIREBASE.md](docs/FIREBASE.md). Testes locais não comprovam a habilitação dos servicos no projeto real.

Capturas reais do emulador: [login claro](docs/previews/android-login.png), [turmas claras](docs/previews/android-light.png), [turmas escuras](docs/previews/android-dark.png) e [login escuro após reiniciar](docs/previews/android-login-dark.png).
