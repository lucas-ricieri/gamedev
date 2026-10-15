# Godot MCP

O servidor [blentz/godot-mcp](https://github.com/blentz/godot-mcp) foi instalado e registrado no Codex como `godot` em 10/10/2026.

## Usar

1. Reinicie o Codex para carregar o novo servidor MCP.
2. Abra `project.godot` desta pasta no Godot quando quiser usar as ferramentas do editor.
3. O complemento `godot_mcp` já está instalado e habilitado. A conexão funciona enquanto o editor desse projeto estiver aberto.

O projeto contém apenas a configuração inicial e o complemento. A cena principal e o jogo serão criados a partir das informações fornecidas depois da instalação.

## Instalação

- Código do servidor: `.tools/godot-mcp`.
- Revisão instalada: `735bdc9c98806e5ecdd05b819bc4ac461d9af935`.
- Entrada compilada: `.tools/godot-mcp/dist/server.js`.
- Node.js: `C:\Program Files\nodejs\node.exe`.
- Godot: `C:\Users\Ricieri\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.
- Configuração MCP: `C:\Users\Ricieri\.codex\config.toml`, servidor `godot`.
- `GODOT_PROJECT` aponta para `C:\Users\Ricieri\Documents\ChatGPT\GameDev`.

O servidor e os arquivos temporários ficam em `.tools`, ignorada pelo Git e pela importação do Godot. O complemento em `addons/godot_mcp` deve acompanhar o projeto.

## Ajustes locais de Windows

Foram corrigidos a comparação de URLs na inicialização do servidor, a detecção da área de trabalho e o encerramento da árvore de processos com `taskkill`. Os subprocessos de console usam `windowsHide`.

Os ajustes estão nos fontes instalados e também em `.tools/godot-mcp-windows.patch`. Preserve esse arquivo e reaplique os ajustes antes de recompilar se atualizar o servidor. Uma atualização pode exigir revisão do patch.

## Verificação

Passaram a negociação MCP, a descoberta das 50 ferramentas, a detecção do Godot 4.7.2, a criação e leitura de uma cena temporária, a validação de GDScript, a execução e parada do jogo, o timeout de processos no Windows e a comunicação com o editor (estado, seleção e execução de GDScript).

As sessões temporárias do Godot foram encerradas. O resultado está em `.tools/verification-report.json`. A captura de imagens e as ferramentas de C# não foram verificadas. Para C#, será necessário Godot .NET e um SDK .NET; o Godot instalado atualmente é a distribuição padrão.

Para conferir o registro no terminal:

```powershell
codex mcp get godot
```
