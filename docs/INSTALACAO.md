# Instalar o Academya no celular

## Android: instalar o APK pronto

1. No computador, abra a pasta do projeto:

```powershell
Set-Location 'C:\Users\Pichau\OneDrive\Desktop\Faculdade\Fiap\2_ano\Cross-Platform Application Development\2_Semestre\fiap-cpad-cp4'
```

2. O arquivo gerado fica em `build\app\outputs\flutter-apk\app-release.apk`. Para abrir essa pasta no Explorer:

```powershell
Invoke-Item .\build\app\outputs\flutter-apk
```

3. Conecte o celular ao computador com um cabo USB. No celular, escolha **Transferencia de arquivos** na notificacao USB.
4. Pelo Explorer, transfira `app-release.apk` para a pasta **Download** do celular.
5. No celular, abra **Arquivos** ou **Meus Arquivos**, entre em **Download** e toque em `app-release.apk`.
6. Se o Android pedir, permita **Instalar apps desconhecidos** para o gerenciador de arquivos que esta abrindo o APK. Volte ao arquivo e toque em **Instalar**.
7. Toque em **Abrir**. O aplicativo tambem aparece na lista de apps como **Academya**.

Nao e necessario instalar Flutter no celular. Esta instalacao manual nao exige depuracao USB nem conta de desenvolvedor. Os nomes dos menus variam conforme a marca e a versao do Android.

## Android: instalar pelo Flutter via USB

1. No celular, abra **Configuracoes > Sobre o telefone > Informacoes do software** e toque sete vezes em **Numero da versao** (em alguns aparelhos, **Numero da compilacao**).
2. Abra **Opcoes do desenvolvedor** e ative **Depuracao USB**.
3. Conecte o cabo USB e confirme **Permitir depuracao USB** no celular.
4. No PowerShell, entre na pasta do projeto e liste os dispositivos:

```powershell
Set-Location 'C:\Users\Pichau\OneDrive\Desktop\Faculdade\Fiap\2_ano\Cross-Platform Application Development\2_Semestre\fiap-cpad-cp4'
flutter devices
```

5. Copie o ID mostrado na linha do seu celular (nao use `windows`, `edge` nem o ID de um emulador) e substitua `ID_DO_CELULAR`:

```powershell
flutter install -d ID_DO_CELULAR --release
```

6. Abra **Academya** no celular. Para executar enquanto desenvolve, com logs e hot reload:

```powershell
flutter run -d ID_DO_CELULAR
```

Se aparecer `unauthorized`, desbloqueie o aparelho e confirme a autorizacao USB. Se nao aparecer na lista, verifique se o cabo transmite dados e se o Windows precisa do driver USB do fabricante.

## Gerar um novo APK depois de alterar o codigo

Na pasta do projeto:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Instale novamente o arquivo `build\app\outputs\flutter-apk\app-release.apk`. Este APK universal inclui as arquiteturas Android suportadas e dispensa escolher um arquivo por processador.

Se o build pedir ferramentas do Android SDK, abra **Android Studio > SDK Manager > SDK Tools**, selecione **Android SDK Command-line Tools (latest)** e **Android SDK Build-Tools**, e aplique. Depois execute:

```powershell
flutter doctor --android-licenses
flutter doctor -v
```

Leia e aceite as licencas no seu terminal. Gere novamente o APK quando o SDK estiver pronto.

## Primeiro acesso e temas

Habilite **E-mail/senha** e publique as regras conforme [FIREBASE.md](FIREBASE.md). No app, toque em **Criar conta** e cadastre nome completo, e-mail e senha de pelo menos 6 caracteres com letras e numeros. Nao existem mais contas mockadas no APK.

No icone de aparencia da barra superior, escolha **Modo claro**, **Modo escuro** ou **Seguir sistema**. A escolha permanece salva quando voce fecha o app.

As contas ficam no Firebase Authentication, e os perfis, turmas e publicacoes no Firestore. A sessao e restaurada ao reabrir o app. O primeiro cadastro/login e as gravacoes precisam de conexao; o app nao libera um login ficticio se o Firebase estiver indisponivel.

## iPhone

Um iPhone nao instala APKs. Para instalar a versao nativa iOS, e necessario um Mac com Flutter e Xcode, alem da configuracao de assinatura Apple. A pasta iOS pode ser gerada no Mac com `flutter create . --platforms=ios`; depois conecte o iPhone, configure a equipe de assinatura em `ios/Runner.xcworkspace` e use `flutter run -d ID_DO_IPHONE`. Para distribuir por TestFlight, e necessario configurar uma conta Apple Developer e gerar `flutter build ipa`. O build iOS nao foi realizado neste computador Windows.

## Referencias

- [Build e instalacao Android no Flutter](https://docs.flutter.dev/deployment/android).
- [Configurar Android no Windows](https://docs.flutter.dev/platform-integration/android/setup).
- [Build e distribuicao iOS](https://docs.flutter.dev/deployment/ios).
