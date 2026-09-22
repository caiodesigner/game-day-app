# Directive Document: Block Puzzle Jewel Clone (Flutter + VS Code)

Este documento orienta a criação de um aplicativo Android nativo no estilo **Block Puzzle**, leve, totalmente offline, sem login e sem uso de WebView. O desenvolvimento será realizado 100% no **VS Code**, otimizado para máquinas com recursos modestos (Core i5, 8GB RAM).

---

## 1. Mapeamento do Ambiente e Instalação Mínima

Para compilar o APK sem instalar a interface pesada do Android Studio, siga esta pilha de ferramentas:

### Requisitos no Sistema
1. **VS Code + Extensões:**
   - Flutter (`Dart Code`)
   - Flutter Widget Snippets
2. **Flutter SDK:** Baixe o SDK do Flutter e adicione ao `PATH` do sistema.
3. **JDK 17 (Java Development Kit):** Necessário para a compilação do Gradle no Android.
4. **Android Command-line Tools (sem Android Studio GUI):**
   - Baixe apenas as **Command Line Tools** do site oficial de desenvolvedores do Android.
   - Use o utilitário `sdkmanager` via terminal para instalar apenas o essencial:
     ```bash
     sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
     ```
   - Aceite as licenças executando:
     ```bash
     flutter doctor --android-licenses
     ```

---

## 2. Arquitetura e Stack do Projeto

* **Framework:** Flutter (versão estável mais recente).
* **State Management:** `flutter_bloc` ou `Provider` (para gerenciar estado do tabuleiro, pontuação e drag-and-drop de forma limpa).
* **Persistência Local:** `shared_preferences` (para guardar o Recorde / High Score sem precisar de banco de dados pesado).
* **Efeitos Sonoros & Animações:** `audioplayers` para sons locais de encaixe e limpeza de linha; animações nativas de opacidade e escala do Flutter.

---

## 3. Especificações do Jogo & Mecânicas

### A. Estrutura do Tabuleiro (Grid)
* **Tamanho:** Matriz 8x8 (64 células).
* **Estado de Célula:** Vazia (`0`) ou Ocupada (`1` ou ID da cor/bloco).
* **Validação de Preenchimento:**
  * Sempre que uma peça for posicionada, verificar se alguma linha horizontal ou coluna vertical ficou 100% preenchida.
  * Executar a limpeza simultânea de todas as linhas e colunas completadas.

### B. Peças (Dock Inferior)
* **Geração:** Três peças geradas aleatoriamente por rodada na área inferior.
* **Formatos Comuns:**
  * Bloco 1x1, 2x2, 3x3
  * Linhas/Colunas de tamanhos 2, 3, 4, 5
  * Formatos em "L", "T", "J", "Z"
* **Comportamento:**
  * O jogador clica e arrasta a peça (usando `Draggable` / `DragTarget` do Flutter ou detecção gestual).
  * Enquanto arrasta, destaca as células do grid onde a peça será solta se a posição for válida.
  * Se a posição for inválida, a peça retorna para a base.
  * Quando as 3 peças forem jogadas, uma nova rodada com 3 novas peças é gerada.

### C. Game Over & Validação
* Antes de permitir o movimento ou ao gerar novas peças, o jogo checa se **pelo menos uma** das peças disponíveis cabe em **qualquer lugar livre** do tabuleiro.
* Se nenhuma peça puder ser encaixada, acionar a tela/dialog de **Game Over**.

### D. Sistema de Pontuação
* **Colocação:** 1 ponto por cada quadrado individual do bloco encaixado.
* **Limpeza:** 10 pontos por linha/coluna eliminada.
* **Combos:** Bônus multiplicador se mais de uma linha/coluna for destruída no mesmo movimento (ex: 2 linhas = 30 pontos, 3 linhas = 60 pontos).

---

## 4. Design e Interface (UI/UX)

* **Estilo Visual:** Dark Neumorphism ou Modern Flat Cyberpunk/Jewel.
* **Layout:**
  1. **Cabeçalho:** Placares de *Pontuação Atual* e *Recorde (High Score)* com ícone de reiniciar/pausar.
  2. **Centro:** Tabuleiro 8x8 centralizado e responsivo.
  3. **Rodapé:** Dock horizontal contendo as 3 peças disponíveis ajustadas em tamanho reduzido até o toque.
* **Sem Anúncios / Sem Telas de Carregamento Web / 100% Offline**.

---

## 5. Roteiro de Desenvolvimento Prompt-by-Prompt (Instruções para o Codex/IA)

Passe as seguintes fases sequencialmente ao codificar com uma IA:

### Fase 1: Setup do Projeto e Grid Lógica
> "Crie a estrutura básica de um projeto Flutter. Implemente uma classe `BoardLogic` que gerencie uma matriz 8x8 em Dart. Inclua métodos para tentar inserir uma peça na coordenada (x, y), verificar se a posição é válida, limpar linhas/colunas cheias e calcular a pontuação."

### Fase 2: Componente do Tabuleiro e Drag & Drop
> "Crie a interface UI do tabuleiro 8x8 usando `GridView.builder`. Adicione a lógica de `DragTarget` nas células da grade e `Draggable` nas peças do dock inferior, permitindo arrastar os blocos até o tabuleiro com feedback visual de onde eles vão cair."

### Fase 3: Validação de Game Over e Persistência
> "Adicione a checagem automática de Game Over quando não houver movimentos válidos no tabuleiro para as peças restantes no dock. Integre o pacote `shared_preferences` para salvar e carregar o High Score do dispositivo."

### Fase 4: Efeitos Visuais, Áudio Local e Polimento
> "Adicione animações na destruição de blocos, efeito sonoro quando linhas são limpas e um diálogo moderno de Game Over com botão de reiniciar partida rápida."

---

## 6. Comandos para Gerar o APK no VS Code

Após concluir o código no VS Code, abra o terminal integrado (`Ctrl + '`) e rode os comandos:

1. **Testar no celular conectado via USB:**
   ```bash
   flutter run --release
   ```

2. **Gerar o arquivo APK standalone para instalar/compartilhar:**
   ```bash
   flutter build apk --split-per-abi
   ```
   *O APK final estará disponível na pasta:* `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
