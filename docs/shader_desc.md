```md
# SimulationSurface Shader – Arcane Instability
## Universeller Material- und Simulations-Shader (Implementationsspec)

---

## 0. Ziel des Shaders

Dieser Shader visualisiert eine vollständig datengetriebene Simulation auf einem Grid.

Er ersetzt klassische Material- und Effekt-Logik durch ein einziges konsistentes System.

Der Shader gilt für:

- Boden
- Wände
- Objekte
- Gegner (optional gleiche Visualisierungsschicht)

Er enthält **keine Material-Spezialisierung** (kein “Feuer-Shader”, kein “Stein-Shader”, kein “Blitz-Shader”).

Alle Unterschiede entstehen ausschließlich durch:

- Materialparameter
- Simulationswerte
- prozedurales Noise

---

## 1. Datenmodell

---

### 1.1 Vertex-Daten

Jedes Fragment basiert auf:
- worldPosition (vec3)
- normal (vec3)
- tangent (optional)
- uv (optional)

---

### 1.2 Materialdaten (uniform pro Objekt)

Diese Werte definieren nur die “physische Oberfläche”, nicht den Zustand:

```

baseColor (vec3)
roughness (float)
metallic (float)

noiseScale (float)

edgeStrength (float)

emissionStrength (float)

wobbleAmount (float)

crackThreshold (float)

```

---

### 1.3 Simulationsdaten (Grid-Zelle)

Diese Werte kommen aus einer Grid-Struktur (Texture / Buffer):

```

energy        [-1 .. +1]
impulse       [0 .. 1]
structure     [0 .. 1]
conductivity  [0 .. 1]

```

Interpretation:

- energy: thermische / magische Energie
- impulse: kinetischer Schock / Bewegung
- structure: Materialintegrität
- conductivity: Ausbreitung von Energie/Impuls

---

## 2. Architekturprinzip

Der Shader besteht aus einer festen Pipeline:

```

1. Grid Lookup
2. Base Material
3. Procedural Noise
4. Energy Layer
5. Impulse Layer
6. Structure Layer
7. Conductivity Layer
8. Edge Layer
9. Lighting

```

Jeder Layer ist unabhängig und additiv kombinierbar.

---

## 3. Grid Lookup

### Zweck

Bestimme die Simulation für die aktuelle Weltposition.

### Berechnung

Die Welt-Position kommt auf der GridCell selbst.

---

## 4. Base Material Layer

### Ziel

Erzeugt eine neutrale, texturfreie Grundoberfläche.

### Algorithmus

```

noise = fbm(worldPosition * noiseScale)

baseColor = baseColor * (0.85 + 0.15 * noise)

```

---

## 5. Edge Layer (Lesbarkeit / Stil)

### Ziel

Technischer, leicht “holografischer” Look.

### Formel

```

fresnel = pow(1 - dot(viewDir, normal), 3)

color += fresnel * edgeStrength

```

Optional:
- leichtes Rim Light (weiß/blau)

---

## 6. Energy Layer

### Ziel

Visualisiert Energie ohne klassische Partikeleffekte.

---

### Aufteilung

```

heat = max(sim.energy, 0)
cold = max(-sim.energy, 0)

```

---

### Hitze

```

color = lerp(color, white, heat * 0.25)

emission += heat * vec3(1.0, 0.4, 0.1)

```

Effekt:
- Glühen
- Aufhellung
- warme Emission

---

### Kälte

```

color = lerp(color, vec3(0.6, 0.8, 1.0), cold)

roughness += cold * 0.2

```

Effekt:
- bläuliche Tönung
- matte Oberfläche

---

## 7. Structure Layer (Risse / Integrität)

### Ziel

Zustand “Brüchigkeit” sichtbar machen.

---

### Berechnung

```

crackAmount = 1 - sim.structure

```

---

### Muster (Pflicht: prozedural)

Verwende eines:

- Voronoi
- Worley Noise
- Hash Grid

---

### Beispiel

```

cells = voronoi(worldPosition * 3.0)
mask = smoothstep(crackThreshold, 1.0, crackAmount)

```

---

### Anwendung

```

color *= (1 - mask * cells)

normal += noiseNormal * mask * 0.5

```

Effekt:
- Risse erscheinen
- Oberfläche bricht visuell auf

---

## 8. Impulse Layer (Dynamik)

### Ziel

Kurzzeitige mechanische Reaktion.

---

### Vertex Displacement (Pflicht)

```

vertexPosition += normal * sim.impulse * noise(worldPosition * 10)

```

---

### Fragment Variation (optional)

```

color += sin(time * 10 + worldPosition) * sim.impulse * 0.1

```

Effekt:
- Zittern
- Schockwellengefühl
- Material “lebt”

---

## 9. Conductivity Layer (Energiefluss)

### Ziel

Darstellung von Ausbreitung entlang des Materials.

---

### Wellenfunktion

```

wave =
sin(time * speed + worldPosition.x * 8 + worldPosition.y * 8)

pulse = wave * 0.5 + 0.5

```

---

### Anwendung

```

emission += sim.conductivity * pulse * vec3(0.2, 0.6, 1.0)

```

Effekt:
- wandernde Lichtadern
- “magische Leitung” im Material

---

## 10. Lighting Model

Minimalistisches PBR oder pseudo-PBR:

Pflicht:

- diffuse lighting
- simple specular highlight
- emissive additive blending

Optional:

- rim lighting boost
- screen-space AO influence

---

## 11. Final Composition

Reihenfolge ist verpflichtend:

```

Base Material

* Energy Layer
* Conductivity Layer

- Structure Damage

* Edge Layer
* Lighting

```

Vertex:

```

* Impulse Displacement

```

---

## 12. Design Constraints

### Verboten

- keine Material-spezifischen Shader
- keine Texturen für Materialien (nur Noise erlaubt)
- keine Partikel für klassische Elemente (Feuer, Eis, Blitz)
- keine if/else Logik nach Materialtyp
- keine Gameplay-Logik im Shader

---

### Erlaubt

- prozedurales Noise
- Grid Sampling
- additive Farb- und Emissionseffekte
- einfache Vertex-Deformation
- generische physikalische Visualisierung

---

## 13. Erweiterbarkeit

Das System muss modular erweiterbar sein.

Neue Achsen können hinzugefügt werden:

- toxicity
- mana saturation
- gravity distortion
- entropy

Erweiterung erfolgt durch:

- zusätzliche Layer
- keine Änderungen an bestehenden Layern

---

## 14. Zielbild der visuellen Sprache

Die Welt soll wirken wie:

- eine lebende Simulation
- ein physikalisches Feld
- eine wissenschaftliche Visualisierung
- eine “sichtbar gewordene Physik”

Nicht wie:

- klassische Fantasy
- klassisches Low-Poly-Spiel
- particle-heavy VFX system

---

## 15. Kernidee in einem Satz

Der Shader visualisiert keine Dinge.

Er visualisiert Zustände.
```