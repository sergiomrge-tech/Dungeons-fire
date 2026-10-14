# Dungeons Fires: As Cinco Brasas - v0.3.0

Repositório oficial independente: https://github.com/sergiomrge-tech/Dungeons-fire. Abra o `project.godot` na raiz deste repositório.

## Avanço v0.3 — Refúgio vivo e legibilidade do combate

- Refúgio começa a recuperar pontos de luz, bandeirolas e vegetação conforme conquistas da campanha e melhorias das oficinas. São sobreposições leves, sem alterar colisão ou saves antigos.
- Neris passa a aparecer no hub após as três primeiras expedições; o menu **Diário de Edrava** mostra progresso por capítulo, brasas recuperadas e próxima masmorra.
- Corrida ganha pequenas nuvens de poeira; esquiva cria imagens residuais; golpes exibem arcos luminosos sincronizados com a janela de impacto. Os 112 frames autorados continuam sendo a base.
- Suíte dedicada testa navegação do diário, desbloqueio do NPC, estados de combate e controles ao voltar ao hub. O workflow publica também capturas reais do refúgio recuperado e do diário, além do arquivo-fonte atualizado.

**Status:** nova implementação de código. O APK presente em `builds/` ainda corresponde à v0.1.0 e **não** demonstra estas alterações. A v0.3 deve passar pelo CI e pela avaliação real de jogabilidade/visual no Android antes de ser considerada aprovada.

## Nova direção visual v0.2

Visual de fantasia anime inspirado na referência Ragnarok Online: seis ambientes pintados, quatorze conjuntos de sprites, 112 poses, retratos e interface clara. Detalhes e limitações em [VISUAL_DIRECTION_v0_2](docs/VISUAL_DIRECTION_v0_2.md). O APK disponível em `builds/` ainda é a v0.1.0; esta atualização é do projeto Godot.

## O que esta versão permite jogar

- Hub com forja, fabricação, equipamentos, talentos iniciais e cinco estruturas aprimoráveis.
- Mapa com quinze expedições desbloqueadas em sequência, cinco temas e cinco salas por expedição.
- Varek inicialmente; Maela após três masmorras; Neris após seis. Seis famílias de arma com aparência correspondente.
- Combo, esquiva, duas técnicas por herói, suprema, poções e inimigos com aviso antes do golpe.
- Loot de recursos/equipamentos, 120 definições de itens, melhorias até +10 e relíquias de chefes.
- Save local com gravação temporária/backup e retomada preservando vida, poções, inimigos e saque.
- Controles por toque; opções de áudio, tremor, zoom e dificuldade História/Aventura.

## Escopo real e limites

Esta é uma base jogável em evolução, não o lançamento final descrito no GDD. Os personagens e ambientes ilustrados são originais. As poses produzidas foram integradas aos estados reais de combate; transições, alinhamento dos sprites e acabamento visual ainda podem ser refinados.

As quinze expedições usam encontros e arenas derivados de templates; não são quinze masmorras finais com level design exclusivo. Há três arquétipos comuns e variações de chefes. Cada classe tem duas técnicas fixas nesta versão; as 18 skills planejadas e as árvores completas ainda não estão implementadas. Talentos atuais aumentam vida/ataque. Estruturas Arquivo/Quartel têm aprimoramento persistente e leitura narrativa, mas missões pessoais/arena/contratos ainda são futuros. Não há afixos aleatórios, desmontagem, loadouts, Veterano ou quatro sets visuais de armadura por herói.

Equipamentos repetidos ou recebidos com mochila cheia convertem em três minérios, regra temporária mostrada no inventário. Primeiras conclusões também garantem uma arma compatível. A duração de 8-15 minutos do GDD é uma meta futura; as arenas de v0.1 são mais curtas.

## Abrir e jogar

APK de teste: [Dungeons_Fires_v0_1_0_Android.apk](builds/Dungeons_Fires_v0_1_0_Android.apk). O planejamento completo está em [docs/GDD_v1.md](docs/GDD_v1.md) e [PDF](docs/GDD_v1.pdf).

Abra o `project.godot` desta pasta com Godot 4.6.1 ou versão compatível. Este repositório contém apenas Dungeons Fires. O import de assets é feito pelo editor. Android: APK para arm64, Android 7.0/API 24 ou superior, tela horizontal, sem acesso à internet obrigatório.

Teclado de teste: WASD/setas para andar; J/espaço golpe; K esquiva; Q/E técnicas; R suprema; H cura; Esc pausa/voltar. No celular, use o analógico e os botões desenhados na base da tela. Comece pela Mina dos Sinos no mapa.

## Validação

Execute no diretório do projeto:

```bash
godot --headless --editor --import --quit
godot --headless --script tests/test_game.gd -- --qa
godot --headless --script tests/test_combat_bot.gd -- --qa
```

O argumento QA usa saves separados e suprime áudio nos testes. Não distribua scripts internos de teste dentro do APK final.

Use o preset Android para exportação. `tools/package_android.py` remove apenas testes e assinaturas antigas, preserva metadados restantes, adiciona licenças, alinha a 16 KB, assina com chave privada externa e verifica o resultado com Android SDK Build Tools. Nunca inclua keystore ou senha no repositório. A chave deve ser preservada para permitir atualizações sobre o APK instalado.

`tools/import_visual_atlases.gd` reproduz o corte dos masters visuais e `tools/create_content.py` reproduz o catálogo. O antigo gerador está arquivado em `art_sources/legacy/`. A fonte DejaVu tem licença anexada. Não foram usados sprites ou músicas de Golden Axe.

Leia `docs/GDD_v1.md` para o projeto completo e `docs/QA_v0_1.md` para evidências e limitações desta build.
