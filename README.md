# Portal de Cliente — Mod Journey

Repositorio de los dashboards de cliente de **Mod Journey SPA**.

## 🌐 URL en producción

`https://cliente.modjourney.cl/{proyecto-cliente}/dashboard/`

## 📁 Estructura

```
public/
├── ad286-ridley/           # Ridley SPA — Proyecto Aguadulce 286
│   └── dashboard/
│       └── index.html
└── (futuros clientes...)
```

## 🚀 Cómo agregar un nuevo cliente

1. Crear carpeta en `public/` con el código del proyecto:
   ```
   public/sa11-awad/dashboard/index.html
   ```
2. Commit + push a `main`
3. EasyPanel auto-despliega
4. Compartir con cliente: `https://cliente.modjourney.cl/sa11-awad/dashboard/`

## 🔐 Acceso

Cada dashboard tiene su propia clave en el HTML (variable `ACCESS_KEY`).

| Cliente | URL | Clave |
|---------|-----|-------|
| Ridley SPA | `/ad286-ridley/dashboard/` | `ridley286` |

## 🛠️ Deploy

EasyPanel auto-despliega cada push a `main` usando el Dockerfile incluido.

- **Imagen base:** `nginx:alpine`
- **Puerto:** `80`
- **Config Nginx:** `nginx.conf` (gzip, cache, headers de seguridad)

## 📝 Tecnología

HTML/CSS/JS vanilla. Sin build step. Cada `index.html` es self-contained.
