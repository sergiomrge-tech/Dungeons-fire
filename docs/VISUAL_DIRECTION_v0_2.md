# Direção visual v0.2 — fantasia anime

Em 14/10/2026, Sergio solicitou que o visual de Dungeons Fires seguisse Ragnarok Online. Esta decisão substitui a direção visual inicialmente proposta na seção 04 do GDD v1. Lore, personagens, combate em faixa de profundidade, hub, campanha, equipamentos e saves permanecem próprios de Dungeons Fires.

## Aplicado no projeto

- Seis cenários pintados com perspectiva elevada: Mina dos Sinos, mosteiro aquático, santuário nevado, forja desértica, arquivo noturno e Refúgio da Última Chama.
- Vila com telhados vermelhos/azuis, pedra clara, árvores e flores; regiões com paletas próprias e chão livre para as arenas existentes.
- Varek, Maela e Neris redesenhados em proporção anime, com variantes reais de espada/martelo, cajado/livro e arco/adagas.
- Três famílias comuns de inimigos e cinco chefes com o mesmo acabamento ilustrado. Quatorze atlases de oito poses, totalizando 112 frames autorados; 14 retratos extraídos desses atlases.
- Seleção de poses conectada aos estados reais de corrida, antecipação, contato, recuperação e técnica. Respiração, esquiva e morte recebem transformações complementares.
- Interface em marfim, azul e dourado; menu e hub mais abertos, retratos nos heróis, barras de vida/energia e controles touch com símbolos.
- Partículas ambientais limitadas por tema, ondulações no mosteiro e contorno nos números de dano.

## Fontes e reprodução

Produzido com ImageGen integrado. Masters preservados em `art_sources/`; metadados e especificações em `art_sources/manifest.json`. O corte técnico é reproduzido pelo Godot com `tools/import_visual_atlases.gd`. A pasta de masters possui `.gdignore` e não é exportada para o jogo. O gerador antigo foi preservado apenas como histórico em `art_sources/legacy/`.

O cenário é uma pintura 2D com perspectiva; não existe geometria 3D navegável nesta versão. Os sprites possuem poses autoradas, mas não animação em oito direções. Ragnarok é referência estética, sem cópia de mapas, personagens, interface ou sprites.

## Validação

Importação e parser Godot 4.6.1 sem erros. As 139 verificações de campanha, inventário, fabricação, salvamento e multitoque passaram. O bot venceu a primeira masmorra. A suíte visual verifica dimensões dos 14 atlases, 14 retratos, 6 cenários, sincronização da pose de ataque com o dano e descarte do HUD ao retornar ao hub.

`tests/capture_visuals.gd` produz exclusivamente capturas reais do framebuffer Godot: menu, hub, heróis, mapa, cinco regiões, maga e arqueira. O workflow publica essas imagens para revisão; imagens de produção nunca são apresentadas como capturas do jogo.

O APK em `builds/` continua sendo a v0.1.0. A v0.2 é uma atualização do projeto-fonte. Não houve medição de FPS, instalação ou teste de toque físico no aparelho Android.

## Revisão sobre v0.3

Capturas reais do Godot identificaram retratos que excediam o painel, barras com altura mínima incorreta e recortes de sprites com partes de linhas vizinhas. O importador agora usa limites por coluna, preserva a proporção com escala comum por personagem e alinha os pés. O HUD aplica o tamanho após configurar a expansão e atualiza o contador de poções. Barras de inimigos ficam restritas ao combate, sem aparecer nos NPCs da vila. A revisão preserva o diário, a recuperação do refúgio e os efeitos da v0.3.

## Refúgio aprovado como acampamento — 15/10/2026

Sergio aprovou a direção visual da v0.3.1. Preservar o estilo dos personagens, cenários e interface. Sua alteração específica para o hub substitui a cidade por acampamento com fogueira central, barracas e floresta atrás. O novo master original é `art_sources/hub_camp_v1.png`, convertido pelo importador para `assets/painted_worlds/hub_camp.webp`. Esse asset é usado no tema 5: menu, hub e diário. Os sistemas e saves continuam iguais. Lanternas, brasas e bandeirolas ficam ancoradas nos elementos do acampamento.
