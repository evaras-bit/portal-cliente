# Portal Cliente — AD286 Ridley

> Documento maestro del portal de Ridley SPA. **Vive fuera de `public/`**, por lo que NO se sirve a la web (el Dockerfile solo copia `public/` a nginx). Puede contener clave y procedimiento de deploy.
>
> Última actualización: **2026-05-29**.

---

## 1. Qué es

- **URL:** https://cliente.modjourney.cl/ad286-ridley/dashboard/
- **Clave de acceso:** `ridley286`
- **Cliente:** Ridley SPA · Contrato base **7.400 UF** · Entrega **15/07/2026**
- **Archivos del portal:**
  - `public/ad286-ridley/dashboard/index.html` — dashboard (HTML+JS vanilla, lee el JSON)
  - `public/ad286-ridley/data/proyecto.json` — TODOS los datos del dashboard
  - `public/ad286-ridley/data/config.json` — clave de acceso

El dashboard tiene 6 pestañas: **General · Estado de Avance (Gantt) · Estado de Pago (calendario) · Cartola Banco · Facturación · Adicionales**.

---

## 2. De dónde salen los datos

Pipeline diseñado: **Notion (5 bases) → n8n → GitHub (`evaras-bit/portal-cliente`) → Easypanel**.

⚠️ **Hoy los workflows de n8n están INACTIVOS.** Los datos se mantienen a mano editando `proyecto.json` + Notion en paralelo (Notion es la fuente de verdad). Ver `~/.claude/.../memory/n8n_notion_portal_sync.md` para IDs de bases y detalle del workflow.

**Fuente oficial de los pagos/facturas:** `~/Desktop/Facturas Ridley/Cartola_Ridley_FINAL_v4.xlsx`
(hojas: *Cartola Pagos RIDLEY*, *Facturas Emitidas*, *Adicionales*, *Comprobantes*).

---

## 3. Estructura de `proyecto.json`

| Bloque | Contenido | Origen |
|---|---|---|
| `meta` | proyecto, cliente, fecha_entrega, semanas/días restantes, ultima_actualizacion | Notion Proyectos |
| `resumen` | KPIs: contrato_base_uf, pagado_uf, pagado_clp, avance_financiero_pct, avance_fisico_pct, avance_fisico_compras_pct, total_adicionales_uf, saldo_por_cobrar_uf/_clp_aprox, proximo_ep_uf/_fecha, uf_referencia/_fecha | calculado + Notion Proyectos |
| `gantt` | `meses[]` + `partidas[]` (cada una: nombre, categoria, estado, semanas_activas, opcional milestone) | Notion Gantt |
| `estados_de_pago[]` | hitos: fecha, concepto, factura, pagado_clp, uf, estado (Pagado/Pendiente) | Notion EDP |
| `facturas_base[]` / `facturas_adicionales[]` | folio, tipo, emision, concepto, neto_clp, iva_clp, total_clp, total_uf | Notion Facturas |
| `cartola` | `resumen{}` + `movimientos[]` (id, fecha_pago, referencia, pagado_clp, uf, estado) | Notion Cartola |

**Estado actual (2026-05-29):** 24 EDP (20 pagados + 4 pendientes) · 12 facturas (10 base + 2 adic.) · 20 movimientos de cartola.

---

## 4. Reglas de negocio clave

### Avance Financiero = lo PAGADO (caja), NO lo facturado
- `pagado_uf` = suma de cada pago del EDP convertido a UF: **`uf = pagado_clp / UF_del_día`**.
- El **UF del día** se toma del Excel oficial, que pinta cada pago a la **UF de la factura del EEPP** (así los hitos cuadran exactos: EEPP30=1.704, EEPP60=2.220, EEPP90=444). Si no está en el Excel, usar UF oficial: `curl https://mindicador.cl/api/uf/DD-MM-YYYY` → `.serie[0].valor` (difiere ~décimas, preferir Excel).
- `avance_financiero_pct = pagado_uf / (contrato_base_uf + total_adicionales_uf) * 100`.
- `saldo_por_cobrar_uf = (contrato + adic) − pagado_uf`; `saldo_por_cobrar_clp_aprox = saldo_uf * uf_referencia` (**recalcular este CLP al cambiar la UF de referencia — suele quedar el viejo**).
- **Hoy:** 6.815,9 UF pagadas → **88,7%**; saldo 869,35 UF.
- El mismo `uf` por pago se rellena en `cartola.movimientos[]`; `cartola.resumen.total_pagado_uf` debe coincidir con `pagado_uf`.

### Calendario de Estados de Pago (pestaña "Estado de Pago")
- Muestra como tarjetas los EDP con `estado != 'Pagado'`.
- Los **hitos pendientes** van en `estados_de_pago` con `estado:'Pendiente'` y `pagado_clp:null`. **NO** se cuentan en `pagado_uf` (que es solo lo pagado).
- La suma de pendientes debe ≈ `saldo_por_cobrar_uf`. Hoy: 240 (29/05) + 280 (15/06) + 229 (30/06) + 120 (15/07) = 869 UF.

### Gantt (pestaña "Estado de Avance")
- El bloque de cada partida va SOLO en el mes de su **Mes término**, pintado con el color de su **Estado** (Terminado=verde, En progreso=naranja, Programado=gris). Entrega final = milestone (círculo).
- En `proyecto.json` cada partida lleva `estado` y opcional `milestone:true`; `semanas_activas` = semanas ISO del mes de término (may=W19-22, jun=W23-27, jul=W28-29).

---

## 5. Convenciones de render (`index.html`)

- **`renderCartola`** — orden DESCENDENTE por `fecha_pago`. Columnas: **Fecha · Concepto (`m.id`) · Referencia (`m.referencia`) · Pagado**. El Concepto del pago debe coincidir con el `Concepto` del EDP (se alinearon en Notion: C63→"Adicional Nov25 + Quincho Adic.", C65→"Adicional 106,31 UF", anticipo→"EEPP 130 — parcial 4 (200 UF) Base").
- **`renderFacturas`** — orden DESCENDENTE por `emision`. Al agregar una factura, recalcular `cartola.resumen` (n_facturas, total_neto_clp, total_iva_clp, total_con_iva_clp).
- **`renderCobros`** — el calendario descrito arriba.
- `avance_fisico_pct` / `avance_fisico_compras_pct` → de Notion Proyectos.

---

## 6. Cómo actualizar un dato (manual, workflows inactivos)

1. **Editar en Notion** la base que corresponda (Proyectos / Gantt / EDP / Facturas / Cartola) → fuente de verdad.
2. **Editar `public/ad286-ridley/data/proyecto.json`** en consecuencia (y recalcular los totales/KPIs afectados — ver reglas §4).
3. **Validar el JSON**: `python3 -c "import json; json.load(open('public/ad286-ridley/data/proyecto.json'))"`.
4. **Commit + push** a `main` (ver §7).
5. **Disparar deploy** en Easypanel (ver §7) y **verificar en vivo**.

---

## 7. Procedimiento de DEPLOY

⚠️ **Easypanel NO auto-deploya** (no hay webhook GitHub). Hay que dispararlo manual tras cada push.

```bash
cd portal-cliente
git add <archivos>
git commit -m "Ridley: <qué cambió>"
git push origin main

# Disparar rebuild en Easypanel:
curl -s -X POST 'https://5drhb2.easypanel.host/api/trpc/services.app.deployService' \
  -H 'Authorization: Bearer 9114d50569fbb35a968ca13203096e419b91ad3e1e29c5b01822268569a1b3c9' \
  -H 'Content-Type: application/json' \
  -d '{"json":{"projectName":"portal_cliente","serviceName":"cliente"}}'
# Respuesta {"result":{"data":{"json":null,...}}} = encolado OK

# Verificar (~1-2 min): que el JSON en producción tenga el dato nuevo
curl -s "https://cliente.modjourney.cl/ad286-ridley/data/proyecto.json?cb=$RANDOM" | python3 -m json.tool | head
```

> El deploy de nginx/Dockerfile afecta a **TODOS** los portales del service `cliente` (Ridley, etc.), no solo a Ridley. Editar solo datos de `ad286-ridley` es seguro; cambios en `nginx.conf`/`Dockerfile` impactan a todos.

---

## 8. ⚠️ TAREA PENDIENTE: arreglar el nodo `Build JSON` del workflow n8n

El workflow `sync-notion-to-json` (n8n, INACTIVO) tiene su nodo **`Build JSON` desfasado**. Si se ejecuta, **revertiría** dos cosas que hoy se calculan a mano:

1. **Gantt** — no incluye `estado`/`milestone` y lee `Semanas activas` (vacías) en vez de derivar el bloque del **Mes término**.
2. **Avance Financiero** — no convierte los pagos a UF (`Monto UF`), dejaría `pagado_uf` ≈ 0.

**Mitigación ya hecha:** se backfilleó `Monto UF` + `Valor UF` en las 20 filas pagadas del EDP en Notion, así que si el Build JSON sumara `Monto UF` el avance saldría bien. Pero el Gantt seguiría revirtiéndose.

**Acción pendiente:** actualizar el nodo `Build JSON` para (a) derivar `semanas_activas` del mes de `Mes término` + incluir `estado`/`milestone`, y (b) derivar `pagado_uf` de `Monto UF` (o de `pagado_clp / Valor UF`). Mientras tanto, **mantener los workflows inactivos** y editar a mano.

---

## 9. Historial

- **2026-05-29** — Sync completo desde Notion + Excel oficial:
  - Avance Financiero pasó a base "pagado UF" (88,7%); backfill UF en EDP de Notion.
  - Cartola y Facturas ordenadas descendente; columna "ID" → "Concepto"/"Referencia"; conceptos alineados con EDP.
  - Calendario con 4 hitos pendientes (869 UF); Próximo EP 240 UF / 29-05.
  - FAC-175 agregada (anticipo 200 UF).
  - Avance Físico 79% / Físico+Compras 82%; UF referencia $40.576,86.
  - nginx: no-cache para `/data/*.json`.
  - **Desplegado a producción.** Commits: `b041914` (sync principal), `49f4aa4` (ajuste físicos).
