# Arcane Instability – Simulationssystem

## Zusammenfassung

**Arcane Instability** ist ein Indie-Action-Roguelike mit simulationsbasierter Magie. Die Spielwelt wird in **3D dargestellt**, aber auf einem **2D-Grid simuliert**. Zauber besitzen keine festen Elemente oder hardcodierten Synergien, sondern manipulieren ausschließlich vier universelle Zustandsachsen:

* **Energie** (bestehend aus mehreren Energiekanälen)
* **Impuls** (Druck, Bewegung, Schockwellen)
* **Struktur** (Härte, Stabilität, Brüchigkeit)
* **Leitung** (Ausbreitung von Energie und Impuls)

Die Energieachse besteht aus beliebig vielen **Energiekanälen**. Jeder Kanal verwendet dieselbe Simulationslogik (Wert, Verfall und Ausbreitung), unterscheidet sich jedoch durch seine Reaktionen.

Beispiele für Energiekanäle:

* Thermisch
* Elektrisch
* Arkan
* (später z. B. Licht, Void, Plasma, Schall)

Neue Energiekanäle können jederzeit hinzugefügt werden, ohne Änderungen am Simulationskern vorzunehmen.

Jede Zelle, jedes Material und jede Entity besitzt Werte auf diesen Zustandsachsen. Materialien definieren zusätzlich lediglich wenige Konstanten wie Entzündungstemperatur, Schmelzpunkt oder Leitfähigkeiten für einzelne Energiekanäle. Es existiert keine materialspezifische Speziallogik.

Zauber verändern ausschließlich Zustände (z. B. **+Thermische Energie** oder **+Impuls**). Sämtliche Effekte entstehen aus wenigen generischen Reaktionsregeln, die für alle Materialien und Entities gelten. Reaktionen verändern wiederum Zustände und können dadurch emergente Kettenreaktionen auslösen.

Gegner verwenden dieselben Zustandsachsen wie Materialien. Zusätzlich besitzen sie **Integrität (HP)** sowie Belastungsgrenzen. Schaden entsteht nicht direkt durch Zauber, sondern wenn Zustände diese Belastungsgrenzen überschreiten.

Die Simulation arbeitet ausschließlich lokal auf benachbarten Grid-Zellen.

Simulationsablauf:

```
Modul-Konfiguration
    ↓
Zustände verändern
    ↓
Zustände ausbreiten
    ↓
Reaktionen auslösen
    ↓
Belastung berechnen
    ↓
Schaden anwenden
    ↓
Decay anwenden
```

Die Steuerung erfolgt per Controller:

* Linker Stick → Bewegung
* Rechter Stick → Cursor
* Vier Schultertasten feuern je eine Modul-Konfiguration ab.

Der Spieler sammelt keine fertigen Zauber, sondern **Module**. Vor oder während eines Runs ordnet er diese Module den vier Schultertasten zu. Für den Spieler wirkt jede Taste wie ein eigener Zauber – intern ist es nur eine Konfiguration derselben Simulationsbausteine.

Das Designziel ist ein **einfach implementierbares, konsistentes und datengetriebenes Simulationssystem**, in dem neue Zauber, Materialien oder Energiekanäle automatisch neue Interaktionen ermöglichen.

---

# Kernsystem

## Welt

* 3D-Darstellung
* 2D-Simulationsgrid
* Simulation erfolgt ausschließlich lokal (Nachbarzellen)

Jede Zelle enthält:

* Material
* Zustände
* optionale Entity

---

# Zustandsachsen

## Energie

Die Energieachse besteht aus mehreren Energiekanälen.

Jeder Kanal besitzt dieselben Eigenschaften:

```text
value
decay
conductivity
```

Beispiele:

```text
ThermalEnergy
ElectricalEnergy
ArcaneEnergy
```

Alle Energiekanäle verwenden dieselbe Simulationslogik.

---

## Impuls

Beschreibt:

* Druck
* Bewegung
* Schockwellen
* Rückstoß

Eigenschaften:

```text
value
decay
conductivity
```

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

Struktur breitet sich normalerweise nicht aus.

---

## Leitung

Beschreibt, wie gut Energie und Impuls auf benachbarte Zellen übertragen werden.

Eigenschaften:

```text
value
```

---

# Materialien

Materialien definieren ausschließlich Konstanten.

Beispiel:

```text
Stone

Structure = 90

ThermalConductivity = 20
ElectricalConductivity = 5
ArcaneConductivity = 30

IgnitionTemperature = none
MeltingTemperature = 250
```

```text
Wood

Structure = 45

ThermalConductivity = 15
ElectricalConductivity = 5
ArcaneConductivity = 40

IgnitionTemperature = 80
```

```text
Metal

Structure = 75

ThermalConductivity = 80
ElectricalConductivity = 100
ArcaneConductivity = 20

MeltingTemperature = 180
```

Materialien besitzen keine Speziallogik.

---

# Module

Der Spieler sammelt keine fertigen Zauber, sondern Module. Module sind in drei Kategorien unterteilt.

## Energiekanäle

Bestimmen, welcher Zustand verändert wird.

```text
Thermisch   → +ThermalEnergy
Elektrisch  → +ElectricalEnergy
Arkan       → +ArcaneEnergy
```

Neue Kanäle können ergänzt werden, ohne den Simulationskern zu ändern.

## Formen

Bestimmen, wie und wo der Zustand angewendet wird.

```text
Strahl      → kontinuierlicher Beam in Cursorrichtung
Projektil   → bewegtes Objekt, das Zustände bei Treffer überträgt
Aura        → Zustand um den Spieler herum
Mine        → platziertes Objekt, löst bei Kontakt aus
Kegel       → breiter Nahbereichskegel
```

## Modifikatoren

Verändern Eigenschaften der Anwendung.

```text
Größer      → erhöhter Radius / Fläche
Schneller   → höhere Projektilgeschwindigkeit / kürzere Wirkzeit
Springt     → Wirkung prallt auf Nachbarzellen ab
Durchdringt → Projektil passiert Entities ohne zu stoppen
Explodiert  → Flächenwirkung bei Aufprall
```

Module kennen keine Materialien. Die Zustandsänderung entsteht intern aus der Kombination.

## Konfiguration

Vor oder während eines Runs weist der Spieler den vier Schultertasten je eine Kombination aus Modulen zu:

```text
Taste   Energiekanal   Form      Modifikator
R2      Thermisch      Strahl    —
R1      Impuls         Welle     —
L2      Struktur       Wand      —
L1      Elektrisch     Kette     —
```

Für den Spieler sind das vier Zauber. Intern ist jede Taste nur eine Konfiguration derselben Simulationsbausteine.

---

# Primäre Reaktionen

| Bedingung                         | Reaktion                         |
| --------------------------------- | -------------------------------- |
| Thermische Energie > Entzündung   | Entzünden                        |
| Thermische Energie > Schmelzpunkt | Schmelzen                        |
| Thermische Energie sehr niedrig   | Erstarren                        |
| Elektrische Energie hoch          | Elektrische Entladung            |
| Arkane Energie hoch               | Arkane Überladung                |
| Impuls > Struktur                 | Zerbrechen                       |
| Impuls hoch                       | Beschleunigen                    |
| Impuls negativ                    | Abbremsen                        |
| Struktur steigt                   | Verfestigen                      |
| Struktur sinkt                    | Erweichen                        |
| Leitung hoch                      | Energie oder Impuls weiterleiten |
| Thermische Energie + Impuls hoch  | Explosion                        |
| Wiederholter Impuls               | Erosion                          |

Alle Reaktionen verändern wiederum Zustände.

---

# Zustandsausbreitung

Für jede Simulationszelle:

```text
Nachbarn prüfen
    ↓
Energie übertragen
    ↓
Impuls übertragen
    ↓
Decay anwenden
    ↓
Reaktionen prüfen
```

Die Simulation erfolgt ausschließlich lokal.

---

# Gegner

Gegner sind normale Entities.

Sie besitzen dieselben Zustände:

```text
Energy Channels
Impulse
Structure
Conduction
```

Zusätzlich:

```text
Integrity (HP)

Energy Tolerance
Impulse Tolerance
```

---

# Schaden

Schaden entsteht ausschließlich durch überschrittene Belastungsgrenzen.

Beispiel:

```text
ThermalEnergy = 120
Tolerance = 90

↓

30 Belastung

↓

Integrity verliert HP
```

Explosion:

```text
Impulse = 150
Tolerance = 100

↓

50 Belastung

↓

Integrity verliert HP
```

Zauber verursachen niemals direkten Schaden.

---

# Statuseffekte

Status sind keine separaten Systeme.

Sie entstehen automatisch aus Zuständen.

| Zustand                          | Effekt                |
| -------------------------------- | --------------------- |
| Hohe thermische Energie          | Brennt                |
| Sehr niedrige thermische Energie | Eingefroren           |
| Hoher Impuls                     | Rückstoß              |
| Niedrige Struktur                | Fragil                |
| Hohe Leitung                     | Leitet Energie weiter |

---

# Controller

Linker Stick

→ Bewegung

Rechter Stick

→ Cursor

Vier Schultertasten feuern je eine Modul-Konfiguration ab.

```text
R2 → Modul-Konfiguration A
R1 → Modul-Konfiguration B
L2 → Modul-Konfiguration C
L1 → Modul-Konfiguration D
```

Beispielkonfiguration:

```text
R2   Thermisch  + Strahl
R1   Impuls     + Welle
L2   Struktur   + Wand
L1   Elektrisch + Kette
```

Modifikatoren (Größer, Schneller, Springt, Durchdringt, Explodiert) können einer Konfiguration hinzugefügt werden und verändern ausschließlich die Anwendungseigenschaften. Die zugrunde liegende Simulationslogik bleibt unverändert.

---

# Simulations-Loop

```text
1. Modul-Konfiguration anwenden (Zustände setzen)

2. Zustände aktualisieren

3. Zustände auf Nachbarn übertragen

4. Reaktionen auslösen

5. Neue Zustände erzeugen

6. Belastung berechnen

7. Integrität (HP) reduzieren

8. Decay anwenden
```

---

# Designprinzipien

* Nur vier universelle Zustandsachsen.
* Energie besteht aus beliebig vielen Energiekanälen mit identischer Simulationslogik.
* Der Spieler sammelt Module, keine Zauber.
* Module kombinieren Energiekanal, Form und optionale Modifikatoren.
* Jede Schultertaste ist eine Modul-Konfiguration – für den Spieler ein Zauber, intern eine Datenkombination.
* Materialien definieren ausschließlich Konstanten.
* Alle Reaktionen sind generisch und datengetrieben.
* Schaden ist eine Folge der Simulation und kein direkter Zaubereffekt.
* Neue Module, Materialien und Energiekanäle integrieren sich automatisch in das bestehende System, ohne zusätzliche Speziallogik.
