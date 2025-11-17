# LuaCommandServer

A lightweight Tacview Lua add-on that opens a TCP/IP server to receive and execute Lua commands from external clients in real-time. Designed for testing, automation, and remote control of Tacview through the Lua API.

## How to use it?

1. Enable the **LuaCommandServer** add-on in Tacview.
2. Connect to the server from an external client (e.g., PuTTY in *Raw* mode, `nc`, or a custom script) using the configured IP address and port (50505 by default).
3. Each line you send will be executed as a Lua instruction in Tacview.
4. Responses, errors, or printed text will be sent back as JSON messages.

**Important:** Before running commands that call Tacview functions, you must enable the Tacview Lua API:

```lua
Tacview = require("Tacview195")
```

After that, you can call any available Tacview API function from your connection.

## Limitations

- This is **not** a security sandbox. Any Lua code sent by a connected client will have full access to the global Lua environment.
- Designed for **trusted environments** only. Do not expose the listening port to untrusted networks.
- Only one line (ending with `\n`) is treated as a complete command. Multi-line Lua chunks are not supported.
- Large or infinite outputs from `print` are not truncated by default - ensure your scripts produce reasonable output sizes.
- No built-in authentication or encryption.

## Troubleshooting

**I can connect but nothing happens**

- Make sure you end each command with a newline `\n`. Without it, the server will wait for the command to finish.

**PuTTY output looks weird (lines start in the middle)**

- In PuTTY, go to **Terminal** settings and enable **Implicit CR in every LF** so `\n` is rendered as a full new line.

**"Address already in use" on startup**

- Wait for the port to be released, or change the configured port number. The add-on tries to enable address reuse, but some platforms may still require a delay.

**Tacview API functions are not recognized**

- Remember to run `Tacview = require("Tacview195")` first in your connection session.

**I want to close the connection from the client**

- In PuTTY Raw mode, closing the window will disconnect. With `nc`, press **Ctrl+D** to send EOF and close the connection.
