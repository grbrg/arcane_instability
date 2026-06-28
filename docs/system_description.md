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
Zauber
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
* Vier Schultertasten manipulieren direkt die vier Zustandsachsen.

Runen und Upgrades verändern ausschließlich die Form der Anwendung (Strahl, Projektil, Aura, Kegel usw.), nicht die zugrunde liegenden Systeme.

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

# Zauber

Zauber manipulieren ausschließlich Zustände.

## Feuerstrahl

```text
+40 ThermalEnergy
```

## Blitz

```text
+40 ElectricalEnergy
```

## Arkanstoß

```text
+40 ArcaneEnergy
```

## Druckwelle

```text
+60 Impulse
```

## Kristallisieren

```text
+30 Structure
-20 ThermalEnergy
```

Zauber kennen keine Materialien.

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

Vier Schultertasten manipulieren direkt die vier Zustandsachsen.

```text
R2 → Energie
R1 → Impuls
L2 → Struktur
L1 → Leitung
```

Runen und Upgrades verändern ausschließlich:

* Form (Strahl, Projektil, Aura, Mine, Kegel ...)
* Radius
* Stärke
* Dauer
* Reichweite

Die zugrunde liegende Funktion bleibt unverändert.

---

# Simulations-Loop

```text
1. Zauber anwenden

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
* Zauber manipulieren ausschließlich Zustände.
* Materialien definieren ausschließlich Konstanten.
* Alle Reaktionen sind generisch und datengetrieben.
* Schaden ist eine Folge der Simulation und kein direkter Zaubereffekt.
* Neue Zauber, Materialien und Energiekanäle integrieren sich automatisch in das bestehende System, ohne zusätzliche Speziallogik.
