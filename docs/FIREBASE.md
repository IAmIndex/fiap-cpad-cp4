# Login e cadastro reais no Firebase

O app utiliza automaticamente `lib/firebase_options.dart`, gerado para `academya-fiap-4547a`. Agora o login e o cadastro usam Firebase Authentication, sem usuários ficticios ou autenticação anonima.

## Arquivos de configuracao e .env

Nao coloque credenciais no `.env`: este projeto nao carrega variaveis desse arquivo. Ele esta declarado apenas como asset de build. O arquivo pode conter somente um comentario, sem valores.

| Arquivo | Conteudo |
| --- | --- |
| `lib/firebase_options.dart` | Configuracao FlutterFire de Android, web e Windows. |
| `android/app/google-services.json` | Configuracao nativa do mesmo aplicativo Android e projeto. |
| `firebase.json` | Metadados da CLI e caminho das regras; nao e uma chave de autenticacao. |
| `.env` | Nao e utilizado para inicializar Firebase. |

Para Android, as correspondencias entre JSON e Dart sao:

| No google-services.json | No FirebaseOptions.android |
| --- | --- |
| `project_info.project_id` | `projectId` |
| `project_info.project_number` | `messagingSenderId` |
| `client_info.mobilesdk_app_id` do cliente Android | `appId` |
| `api_key[0].current_key` do cliente Android | `apiKey` |
| `project_info.storage_bucket` | `storageBucket` |

O pacote Android registrado e `br.com.academya.flutter_application_1`. Os arquivos ja foram alinhados para `academya-fiap-4547a`. Foi encontrada uma configuracao nativa de `academya-fiap-98f4b` junto do Dart do projeto anterior; essa mistura pode causar `[core/duplicate-app]` na inicializacao, antes mesmo do login.

Para obter novamente os arquivos, abra **Configuracoes do projeto > Geral > Seus aplicativos > Android** no Console e baixe `google-services.json` para `android/app/google-services.json`. Para gerar as opcoes Dart e os metadados das plataformas, na pasta do projeto:

```powershell
flutterfire configure --project=academya-fiap-4547a --platforms=android,web,windows
```

Depois confira que os arquivos apontam para o mesmo projeto e gere um novo APK. Alterar arquivos no computador nao atualiza o APK ja instalado no celular. Nao use um arquivo do outro projeto nem coloque service accounts/chaves privadas no app.

Referencia: [configuracao FlutterFire](https://firebase.google.com/docs/flutter/setup) e [download da configuracao pelo Console](https://support.google.com/firebase/answer/7015592).

## 1. Habilitar e-mail/senha

1. Abra o [Console do projeto](https://console.firebase.google.com/project/academya-fiap-4547a/overview).
2. Acesse **Authentication > Metodo de login** (ou **Sign-in method**).
3. Adicione/habilite **E-mail/senha** e salve. Não e necessário habilitar link de e-mail sem senha.
4. O provedor **Anonimo** não e mais necessário para este app. Sessoes anonimas antigas não liberam acesso as telas de turmas.

Não é necessário criar usuários manualmente no Console nem baixar uma chave de administrador. As contas serao criadas pela tela **Criar conta**. Nunca coloque um JSON de service account ou chave privada dentro do aplicativo.

## 2. Criar o banco e publicar as regras

Se ainda não existir, crie o Cloud Firestore **(default)** na edição **Standard**, escolha a região e mantenha o plano Spark.

Substitua as regras antigas por todo o conteudo de [firestore.rules](../firestore.rules) em **Firestore Database > Regras** e clique em **Publicar**.

Alternativamente, na pasta do projeto, com a CLI autenticada na sua conta:

```powershell
firebase deploy --only firestore:rules --project academya-fiap-4547a
```

Esse comando publica somente as regras, não altera o provedor de login. O arquivo `firebase.json` já aponta para as regras versionadas. A publicação altera as permissões do banco: revise antes se outros aplicativos tambem utilizam este projeto. A configuração do Console e a publicação em produção não foram executadas automaticamente.

As regras permitem:

- Perfil em `users/{uid}`: somente o próprio usuário pode ler/gravar; campos de senha são proibidos.
- Turma nova: criador e primeiro membro precisam ser o UID autenticado.
- Entrada em turma: o usuário pode acrescentar somente seu próprio UID, sem remover outros membros nem trocar o criador.
- publicação: somente o criador publica; somente membros leem.
- Sessoes anonimas e acessos sem login: bloqueados.

Os metadados de turmas (incluindo código e UIDs dos membros) podem ser consultados por qualquer usuário autenticado para permitir a busca por código. O código não e uma barreira de privacidade para esses metadados. Para turmas privadas, essa descoberta/entrada deve ser movida para um fluxo de convites validado no servidor. Perfis e conteudo das publicações não ficam publicos.

Os documentos antigos de demonstracao não são apagados nem atribuidos automaticamente a novas contas. Crie novas turmas com sua conta real; documentos cujo criador era `user-student` ou `user-teacher` não representam seu UID Firebase.

## 3. Rodar e criar a conta

Encerre a execucao anterior e rode na pasta do projeto:

```powershell
flutter pub get
flutter run -d edge
```

Para Android:

```powershell
flutter devices
flutter run -d ID_DO_DISPOSITIVO
```

1. Toque em **Criar conta**.
2. Preencha nome completo e um e-mail seu.
3. Escolha uma senha de pelo menos 6 caracteres, com letras e numeros. Uma politica mais restritiva configurada no Firebase tambem sera aplicada pelo servidor.
4. Toque em **Cadastrar**. O cadastro autentica a conta e abre as turmas.
5. Uma conta nova comeca sem turmas. Crie uma turma e compartilhe seu código com outra conta.

As antigas credenciais de demonstracao não funcionam, a menos que uma conta com esse e-mail tenha sido realmente criada em Authentication.

## 4. Comprovar a persistencia real

1. Em **Authentication > Usuários**, localize o e-mail cadastrado e anote o **UID**. O provedor deve ser e-mail/senha, não anonimo.
2. Em **Firestore > Dados > users**, localize um documento com esse mesmo UID. Ele contem `fullName`, `email` e `updatedAt`, nunca a senha.
3. Crie uma turma. Em `classes`, confira `creatorId` e `memberIds` usando o UID real.
4. Crie uma publicação. Ela deve aparecer em `classes/{classId}/publications`.
5. Encerre completamente o processo do app e reabra. A sessão deve ser restaurada sem preencher a senha, e as turmas devem ser consultadas do servidor.
6. Toque em **Sair** e entre novamente com o mesmo e-mail/senha. Teste tambem uma senha incorreta: o acesso deve ser negado.
7. Em outro dispositivo, entre na mesma conta. Os dados da conta devem aparecer.
8. Para testar duas contas, crie uma segunda conta e entre pelo código da turma. Ela pode ler publicações, mas não publicar na turma criada pela primeira.

A identidade fica no Firebase Authentication. O SDK administra a senha; o aplicativo não salva senha em Firestore, Shared Preferences ou no modelo do usuário.

Se a conta aparecer em Authentication, mas faltar `users/{uid}`, o cadastro de identidade funcionou e a gravacao do perfil falhou. Corrija as regras/banco e toque em **Tentar novamente** ou **Atualizar turmas**. Não refaca o cadastro: o e-mail já estara registrado.

## Recuperar senha

Na tela de login, preencha o e-mail e toque em **Esqueci minha senha**. Confira a caixa de entrada e o spam. A mensagem do app e neutra para não revelar se o e-mail pertence a uma conta. Os modelos de e-mail podem ser ajustados em **Authentication > Modelos/Templates**.

## Atualizar o APK

```powershell
flutter build apk --release
flutter install -d ID_DO_DISPOSITIVO --release
```

O arquivo atualizado fica em `build/app/outputs/flutter-apk/app-release.apk`. O APK anterior não recebe estas mudanças automaticamente.

## Tempo real

A sessão de autenticação e acompanhada por `userChanges()`. As turmas e publicações são consultadas ao entrar/reabrir ou atualizar a lista. As gravações agora são pontuais, mas ainda não ha listeners `snapshots()` para publicações: não espere uma nova publicação em outro celular sem atualizar a lista ou entrar novamente.

## Testes locais

```powershell
flutter analyze
flutter test
```

Os testes Dart/widget usam servicos injetados, sem acessar o projeto real. Para verificar cadastro/login e regras no Firebase Emulator Suite, instale Node.js, Firebase CLI e Java 21 ou superior:

```powershell
firebase emulators:exec --project demo-academya --config firebase.emulators.json --only auth,firestore "node test/firebase_emulator_test.mjs"
```

Neste computador, o Java 21 do Android Studio pode ser selecionado antes do comando:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
```

O teste exige hosts locais e o projeto `demo-academya`; não cria usuários nem documentos em produção. Foram aprovados 52 testes Flutter e 26 verificacoes nos emuladores. Esses testes não comprovam que voce habilitou E-mail/senha ou publicou as regras no Console real.

O APK corrigido tambem foi executado no emulador Android contra o projeto real `academya-fiap-4547a`. Uma tentativa com conta ficticia inexistente retornou credenciais invalidas pelo Firebase Auth, confirmando a inicializacao e a resposta do servico, sem cadastrar usuarios reais. A existencia do banco Firestore foi confirmada por consulta de leitura da CLI; a gravacao de perfil e as regras publicadas ainda devem ser verificadas com sua conta real.

## Referencias

- [Autenticação e-mail/senha no Flutter](https://firebase.google.com/docs/auth/flutter/password-auth).
- [Persistencia e eventos da sessão](https://firebase.google.com/docs/auth/flutter/start).
- [Perfil e recuperação de senha](https://firebase.google.com/docs/auth/flutter/manage-users).
- [Regras do Firestore](https://firebase.google.com/docs/firestore/security/get-started).
