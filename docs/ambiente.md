# Preparação do ambiente — 22/09/2026

## Ferramentas

| Componente | Configuração |
| --- | --- |
| Sistema | Ubuntu 24.04.4 LTS, x64 |
| Flutter | 3.47.5 stable, commit `6a19cca56475dbfba1478ee68d7bd0c2ef891da1` |
| Dart | 3.13.4, incluído no Flutter |
| Java utilizado | OpenJDK 21.0.12.1 já instalado |
| Alvo Java/Kotlin do app | JVM 17, conforme template Flutter |
| Android compile/target SDK | API 36, conforme template Flutter |
| Android Build-Tools | 36.0.0, instalado automaticamente pelo build |
| Android Command-line Tools | pacote Linux `15859902`, instalado nesta preparação |
| Gradle / Android Gradle Plugin | 9.3.1 / 9.1.0, conforme template Flutter |
| VS Code | Flutter e Dart 3.142.0; Flutter Widget Snippets 3.0.0 |

SDK Flutter instalado em `.tools/flutter` usando o repositório oficial, branch
`stable`. O manifesto de distribuição em storage.googleapis.com retornou HTTP
404; o clone oficial e o download do Dart funcionaram.

Command-line Tools instalado em `~/Android/Sdk/cmdline-tools/latest`, aproveitando
o SDK Android existente. SHA-256 conferido com a página oficial:
`4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583`.

O JDK 21 existente foi mantido. Compilar para JVM 17 não significa exigir que o
processo Gradle rode no JDK 17. Não fixamos Android 34 porque o template do Flutter
atual usa API 36. O Gradle foi limitado a heap de 2 GB e dois workers para reduzir
pressão de memória. Nenhum emulador novo ou Android Studio foi instalado.

## Verificação

- `flutter pub get`: dependências resolvidas; versões registradas em `pubspec.lock`.
- `dart format lib`: sem alterações pendentes.
- `flutter analyze`: sem problemas.
- Licenças Android aceitas com `flutter doctor --android-licenses`.
- `flutter doctor -v`: Flutter e Android toolchain aprovados.
- `flutter build apk --debug --target-platform android-arm64`: concluído com
  sucesso; APK em `build/app/outputs/flutter-apk/app-debug.apk`.
- Nenhum dispositivo Android conectado no diagnóstico inicial; teste físico pendente.
- Ferramentas para desktop Linux ausentes no `flutter doctor`; não são necessárias
  para este projeto, que gera apenas Android.

## Escopo entregue

Projeto Android mínimo, tela inicial com nome do app, configuração do editor,
script de ambiente, caches isolados e roteiro no README. As mecânicas do jogo
começam na Fase 1. O identificador `com.example.block_puzzle` e a assinatura de
debug são provisórios para desenvolvimento, não para publicação.

## Recriar o SDK Flutter em outra máquina Linux

```bash
git clone --depth 1 --branch 3.47.5 https://github.com/flutter/flutter.git .tools/flutter
source scripts/env.sh
flutter --version
flutter pub get
flutter doctor -v
```

Instale as [Command-line Tools oficiais](https://developer.android.com/studio#command-tools)
no SDK Android e os pacotes indicados pelo template/diagnóstico, se ausentes.
Consulte a [configuração Android do Flutter](https://docs.flutter.dev/platform-integration/android/setup).
Este projeto preserva o plano original como referência.

## Ajuste durante a Fase 3

A importação automática de projetos Java/Gradle do VS Code foi desativada neste
workspace (`java.import.gradle.enabled: false`, `gradle.autoDetect: off`). SDKs
em `.tools/` e saídas em `build/` também foram excluídos da importação Java.
Durante a validação, processos de importação do editor concorreram por memória
com o build, esgotando RAM e swap. O Flutter continua executando o Gradle
normalmente por `flutter run` e `flutter build apk`; o ajuste afeta a descoberta
pelo editor, não a compilação Android.

Após as interrupções do build, o Gradle foi reduzido para heap de 1 GB e um
worker, com Kotlin compilando no mesmo processo (`in-process`), para limitar
o consumo simultâneo de memória durante a compilação.

Validação final da Fase 3: 40 testes passaram, `flutter analyze` sem problemas
 e `flutter build apk --debug --target-platform android-arm64` concluído.
O APK atualizado está em `build/app/outputs/flutter-apk/app-debug.apk`.
Cinco daemons antigos de importação, identificados pelos logs como exclusivos
 deste workspace, foram encerrados para liberar memória.

## Validação da Fase 4

- `flutter analyze`: sem problemas.
- `flutter test`: 45 testes passaram.
- `flutter build apk --split-per-abi`: concluído para armeabi-v7a (13,8 MB),
  arm64-v8a (16,6 MB) e x86_64 (18,0 MB).
- Os três WAV foram conferidos dentro do APK ARM64.
- Manifesto de release conferido com `aapt`: sem permissão de internet.
- CMake 3.22.1 instalado automaticamente pelo build dos componentes nativos.
- Assinatura permanece a de desenvolvimento do template; publicação na loja
  ainda exige identidade e chave de distribuição próprias.
- Sons e sensação das animações no aparelho aguardam validação manual.
