# AI Summary

*Read this first if you're an AI assistant answering follow-up questions about this project. It's a condensed, code-accurate map; the German sections below are the original design document, corrected where the implementation has diverged (last verified 2026-07-20 against commit `9fab4f5`).*

**Arcane Instability** is a Godot 4 (GDScript) local-multiplayer action-roguelike. The world is a 2D simulation grid rendered in 3D. Instead of hardcoded elements/spells, everything manipulates a small set of universal state axes on grid cells, materials, and entities. Damage is never direct — it's a side effect of state values exceeding tolerance thresholds.

**State model (as actually implemented):**
- **Energy channels** — `Thermal`, `Electrical`, `Arcane`, and **`Pressure`** (pressure is implemented as a 4th energy channel, not a separate axis). All share one base class, `EnergyProperty` (`entities/properties/energy_property.gd`), with `value`, `capacity`, `conductivity`, `decay`, `get_damage_value()` (negative/"cold" values don't damage), `get_diffusion_rate()`.
- **Impulse** is *not* stored per-object. It's a directional vector **derived each tick** from pressure differences between neighbouring cells (`GridCell.compute_impulse()`), decayed via `IMPULSE_DECAY`, used for knockback/movement and visualized by `ImpulseIndicator`. The old `ImpulseProperty` / `ImpulseCast` classes are dead stubs (comment-only, replaced by `PressureProperty`/`PressureCast`) — note the naming crossed over: the *stored* channel is called Pressure, the *derived* vector is called Impulse.
- **Structure** (`structure_property.gd`) — `value` + `recovery`, does not diffuse. Matches original design.
- **Conduction** (`conduction_property.gd`) — `value` only, static unless adjusted. Matches original design.
- Base class for all of the above: `EntityProperty` (`entities/properties/entity_property.gd`), which also has a `StatAdjustment`-based caching/source system not in the original design.

**Spell/module system — original design is dead code, actually implemented differently:**
- `modules/module.gd`, `energy_channel_module.gd`, `form_module.gd`, `modifier_module.gd` exist with enums matching the doc's "Energiekanal / Form / Modifikator" vocabulary, but are **never instantiated anywhere** — only referenced as unused typed vars in `spells/cast.gd`. Treat this whole folder as legacy/dead.
- What's actually live: `spells/cast.gd` defines `Cast.Axis = {ENERGY, PRESSURE, STRUCTURE, CONDUCTION}`, with one subclass per axis (`energy_cast.gd`, `pressure_cast.gd`, `structure_cast.gd`, `conduction_cast.gd`; `impulse_cast.gd` is a dead stub) plus a static `Cast.create(axis)` / `Cast.create_from_name(str)` factory. `core/player.gd` exposes 4 physical button slots (`BUTTON_R2/R1/L2/L1`, values 0-3) — **which axis fires on each button is chosen per-player in Build Selection** (`_resolve_axes()`/`_apply_build()`), not hardcoded. Assignment is free (an axis may be repeated across buttons or omitted entirely), defaulting to the historical R2=ENERGY/R1=PRESSURE/L2=STRUCTURE/L1=CONDUCTION order when no build data exists.
- Each `Cast` carries four modifier slots: `AreaModifier` (POINT/PROJECTILE/BEAM/AREA — the actual "form" concept, not Strahl/Aura/Mine/Kegel), `DistanceModifier` (range/cooldown), `EnergyTypeModifier` (THERMAL/ELECTRICAL/ARCANE, energy-axis only), `ExtensionModifier` (NONE/BOUNCING/INVERT/EXPLOSION — `INVERT` has no doc equivalent; doc's "Größer/Schneller/Durchdringt" have no direct equivalent).
- Pre-run loadout customization happens in a full **Build Selection UI** (`ui/build_selection.gd`, `core/build_registry.gd`, persisted to `user://build_selections.cfg`), where each of the 4 button slots gets both an axis dropdown and its 4 modifier dropdowns, validated by a small data-driven rule engine `spells/modifiers/modifier_validator.gd` against `ui/modifier_availability.json`. None of this existed when the original doc was written.

**World architecture:**
- `WorldObject` (`world/world_object.gd`) is the real anchoring abstraction — binds an `Entity` + `Substance` to a grid position, owns diffusion, energy-stress damage, and friction/traction physics. The doc talks about "cells" and "entities" but never mentions this class.
- Every grid cell also contains an invisible **`AirObject`** (`world/air_object.gd`) as the ambient medium that pressure/heat/etc. propagate through — not mentioned in the original doc, but central to how diffusion works.
- Materials are hardcoded in the `SubstanceRegistry` autoload (`entities/substance_registry.gd`), **not** resource files. Only 5 substances exist: `water`, `copper`, `grass`, `kindling`, `air`. None of the doc's examples (Stone, Wood, Metal) exist in code. `Substance` also has `energy_tolerance`/`energy_damage_scale` fields (not in original doc) used by `WorldObject._apply_energy_stress()` to damage a world object's own structure.
- Simulation tick order (`WorldSimulation._tick`): resolve pending casts → compute per-cell impulse from pressure gradients → tick every cell's world objects (conditions tick, properties decay, energy-stress → structure damage, `apply_pressure_wave()` for instant BFS pressure propagation on pressure casts) → invalidate property caches → diffuse energy channels (incl. pressure) to neighbours. There is no separate generic "reactions" step — the only reaction is `BurningCondition`'s temperature check plus the energy-tolerance→damage path, both folded into `tick()`.

**Conditions/status effects:** Only `BurningCondition` (`entities/conditions/burning_condition.gd`) exists as a real `Condition` subclass (self-sustaining fire above ignition temp). Other "status effects" from the original doc (frozen, fragile, knockback) are emergent from raw property values (e.g. cold slows movement via `GridCell` traction constants), not discrete `Condition` classes. Separately, `world/conditions/condition_state.gd` + ramp-up/running/ramp-down states drive VFX scale-in/out timing for condition visuals — purely presentational, unrelated to gameplay state.

**Enemies:** Standard FSM-based AI (`enemies/enemy.gd` + `enemies/states/*`: idle/wandering/following/attacking/recovering) with `NavigationAgent3D` pathing and detection `Area3D`, plus a wave-based `enemy_spawner.gd`. Not mentioned in the original doc at all. Damage still flows through the simulation (`DummyEnemy` injects thermal energy into the player's cell rather than dealing direct HP damage), consistent with "spells never deal direct damage."

**Damage model:** Matches the original design closely. `Character.take_stress(energy, pressure)` → `damage = (max(0, energy - energy_tolerance) + max(0, pressure - pressure_tolerance)) * damage_scale`, applied via `HealthComp`.

**UI/meta layers not in the original doc:** `ui/title_menu.gd`, `ui/build_selection.gd`, `ui/versus_hud.gd` (death counters, cooldown rings, respawns), `ui/health_bar.gd`, `ui/spell_marker.gd`; `core/resource_manager.gd` (autoload asset registry), `core/isometric_camera_3d.gd` (multi-target follow camera), `core/player_spawner.gd`; `world/debug_overlay.gd` (D-key raw axis value overlay, `world/views/temperature_view.gd` + `pressure_view.gd` are separate player-facing in-world VFX, not the debug overlay); `world/ground/*` (per-substance shader/texture loading), `world/impulse_indicator.gd`.

**When answering questions:** trust this AI summary and the corrected German sections over intuition from the section headers alone — several headers (e.g. "Module", "Statuseffekte") describe original intent that the current code has since replaced or extended. Verify against the actual `.gd` file before asserting behavior with confidence, since this doc can drift again.

---

# Arcane Instability – Simulationssystem

## Zusammenfassung

**Arcane Instability** ist ein Indie-Action-Roguelike mit simulationsbasierter Magie. Die Spielwelt wird in **3D dargestellt**, aber auf einem **2D-Grid simuliert**. Zauber besitzen keine festen Elemente oder hardcodierten Synergien, sondern manipulieren ausschließlich universelle Zustandsachsen:

* **Energie** (bestehend aus mehreren Energiekanälen, darunter auch Druck)
* **Impuls** (abgeleiteter Vektor aus Druckgefällen zwischen Zellen – Bewegung, Schockwellen, Rückstoß)
* **Struktur** (Härte, Stabilität, Brüchigkeit)
* **Leitung** (Ausbreitung von Energie und Impuls)

Die Energieachse besteht aus beliebig vielen **Energiekanälen**. Jeder Kanal verwendet dieselbe Simulationslogik (Wert, Verfall/Decay, Leitfähigkeit), unterscheidet sich jedoch durch seine Reaktionen.

Aktuell implementierte Energiekanäle:

* Thermisch (`thermal_energy.gd`)
* Elektrisch (`electrical_energy.gd`, noch ohne kanalspezifische Logik)
* Arkan (`arcane_energy.gd`, noch ohne kanalspezifische Logik)
* **Druck** (`pressure_property.gd`) – technisch ebenfalls ein Energiekanal, siehe unten

> **Hinweis (Stand 2026-07-20):** "Impuls" wurde intern in "Druck" (Pressure) umbenannt und als vierter Energiekanal implementiert, der wie Thermisch/Elektrisch/Arkan diffundiert. Der eigentliche Impuls-*Vektor* (Bewegung, Rückstoß) wird nicht mehr gespeichert, sondern pro Tick aus den Druckunterschieden benachbarter Zellen berechnet (`GridCell.compute_impulse()`) und über `ImpulseIndicator` visualisiert. `ImpulseProperty`/`ImpulseCast` sind nur noch leere Platzhalterdateien.

Neue Energiekanäle können jederzeit hinzugefügt werden, ohne Änderungen am Simulationskern vorzunehmen.

Jede Zelle, jedes Material und jede Entity besitzt Werte auf diesen Zustandsachsen. Materialien definieren zusätzlich lediglich wenige Konstanten wie Entzündungstemperatur, Kapazitäten, Leitfähigkeiten und (neu) Energie-Toleranz/Schadensskalierung. Es existiert keine materialspezifische Speziallogik.

Zauber verändern ausschließlich Zustände (z. B. **+Thermische Energie** oder **+Druck**). Effekte entstehen größtenteils aus generischen Regeln, die für alle Materialien und Entities gelten. Aktuell ist als konkrete Reaktion nur **Brennen** implementiert (siehe „Statuseffekte"); die übrigen in der ursprünglichen Planung genannten Reaktionen (Schmelzen, Erstarren, Zerbrechen, Explosion durch Kombination, …) sind Designziele und noch nicht als eigene Regeln im Code vorhanden.

Gegner verwenden dieselben Zustandsachsen wie Materialien. Zusätzlich besitzen sie **Integrität (HP)** sowie Belastungsgrenzen (`energy_tolerance`, `pressure_tolerance`). Schaden entsteht nicht direkt durch Zauber, sondern wenn Zustände diese Belastungsgrenzen überschreiten – das gilt auch für Gegnerangriffe (siehe „Gegner").

Die Simulation arbeitet ausschließlich lokal auf benachbarten Grid-Zellen.

Tatsächlicher Simulationsablauf (`WorldSimulation._tick`):

```
Anstehende Casts auflösen
    ↓
Impuls pro Zelle aus Druckgefälle berechnen
    ↓
Alle Zellen/WorldObjects ticken
  (Conditions ticken, Decay, Energie-Stress → Strukturschaden,
   ggf. Druckwelle sofort propagieren)
    ↓
Property-Caches invalidieren
    ↓
Energiekanäle (inkl. Druck) an Nachbarn diffundieren
```

Es gibt keinen separaten, generischen „Reaktionen"-Schritt – Reaktionen (aktuell nur Brennen) sowie Belastungsschaden laufen direkt innerhalb von `tick()`.

Die Steuerung erfolgt per Controller:

* Linker Stick → Bewegung
* Rechter Stick → Cursor/Zielrichtung
* Vier Schultertasten (R2/R1/L2/L1) feuern je einen Achsen-Cast ab (Energie/Druck/Struktur/Leitung) – siehe „Module & Casts".

Der Spieler wählt vor dem Run pro Taste sowohl die **Achse** (Energie/Druck/Struktur/Leitung) als auch deren **Modifikatoren** (Form, Reichweite, Energietyp, Zusatzeffekt) über eine eigene Build-Auswahl-UI.

> **Hinweis (Stand 2026-07-20):** Die Achsenzuordnung pro Taste ist frei wählbar (`core/player.gd::_resolve_axes()`) — eine Achse kann auf mehreren Tasten liegen oder ganz weggelassen werden. Ohne gespeicherten Build gilt weiterhin die historische Standardbelegung R2=Energie/R1=Druck/L2=Struktur/L1=Leitung.

Das Designziel bleibt ein **einfach implementierbares, konsistentes und datengetriebenes Simulationssystem**, in dem neue Zauber-Modifikatoren, Materialien oder Energiekanäle automatisch neue Interaktionen ermöglichen.

---

# Kernsystem

## Welt

* 3D-Darstellung, 2D-Simulationsgrid (`GridMap` + `GridCell`-Netzwerk, nur orthogonale Nachbarn)
* Simulation erfolgt ausschließlich lokal (Nachbarzellen)
* Zentrale Ankerklasse: `WorldObject` (`world/world_object.gd`) – bindet eine `Entity` + `Substance` an eine Grid-Position, verwaltet Diffusion, Energie-Stress-Schaden und Reibungs-/Traktionsphysik. Charaktere, Gegner, Grass etc. sind alle `WorldObject`-Subtypen.
* Jede Zelle enthält zusätzlich immer ein unsichtbares **`AirObject`** (`world/air_object.gd`) als Umgebungsmedium – trägt Druck/Wärme/etc. auch dort, wo kein „echtes" Objekt liegt. Ohne dieses Air-Objekt würde z. B. `GridCell.get_pressure()`/`get_temperature()` nicht funktionieren.

Jede Zelle enthält:

* Substanz/Material (über `Biome.get_substance()` aus der GridMap-Tile-ID aufgelöst, siehe unten)
* Zustände (Energiekanäle, Struktur, Leitung)
* optional eine Entity (Spieler, Gegner, Grass, …)

---

# Zustandsachsen

## Energie

Die Energieachse besteht aus mehreren Energiekanälen, gemeinsame Basisklasse `EnergyProperty` (Unterklasse von `EntityProperty`).

Gemeinsame Eigenschaften:

```text
value            # aktueller Wert
capacity         # Kapazität, z. B. für Temperaturberechnung
conductivity     # Ausbreitungsrate an Nachbarn
decay            # Verfall Richtung 0
```

Zusätzlich pro Kanal:

```text
get_damage_value()     # negative Werte (z.B. Kälte) verursachen keinen Schaden
get_diffusion_rate()   # Multiplikator für Diffusion, unabhängig von conductivity
```

Implementierte Kanäle:

```text
ThermalEnergy    # + get_temperature(ambient)
ElectricalEnergy # noch ohne kanalspezifische Logik
ArcaneEnergy     # noch ohne kanalspezifische Logik
PressureProperty # get_diffusion_rate() = 2.0, Basis für den abgeleiteten Impuls-Vektor
```

Alle Energiekanäle verwenden dieselbe Simulationslogik (`EnergyProperty.tick()` / `diffuse_to_neighbours()`).

---

## Impuls (Druck & abgeleiteter Vektor)

* **Druck** (`PressureProperty`) ist ein gespeicherter Energiekanal wie Thermisch/Elektrisch/Arkan – diffundiert und verfällt nach derselben Logik.
* **Impuls** im ursprünglichen Sinn (Bewegung, Schockwelle, Rückstoß) ist **nicht** gespeichert, sondern wird jeden Tick aus den Druckunterschieden benachbarter Zellen berechnet (`GridCell.compute_impulse()`), über `IMPULSE_DECAY` gedämpft und via `ImpulseIndicator` visualisiert.
* Druck-Casts können zusätzlich eine sofortige Druckwelle auslösen (`apply_pressure_wave()`, BFS-Ringausbreitung mit 50 % Abfall pro Ring), unabhängig von der normalen Pro-Tick-Diffusion.

---

## Struktur

Beschreibt:

* Härte
* Stabilität
* Brüchigkeit
* Verformbarkeit

Eigenschaften:

```text
value
recovery
```

Struktur breitet sich nicht aus (`structure_property.gd`: `tick()` erholt nur Richtung Basiswert, keine Diffusion). Entspricht dem ursprünglichen Design.

---

## Leitung

Beschreibt, wie gut Energie und Impuls auf benachbarte Zellen übertragen werden.

Eigenschaften:

```text
value
```

Statisch, außer durch explizite Anpassungen (`conduction_property.gd`). Entspricht dem ursprünglichen Design.

---

# Materialien

Materialien definieren ausschließlich Konstanten – keine Speziallogik. Anders als ursprünglich geplant gibt es **keine `.tres`-Ressourcendateien**; alle Substanzen sind fest im Autoload `SubstanceRegistry` (`entities/substance_registry.gd`) codiert.

Tatsächlich implementierte Substanzen (Stand 2026-07-20) – deutlich weniger als ursprünglich skizziert:

```text
water     – thermal_capacity=0.99, thermal_conductivity=0.1, unbrennbar
copper    – thermal_capacity=0.25, thermal_conductivity=0.2, unbrennbar
grass     – thermal_capacity=0.25, thermal_conductivity=0.2, burning_temperature=0.2
kindling  – thermal_capacity=0.9,  thermal_conductivity=0.05, burning_temperature=0.65
air       – Umgebungsmedium: thermal/electrical/arcane Kapazität+Leitfähigkeit,
            pressure_conductivity=0.92, structure=0, conduction_value=0.6
```

Die in der ursprünglichen Version genannten Beispiele (Stone, Wood, Metal) existieren nicht im Code.

`Substance` besitzt zusätzlich (neu, nicht im ursprünglichen Design):

```text
energy_tolerance       # Schwelle, ab der ein WorldObject durch eigene Energie Strukturschaden nimmt
energy_damage_scale    # Skalierung dieses Schadens
```

verwendet in `WorldObject._apply_energy_stress()`.

Materialien besitzen weiterhin keine Speziallogik.

---

# Module & Casts

> **Wichtig:** Das ursprüngliche Modul-System (`modules/module.gd`, `energy_channel_module.gd`, `form_module.gd`, `modifier_module.gd`) existiert im Code, wird aber **nirgends instanziiert** – es sind nur unbenutzte typisierte Variablen in `spells/cast.gd`. Es handelt sich um totes/veraltetes Design. Tatsächlich implementiert ist das unten beschriebene System aus vier Achsen-Casts (Achse pro Taste frei wählbar) mit Modifikator-Slots.

## Feste Achsen (statt frei wählbarer Module)

`spells/cast.gd` definiert `Cast.Axis = {ENERGY, PRESSURE, STRUCTURE, CONDUCTION}` mit je einer Subklasse:

```text
EnergyCast       (energy_cast.gd)
PressureCast     (pressure_cast.gd)
StructureCast    (structure_cast.gd)
ConductionCast   (conduction_cast.gd)
ImpulseCast       – toter Platzhalter, ersetzt durch PressureCast
```

`core/player.gd` bindet diese vier fest an die Schultertasten:

```text
R2 → EnergyCast
R1 → PressureCast
L2 → StructureCast
L1 → ConductionCast
```

Die vier Tasten sind **nicht** vom Spieler umbelegbar – anpassbar sind nur die Modifikatoren pro Achse.

## Modifikatoren (statt „Formen")

Jeder Cast besitzt vier Modifikator-Slots (`spells/modifiers/*.gd`):

```text
AreaModifier        POINT | PROJECTILE | BEAM | AREA        (entspricht am ehesten "Form")
DistanceModifier     AROUND_PLAYER | SHORT | MIDDLE | FAR    (Reichweite/Cooldown)
EnergyTypeModifier    THERMAL | ELECTRICAL | ARCANE           (nur bei EnergyCast)
ExtensionModifier     NONE | BOUNCING | INVERT | EXPLOSION
```

`NONE` wurde zuletzt ergänzt (Commit „Added extension modifier NONE"), `INVERT` (Effekt umkehren, z. B. Kühlen statt Erhitzen) existiert ohne Entsprechung im ursprünglichen Design. Die früher geplanten Formen „Aura", „Mine", „Kegel" sowie die Modifikatoren „Größer", „Schneller", „Durchdringt" sind nicht als eigene Konzepte implementiert.

`cast_projectile.gd` implementiert Projektilbewegung, kontinuierliche Effektanwendung („radiate", bei Nicht-Beam nur halbe Stärke) sowie einen Abprall-/Splitter-Mechanismus für `ExtensionModifier.BOUNCING`.

## Validierung & Build-Auswahl (neu, nicht im ursprünglichen Design)

* `spells/modifiers/modifier_validator.gd` – datengetriebene Regel-Engine (`{when: {...}, disallow: {...}}`), geladen aus `ui/modifier_availability.json`.
* `ui/build_selection.gd` + `core/build_registry.gd` – vollständiger Vier-Spieler-Loadout-Bildschirm (Name, Farbe, Modifikator-Auswahl pro Achse, Controller-Navigation), persistiert in `user://build_selections.cfg`, live gegen `modifier_validator.gd` geprüft. Ergebnis landet im statischen `BuildRegistry.builds`-Array, das `PlayerSpawner`/`Player._apply_build()` beim Spawn ausliest.

Dies ist die tatsächliche Umsetzung der ursprünglichen Idee „Spieler ordnet Module den Tasten zu vor dem Run" – mechanisch aber grundlegend anders (Modifikator-Auswahl pro fester Achse statt freie Achsen-/Formzuordnung).

---

# Primäre Reaktionen (Designziel, größtenteils noch nicht implementiert)

Die folgende Tabelle beschreibt weiterhin das **Designziel**. Implementiert ist aktuell nur Brennen (siehe „Statuseffekte") sowie generischer Belastungsschaden bei Überschreiten von `energy_tolerance`/`pressure_tolerance`.

| Bedingung                         | Reaktion                         | Status                     |
| ---------------------------------- | -------------------------------- | -------------------------- |
| Thermische Energie > Entzündung   | Entzünden                        | implementiert (`BurningCondition`) |
| Thermische Energie > Schmelzpunkt | Schmelzen                        | nicht implementiert        |
| Thermische Energie sehr niedrig   | Erstarren                        | nicht implementiert (nur Traktions-Effekt, s.u.) |
| Elektrische Energie hoch          | Elektrische Entladung            | nicht implementiert        |
| Arkane Energie hoch               | Arkane Überladung                | nicht implementiert        |
| Impuls > Struktur                 | Zerbrechen                       | nicht implementiert        |
| Druck hoch                        | Beschleunigen                    | implementiert (abgeleiteter Impuls-Vektor) |
| Struktur steigt/sinkt              | Verfestigen/Erweichen            | nicht als Reaktion, nur `recovery` |
| Leitung hoch                      | Energie oder Impuls weiterleiten | implementiert (Diffusion) |
| Thermische Energie + Druck hoch   | Explosion                        | nur über `ExtensionModifier.EXPLOSION` am Cast, nicht als Umgebungsreaktion |
| Wiederholter Impuls               | Erosion                          | nicht implementiert        |

---

# Gegner

Gegner sind normale `WorldObject`/Entity-Träger (`enemies/enemy.gd`, aktuell einzige konkrete Klasse: `dummy_enemy.gd`) und teilen dieselben Zustände wie Materialien plus:

```text
Integrity (HP)         → HealthComp
Energy Tolerance
Pressure Tolerance
damage_scale
```

Zusätzlich (neu, nicht im ursprünglichen Design) besitzen Gegner eine vollständige KI-Zustandsmaschine:

```text
enemies/states/enemy_idle_state.gd
enemies/states/enemy_wandering_state.gd
enemies/states/enemy_following_state.gd
enemies/states/enemy_attacking_state.gd
enemies/states/enemy_recovering_state.gd
```

mit `NavigationAgent3D`-Pathfinding und einer `Area3D`-Erkennungszone. `DummyEnemy` greift an, indem es thermische Energie direkt in die Zelle des Spielers injiziert (`sim.add_effect(...)`) – auch Gegnerangriffe laufen also über die Simulation statt über direkten HP-Schaden.

`enemies/spawner/enemy_spawner.gd` implementiert einen wellenbasierten Spawner (Anzahl Wellen, Gegner pro Welle, Wellen-Abschluss-Signale).

---

# Schaden

Schaden entsteht ausschließlich durch überschrittene Belastungsgrenzen – entspricht dem ursprünglichen Design und ist in `Character.take_stress()` umgesetzt:

```text
damage = (max(0, energy - energy_tolerance) + max(0, pressure - pressure_tolerance)) * damage_scale
```

Beispiel:

```text
ThermalEnergy = 120
Tolerance = 90

↓

30 Belastung

↓

Integrity verliert HP (via HealthComp.take_damage())
```

`WorldObject._apply_energy_stress()` wendet dasselbe Prinzip auch auf Materialien/Objekte selbst an (Substanz-`energy_tolerance` → Strukturschaden), nicht nur auf Charaktere.

Zauber verursachen weiterhin niemals direkten Schaden.

---

# Statuseffekte

Deutlich weniger generisch als ursprünglich geplant. Aktuell existiert nur **ein** konkreter `Condition`-Typ:

| Zustand                          | Effekt                | Implementierung |
| -------------------------------- | ---------------------- | ---------------- |
| Thermische Energie > Zündtemperatur | Brennt (selbsterhaltend, 9s Dauer) | `entities/conditions/burning_condition.gd` (`Condition`-Subklasse) |
| Sehr niedrige thermische Energie | Verlangsamt (nicht „eingefroren") | Traktions-Konstanten in `grid_cell.gd` (`get_traction()`), kein eigener `Condition`-Typ |
| Hoher Druck/Impuls                 | Rückstoß              | über abgeleiteten Impuls-Vektor, kein `Condition`-Typ |
| Niedrige Struktur                | Fragil                | nicht implementiert |
| Hohe Leitung                     | Leitet Energie weiter  | implizit über Diffusion |

Zusätzlich (neu, nur Präsentation, nicht Gameplay): `world/conditions/condition_state.gd` treibt zusammen mit `condition_ramp_up_state.gd`, `condition_running_state.gd`, `condition_ramp_down_state.gd` eine generische Zustandsmaschine für **VFX-Timing** (Skalierung beim Ein-/Ausblenden von Effekten wie Feuer), gesteuert über `condition_view.gd`. Das ist ein reines Präsentationssystem und beeinflusst keine Simulationswerte.

---

# Controller

```text
Linker Stick   → Bewegung
Rechter Stick  → Cursor / Zielrichtung (relativ zur Kamera)
R2/R1/L2/L1    → EnergyCast / PressureCast / StructureCast / ConductionCast (fest zugeordnet)
```

Tatsächlich verwendet wird ausschließlich `TwinstickPlayerController` (`Player._ready()` instanziiert ihn fest). Zwei weitere Controller-Klassen existieren im Code, werden aber **nicht** verwendet:

```text
WorldCursorPlayerController  – unabhängiger, "andockbarer" Cursor
FaceButtonsPlayerController  – Achsen auf X/B/Y/A statt Schultertasten
```

`core/input_manager.gd` hat außerdem einen defekten Pfad für Tastatur-Spieler (`device_id < 0`): er ruft `player.request_spell(i)`/`release_spell(i)` auf, die auf `Player` nicht existieren (nur `request_cast`/`release_cast`) – dieser Pfad würde bei Auslösung fehlschlagen.

Modifikatoren (siehe „Module & Casts") werden **vor** dem Run in der Build-Auswahl-UI festgelegt, nicht während des Runs per Tastenkombination.

---

# Simulations-Loop (tatsächlicher Ablauf)

```text
1. Anstehende Casts auflösen (apply_to_cell)

2. Impuls pro Zelle aus Druckgefälle berechnen (compute_impulse)

3. Jede Zelle / jedes WorldObject ticken:
   - Conditions ticken (Aktivierung/Deaktivierung prüfen, z.B. Brennen)
   - Energie-/Struktur-/Leitungs-Decay
   - Energie-Stress → Strukturschaden (_apply_energy_stress)
   - Charaktere: apply_stress_from_cell() → HP-Schaden
   - ggf. sofortige Druckwelle (apply_pressure_wave)

4. Property-Caches invalidieren

5. Energiekanäle (inkl. Druck) an Nachbarn diffundieren
```

Anders als im ursprünglichen Entwurf gibt es keinen separaten, global entkoppelten „Belastung berechnen"/„Schaden anwenden"-Schritt – das läuft pro Objekt innerhalb von `tick()`. Decay ist ebenfalls kein eigener später Schritt, sondern Teil des jeweiligen Property-`tick()`.

---

# Weitere Subsysteme (nicht im ursprünglichen Design beschrieben)

* **`world/world_object.gd`** – zentrale Basisklasse für alles, was Entity+Substance an eine Zelle bindet (Diffusion, Energie-Stress, Reibung/Traktion).
* **`world/air_object.gd`** – unsichtbares Umgebungsmedium in jeder Zelle.
* **`world/ambient.gd`** – globaler Basiswert für Umgebungstemperatur.
* **`world/biomes/biome.gd`, `experimental_biome.gd`** – bildet GridMap-Tile-IDs auf Substanznamen ab (aktuell nur `ExperimentalBiome`: Tile 0→grass, 8→kindling, 22→water).
* **`world/ground/*`** – lädt pro Substanz dynamisch Shader/Textur; `Grass` als eigener WorldObject-Typ.
* **`world/debug_overlay.gd`** – Mit `D`-Taste umschaltbare Rohwert-Anzeige aller Achsen pro Zelle (Thermal/Pressure/Electrical/Arcane/Structure/Conduction/Impulse).
* **`world/views/temperature_view.gd`, `pressure_view.gd`** – spielerseitig sichtbare In-World-VFX (Hitzeflimmern, Druckwellen-Mesh), unabhängig vom Debug-Overlay; werden erzeugt, sobald eine Property erstmals verändert wird.
* **`world/impulse_indicator.gd`** – Partikel-Visualisierung der Impuls-Richtung/-Stärke pro Zelle.
* **`ui/health_bar.gd`** – schwebende HP-Anzeige über Charakteren.
* **`ui/spell_marker.gd`** – 3D-Zielmarkierung für Casts.
* **`ui/versus_hud.gd`** – Spieler-gegen-Gegner-HUD (Tode, Cooldown-Ringe pro Cast, Respawn-Timer).
* **`ui/title_menu.gd`** – Titelbildschirm, führt zur Build-Auswahl.
* **`core/resource_manager.gd`** – Autoload, lädt gemeinsame Szenen (Ground, Spell-Marker, Property-Views) vor.
* **`core/isometric_camera_3d.gd`** – folgt mehreren Zielen (Zentroid), inkl. Sonderfall für tote Spieler.
* **`core/player_spawner.gd`** – spawnt nur Spieler mit konfiguriertem Build, verwaltet Respawn-Timer.

---

# Designprinzipien

* Wenige universelle Zustandsachsen statt fester Elemente.
* Energie besteht aus beliebig vielen Energiekanälen mit identischer Simulationslogik (Druck eingeschlossen).
* Impuls ist ein abgeleiteter Vektor aus Druckgefällen, kein gespeicherter Zustand.
* Materialien definieren ausschließlich Konstanten, keine Speziallogik.
* Reaktionen/Statuseffekte sollen generisch und datengetrieben aus Zuständen entstehen – aktuell ist das nur für Brennen und Belastungsschaden umgesetzt, der Rest bleibt Designziel.
* Schaden ist eine Folge der Simulation und kein direkter Zaubereffekt – gilt auch für Gegnerangriffe.
* Der Spieler personalisiert Zauber pro Taste über die freie Achsenwahl (Energie/Druck/Struktur/Leitung) und über Modifikatoren (Form/Reichweite/Energietyp/Zusatzeffekt).
* Neue Materialien und Energiekanäle sollen sich automatisch in das bestehende System integrieren, ohne zusätzliche Speziallogik – neue Modifikatoren erfordern aktuell noch manuelle Einträge in `modifier_availability.json` und in den jeweiligen Cast-Klassen.
