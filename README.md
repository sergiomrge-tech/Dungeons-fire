# Dungeons Fires: As Cinco Brasas - v0.7.0

Repositório oficial independente: https://github.com/sergiomrge-tech/Dungeons-fire. Abra o `project.godot` na raiz deste repositório.

## Novos sistemas v0.7

- **Builds de expedição:** oito bênçãos temporárias melhoram dano, defesa, vida, esquiva, habilidades, postura ou recuperação. O saque de uma rota de risco oferece três escolhas; até quatro bênçãos podem compor a build. A Mesa de Cartografia permite refazer uma oferta uma vez por expedição.
- **Rotas ramificadas:** após cada sala, escolher entre o Santuário, que recupera 15% da vida, ou o Pacto de Caçada, que concede uma bênção e fortalece a próxima sala com campeão extra ou chefe fortalecido. O Pacto também aumenta o saque.
- **Sinergias de heróis:** Maela e Varek quebram postura em conjunto; Varek recebe um acompanhamento de brasa de Maela; Neris aplica marcas arcanas. Cada apoio tem recarga própria e só ativa ao acertar uma técnica compatível.
- **Refúgio ampliável:** cinco sobreviventes nomeados podem ser acolhidos ao recuperar as brasas regionais. Quatro projetos permanentes gastam ouro e minério: +1 poção inicial, +10% de ouro/minério dos inimigos, uma nova rolagem de bênçãos e +8% de vida máxima.
- **Contratos:** Juramento sem poções, Caçada de Campeões e Marcha Acelerada acrescentam objetivos e recompensas opcionais. O estado é salvo junto da expedição e migra sem apagar saves v0.6.
- **Cinco novos mobs:** Carrasco de Cinza (investida), Espectro do Sino (projétil que reduz movimento), Sentinela Ossária (bloqueio frontal), Acólito da Brasa Fria (bola de fogo em área) e Rastejante de Vidro (ataque rápido). Os atlas usam a identidade artística aprovada com paletas diferenciadas.

O relatório de implementação e os testes estão em `docs/QA_v0_7.md`. Esta revisão é do projeto Godot; não foi gerado um APK novo nesta etapa.

## Combate e iluminação v0.6

Animações com preparação, contato e recuperação, peso diferente nos três golpes e recuo curto nas reações. As oito poses autoradas por personagem e a identidade visual aprovada permanecem. Varek usa cortes e escudo dourados, Maela projéteis de energia azul-violeta e Neris flechas/rastros verdes. Os impactos são emitidos quando o dano é confirmado; a preparação não antecipa dano.

`combat_vfx.gd` anima fitas de luz, fagulhas, ondas no chão, pilares de brasa e o escudo. Seis PointLight2D reutilizados iluminam cenário/atores/props, sem atingir a interface. Partículas têm velocidade, gravidade, arrasto, rotação e desaparecimento gradual: faíscas, brasas, fragmentos arcanos, folhas, poeira e detritos. Limites: 240 partículas em pool fixo, 36 efeitos simultâneos, 48 projéteis e oito pontos por rastro. Não depende de bloom ou flashes de tela inteira. As capturas e vídeos do CI vêm do framebuffer do Godot; uma comparação com luz ligada/desligada confirma mudança real dos pixels.

## Primeira região v0.5

- Varek: combo de três golpes com entrada antecipada, corrida com aceleração, esquiva e avanço com colisão, breve pausa no impacto e defesa frontal com janela perfeita de 0,20 s. A técnica de proteção usa escudo; não lança magia. As oito poses originais foram preservadas e o ritmo/movimento refinado.
- Mina dos Sinos: entrada, galeria de trilhos com obstáculos reais, depósito com elite e baú, abrigo seguro com descanso e baú e arena do Capataz Rusk. Quatro pinturas novas, atlas de oito props, navegação ao redor de objetos, bloqueio de tiros e saque sem duplicação após retomar.
- Garron: corte frontal, impacto e investida, avisos fixos no chão, janela de recuperação e segunda fase em 55% de vida. Rusk utiliza impacto e corte com recuperação.
- Recompensa regional: Núcleo de Garron libera a receita Marca do Portão na Forja 2. Uma defesa válida carrega o próximo golpe: +25% de dano e 2,5x dano de postura, com brilho dourado. A receita migra nos saves anteriores; esquiva não carrega o efeito.
- O acampamento, a interface clássica e o mapa visível aprovados permanecem como referência.

A validação e a exportação Android desta versão ficam registradas em `docs/QA_v0_5.md`. O APK legado de `builds/` permanece imutável. As novas prévias Android têm identificador próprio e são entregues diretamente no chat.

## Interface clássica v0.4 — opção 1 aprovada

Madeira escura, bronze e texto marfim compõem o layout escolhido por Sergio. O refúgio usa barra inferior com ícones e acesso central à exploração; o retrato, nível, experiência e recursos leem os dados reais do save. A composição do hub segue a opção 1: melhorias do refúgio pela fogueira, menu pelo retrato, história pelo diário e retomada quando há expedição salva. O mapa preserva o cenário visível, com três marcos de masmorras e detalhes concentrados na faixa inferior. O tema é aplicado também às telas de mapa, mochila, forja, heróis e combate, mantendo posições e funcionamento dos controles touch. O módulo de produção `scripts/classic_ui.gd` não depende de ferramentas ou cenas de teste. O APK v0.4.0 já entregue inclui o acampamento e esta interface.

## Refúgio como acampamento

A pedido de Sergio, o refúgio agora é uma clareira na floresta, com fogueira central e barracas. A direção fantasia anime aprovada, os heróis e a interface permanecem como referência visual. A fogueira recebe brilho e pequenas brasas animadas; a recuperação do refúgio acende as lanternas das barracas e acrescenta detalhes ao acampamento. O APK v0.4.0 já entregue inclui o acampamento.

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

A Mina tem cinco salas com composição própria. As demais quatorze expedições ainda usam encontros e arenas derivados de templates; não são quinze masmorras finais com level design exclusivo. Há 13 perfis de inimigos no total, incluindo cinco novas famílias comuns e chefes regionais. Cada herói ainda tem duas técnicas fixas; as 18 habilidades planejadas e árvores completas não estão implementadas. Talentos atuais aumentam vida/ataque; contratos de expedição já estão disponíveis, enquanto missões pessoais e arena ainda são futuros. Não há afixos aleatórios, desmontagem, loadouts, Veterano ou quatro sets visuais de armadura por herói.

Equipamentos repetidos ou recebidos com mochila cheia convertem em três minérios, regra temporária mostrada no inventário. Primeiras conclusões também garantem uma arma compatível. A duração de 8-15 minutos do GDD é uma meta futura; as arenas de v0.1 são mais curtas.

## Abrir e jogar

APK de teste: [Dungeons_Fires_v0_1_0_Android.apk](builds/Dungeons_Fires_v0_1_0_Android.apk). O planejamento completo está em [docs/GDD_v1.md](docs/GDD_v1.md) e [PDF](docs/GDD_v1.pdf).

Abra o `project.godot` desta pasta com Godot 4.6.1 ou versão compatível. Este repositório contém apenas Dungeons Fires. O import de assets é feito pelo editor. Android: APK para arm64, Android 7.0/API 24 ou superior, tela horizontal, sem acesso à internet obrigatório.

Teclado de teste: WASD/setas para andar; J/espaço golpe; K esquiva; Q/E técnicas; R suprema; H cura; F abrir baú próximo; Esc pausa/voltar. No celular, use o analógico e os botões desenhados na base da tela. Comece pela Mina dos Sinos no mapa.

## Validação

Execute no diretório do projeto:

```bash
godot --headless --editor --import --quit
godot --headless --script tests/test_game.gd -- --qa
godot --headless --script tests/test_combat_bot.gd -- --qa
godot --headless --script tests/test_run_systems_v07.gd -- --qa
```

O argumento QA usa saves separados e suprime áudio nos testes. Não distribua scripts internos de teste dentro do APK final.

Use o preset Android para exportação. `tools/package_android.py` remove apenas testes e assinaturas antigas, preserva metadados restantes, adiciona licenças, alinha a 16 KB, assina com chave privada externa e verifica o resultado com Android SDK Build Tools. Nunca inclua keystore ou senha no repositório. A chave deve ser preservada para permitir atualizações sobre o APK instalado.

`tools/import_visual_atlases.gd` reproduz o corte dos masters visuais e `tools/create_content.py` reproduz o catálogo. O antigo gerador está arquivado em `art_sources/legacy/`. A fonte DejaVu tem licença anexada. Não foram usados sprites ou músicas de Golden Axe.

Leia `docs/GDD_v1.md` para o projeto completo e `docs/QA_v0_1.md` para evidências e limitações desta build.
