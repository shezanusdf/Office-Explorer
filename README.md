# Office Explorer

A 2D pixel art office simulation game built with Godot 4.2.

## About

Navigate through an office environment, interact with NPCs, and complete tasks for your coworkers. Help Sarah get her coffee, deliver reports to the CEO, and more!

## NPCs

- **Sarah** - Needs a coffee from the break room
- **Mike** - Has quarterly reports for the CEO
- **Mr. Johnson (CEO)** - Waiting for reports
- **Tom** - Needs a stapler from the supply closet
- **Jenny (Receptionist)** - Has employee forms to sign
- **Dave (IT)** - Needs help restarting the server

## Controls

- **Arrow Keys / WASD** - Move
- **E / Space** - Interact with NPCs and items

## Development

### Requirements
- Godot 4.2+

### Export for Web
1. Open the project in Godot
2. Go to Project > Export
3. Select "Web" preset
4. Export to your web server

### Web Server Requirements
For the web export to work properly, your server must send these headers:
```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

These headers are required for SharedArrayBuffer support which Godot uses for threading.

## Assets

- Character sprites: Bob_16x16.png
- Tileset: Room_Builder_free_16x16.png, Interiors_free_16x16.png
- Items: Coffee cup, stapler, documents

## License

For personal use.
