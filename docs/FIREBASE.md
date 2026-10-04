# Login e cadastro reais no Firebase

O app utiliza automaticamente `lib/firebase_options.dart`, gerado para `academya-fiap-4547a`. Agora o login e o cadastro usam Firebase Authentication, sem usuarios ficticios ou autenticacao anonima.

## 1. Habilitar e-mail/senha

1. Abra o [Console do projeto](https://console.firebase.google.com/project/academya-fiap-4547a/overview).
2. Acesse **Authentication > Metodo de login** (ou **Sign-in method**).
3. Adicione/habilite **E-mail/senha** e salve. Nao e necessario habilitar link de e-mail sem senha.
4. O provedor **Anonimo** nao e mais necessario para este app. Sessoes anonimas antigas nao liberam acesso as telas de turmas.

Nao e necessario criar usuarios manualmente no Console nem baixar uma chave de administrador. As contas serao criadas pela tela **Criar conta**. Nunca coloque um JSON de service account ou chave privada dentro do aplicativo.

## 2. Criar o banco e publicar as regras

Se ainda nao existir, crie o Cloud Firestore **(default)** na edicao **Standard**, escolha a regiao e mantenha o plano Spark.

Substitua as regras antigas por todo o conteudo de [firestore.rules](../firestore.rules) em **Firestore Database > Regras** e clique em **Publicar**.

Alternativamente, na pasta do projeto, com a CLI autenticada na sua conta:

```powershell
firebase deploy --only firestore:rules --project academya-fiap-4547a
```

Esse comando publica somente as regras, nao altera o provedor de login. O arquivo `firebase.json` ja aponta para as regras versionadas. A publicacao altera as permissoes do banco: revise antes se outros aplicativos tambem utilizam este projeto. A configuracao do Console e a publicacao em producao nao foram executadas automaticamente.

As regras permitem:

- Perfil em `users/{uid}`: somente o proprio usuario pode ler/gravar; campos de senha sao proibidos.
- Turma nova: criador e primeiro membro precisam ser o UID autenticado.
- Entrada em turma: o usuario pode acrescentar somente seu proprio UID, sem remover outros membros nem trocar o criador.
- Publicacao: somente o criador publica; somente membros leem.
- Sessoes anonimas e acessos sem login: bloqueados.

Os metadados de turmas (incluindo codigo e UIDs dos membros) podem ser consultados por qualquer usuario autenticado para permitir a busca por codigo. O codigo nao e uma barreira de privacidade para esses metadados. Para turmas privadas, essa descoberta/entrada deve ser movida para um fluxo de convites validado no servidor. Perfis e conteudo das publicacoes nao ficam publicos.

Os documentos antigos de demonstracao nao sao apagados nem atribuidos automaticamente a novas contas. Crie novas turmas com sua conta real; documentos cujo criador era `user-student` ou `user-teacher` nao representam seu UID Firebase.

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
5. Uma conta nova comeca sem turmas. Crie uma turma e compartilhe seu codigo com outra conta.

As antigas credenciais de demonstracao nao funcionam, a menos que uma conta com esse e-mail tenha sido realmente criada em Authentication.

## 4. Comprovar a persistencia real

1. Em **Authentication > Usuarios**, localize o e-mail cadastrado e anote o **UID**. O provedor deve ser e-mail/senha, nao anonimo.
2. Em **Firestore > Dados > users**, localize um documento com esse mesmo UID. Ele contem `fullName`, `email` e `updatedAt`, nunca a senha.
3. Crie uma turma. Em `classes`, confira `creatorId` e `memberIds` usando o UID real.
4. Crie uma publicacao. Ela deve aparecer em `classes/{classId}/publications`.
5. Encerre completamente o processo do app e reabra. A sessao deve ser restaurada sem preencher a senha, e as turmas devem ser consultadas do servidor.
6. Toque em **Sair** e entre novamente com o mesmo e-mail/senha. Teste tambem uma senha incorreta: o acesso deve ser negado.
7. Em outro dispositivo, entre na mesma conta. Os dados da conta devem aparecer.
8. Para testar duas contas, crie uma segunda conta e entre pelo codigo da turma. Ela pode ler publicacoes, mas nao publicar na turma criada pela primeira.

A identidade fica no Firebase Authentication. O SDK administra a senha; o aplicativo nao salva senha em Firestore, Shared Preferences ou no modelo do usuario.

Se a conta aparecer em Authentication, mas faltar `users/{uid}`, o cadastro de identidade funcionou e a gravacao do perfil falhou. Corrija as regras/banco e toque em **Tentar novamente** ou **Atualizar turmas**. Nao refaca o cadastro: o e-mail ja estara registrado.

## Recuperar senha

Na tela de login, preencha o e-mail e toque em **Esqueci minha senha**. Confira a caixa de entrada e o spam. A mensagem do app e neutra para nao revelar se o e-mail pertence a uma conta. Os modelos de e-mail podem ser ajustados em **Authentication > Modelos/Templates**.

## Atualizar o APK

```powershell
flutter build apk --release
flutter install -d ID_DO_DISPOSITIVO --release
```

O arquivo atualizado fica em `build/app/outputs/flutter-apk/app-release.apk`. O APK anterior nao recebe estas mudancas automaticamente.

## Tempo real

A sessao de autenticacao e acompanhada por `userChanges()`. As turmas e publicacoes sao consultadas ao entrar/reabrir ou atualizar a lista. As gravacoes agora sao pontuais, mas ainda nao ha listeners `snapshots()` para publicacoes: nao espere uma nova publicacao em outro celular sem atualizar a lista ou entrar novamente.

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

O teste exige hosts locais e o projeto `demo-academya`; nao cria usuarios nem documentos em producao. Foram aprovados 49 testes Flutter e 26 verificacoes nos emuladores. Esses testes nao comprovam que voce habilitou E-mail/senha ou publicou as regras no Console real.

## Referencias

- [Autenticacao e-mail/senha no Flutter](https://firebase.google.com/docs/auth/flutter/password-auth).
- [Persistencia e eventos da sessao](https://firebase.google.com/docs/auth/flutter/start).
- [Perfil e recuperacao de senha](https://firebase.google.com/docs/auth/flutter/manage-users).
- [Regras do Firestore](https://firebase.google.com/docs/firestore/security/get-started).
