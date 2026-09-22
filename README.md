# Block Puzzle

Aplicativo Android em Flutter, inspirado no gênero Block Puzzle: tabuleiro 8×8,
três peças por rodada, pontuação e recorde local. O jogo será offline, sem login,
anúncios ou WebView. O plano original está em
[plano_de_desenvolvimento_block_puzzle_game.md](plano_de_desenvolvimento_block_puzzle_game.md).

## Ambiente de desenvolvimento

No terminal Bash, a partir da raiz:

```bash
source scripts/env.sh
flutter doctor -v
flutter pub get
flutter analyze
flutter test
```

O Flutter fica em `.tools/flutter`; Dart vem junto com ele. Os caches Pub e
Gradle ficam em `.tools/` e não devem ser versionados. O SDK Android existente
fica em `~/Android/Sdk`. O script configura apenas a sessão atual, sem alterar
o perfil global do terminal. Se necessário, defina `ANDROID_HOME` e `JAVA_HOME`
antes de carregá-lo. A configuração do VS Code corresponde a esta máquina Linux.

Preparação validada com Flutter 3.47.5, Dart 3.13.4 e compilação de APK debug
ARM64. Consulte [o registro do ambiente](docs/ambiente.md) para versões e resultados.

Abra esta pasta no VS Code. As extensões recomendadas estão em
`.vscode/extensions.json`; as configurações de execução em `.vscode/launch.json`.
Abra um novo terminal integrado após mudanças de configuração.

Prefira um celular físico com depuração USB para economizar memória:

```bash
source scripts/env.sh
flutter devices
flutter run
```

Autorize a conexão USB na tela do celular. Use debug durante o desenvolvimento
para hot reload; `flutter run --release` serve para avaliar a versão otimizada.

```bash
flutter build apk --split-per-abi
```

Saída ARM64: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
A assinatura de distribuição será configurada antes de publicar.
Os downloads iniciais exigem internet; isso não altera o requisito de jogo offline.

## Etapas

1. **Preparação:** Flutter, ferramentas Android, editor e validação de build.
2. **Fase 1 — lógica (implementada):** `BoardLogic` em Dart puro; matriz 8×8; inserção válida e
   atômica; limpeza simultânea de linhas/colunas; pontuação e testes unitários.
3. **Fase 2 — interação:** tabuleiro responsivo, dock com três peças,
   arrastar e soltar, prévia de encaixe e reposição por rodada.
4. **Fase 3 — estado e persistência:** detectar ausência de movimentos entre
   todas as peças restantes; salvar recorde com `shared_preferences`.
5. **Fase 4 — polimento:** animações, áudio local com `audioplayers`, reinício,
   diálogo de game over e testes em celular.

Usaremos Provider para conectar estado e interface; a lógica do tabuleiro
permanecerá independente de widgets. As dependências de jogo serão adicionadas
nas respectivas fases.

## Lógica do jogo — Fase 1

O código em `lib/game/` é Dart puro, sem dependências de widgets ou serviços.
`Piece` contém offsets imutáveis e um ID de cor positivo. `Pieces` oferece
15 formatos: quadrados 1×1, 2×2 e 3×3; linhas horizontais e verticais de 2 a 5;
L, J, T e Z em orientações fixas. Geração de rodadas ficará para a Fase 2.

```dart
final board = BoardLogic();
final fits = board.canPlace(Pieces.square2, x: 3, y: 2);
final move = board.tryPlace(Pieces.square2, x: 3, y: 2);
// move == null: posição inválida, sem alterar tabuleiro ou pontuação.
// move != null: pontos e índices das linhas/colunas eliminadas.
```

Importe `package:block_puzzle/game/board_logic.dart` e
`package:block_puzzle/game/piece.dart`. As coordenadas começam em zero:
`x` é coluna, `y` é linha, e a matriz é acessada como `board.cells[y][x]`.
O getter retorna uma cópia imutável; `0` representa vazio. `board.score` acumula
os pontos e `board.reset()` inicia um tabuleiro vazio com pontuação zero.

Cada bloco colocado vale 1 ponto. O bônus por `n` linhas/colunas no mesmo
movimento é `10 × n × (n + 1) ÷ 2`: 10, 30, 60, 100… A fórmula generaliza
os exemplos do plano. Uma linha e uma coluna cruzadas contam como duas linhas;
ambas são detectadas antes da limpeza. Blocos restantes permanecem na posição,
sem gravidade. A limpeza ocorre dentro de `tryPlace`, evitando pontuação dupla.

Execute `flutter test --coverage` para validar as regras e gerar `coverage/lcov.info`.
Os testes cobrem limites, sobreposição, encaixes com espaços vazios, cores,
limpeza simultânea, combos, imutabilidade, catálogo e reinício.

A tela do celular continua exibindo “Block Puzzle”: a interface jogável será
implementada na Fase 2. Game over e persistência continuam previstos na Fase 3.

## Fontes de instalação

- [Instalação manual do Flutter](https://docs.flutter.dev/install/manual)
- [Flutter estável e versões](https://docs.flutter.dev/install/archive)
- [Preparação Android](https://docs.flutter.dev/platform-integration/android/setup)
- [Android Command-line Tools](https://developer.android.com/studio#command-tools)

As referências a JDK 17 e Android 34 no plano são a configuração proposta
originalmente. A configuração efetiva será validada com o template do Flutter
instalado e registrada em `docs/ambiente.md`.
