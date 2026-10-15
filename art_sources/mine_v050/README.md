# Mina dos Sinos — masters originais v0.5.0

Produzidos com ImageGen em 15/10/2026 a partir da direção do cenário `world_0.webp` já aprovado. Fantasy anime pintado, minas de cristais azuis e luz âmbar, sem extração de assets de outros jogos.

| Master | Recurso de produção | Uso |
| --- | --- | --- |
| rails.png | mine_rails.webp | Galeria dos Trilhos |
| store.png | mine_store.webp | Depósito do Capataz |
| rest.png | mine_rest.webp | Abrigo dos Mineiros |
| rusk.png | mine_rusk.webp | Arena de Rusk |
| props.png | mine_props.png | Atlas transparente 4×2 |

O atlas contém baú fechado/aberto, barril, carrinho com minério, portão fechado/aberto, braseiro e sino. `tools/import_mine_assets.gd` faz apenas redimensionamento/corte técnico para cenários 1280×720 e células 256×256, preservando os masters. A disposição, colisão e interações dos objetos são definidas em `data/mine_rooms.json` e nos scripts do jogo; as pinturas não incluem essas regras.

Master e pinturas são assets de produção, não capturas do jogo. As capturas são produzidas separadamente pelo framebuffer real no workflow de validação. Os masters são excluídos da exportação Android.
