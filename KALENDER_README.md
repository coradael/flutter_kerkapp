# Kalender Functie

## Installatie

### 1. Database tabel aanmaken

Voer het volgende SQL script uit in de Supabase SQL Editor:

```sql
-- Kopieer en plak de inhoud van: supabase_calendar_events.sql
```

### 2. Pakket installatie

De `table_calendar` package is al toegevoegd aan `pubspec.yaml`. Voer uit:

```bash
flutter pub get
```

## Gebruik

### Kalender openen

De kalender is toegankelijk via de bottom navigation bar (vierde icoon: 📅).

### Evenement toevoegen

1. Open de kalender pagina
2. Klik op de "Nieuw Evenement" knop (rechtsboven)
3. Vul de details in:
   - **Titel** (verplicht)
   - **Beschrijving** (optioneel)
   - **Locatie** (optioneel)
   - **Datum** (verplicht)
   - **Starttijd** (verplicht)
   - **Eindtijd** (optioneel)
   - **Kleur** (kies uit: blauw, rood, groen, oranje, paars)
4. Klik op "Opslaan"

### Evenementen bekijken

- De kalender toont alle evenementen van je tenant
- Klik op een datum om evenementen van die dag te zien
- Evenementen worden onder de kalender weergegeven met:
  - Titel
  - Beschrijving
  - Tijd
  - Locatie
  - Maker

### Evenement verwijderen

- Alleen de maker van een evenement kan het verwijderen
- Klik op het prullenbak icoon bij het evenement
- Bevestig de verwijdering

## Functionaliteit

### Kalender weergave

- **Maand weergave**: Overzicht van de hele maand
- **Week weergave**: Gedetailleerd overzicht van de week
- **Dagweergave**: Focus op één dag

### Kleur codering

Evenementen kunnen verschillende kleuren hebben voor eenvoudige categorisatie:
- 🔵 Blauw: Standaard
- 🔴 Rood: Belangrijk
- 🟢 Groen: Goedgekeurd
- 🟠 Oranje: Te plannen
- 🟣 Paars: Speciaal

### Beveiliging

- Gebruikers kunnen alleen evenementen van hun eigen tenant zien
- Gebruikers kunnen alleen hun eigen evenementen verwijderen
- Alle data wordt beveiligd via Supabase Row Level Security

## Database structuur

De `calendar_events` tabel heeft de volgende kolommen:

- `id`: Unieke identifier (UUID)
- `tenant_id`: Referentie naar tenant
- `user_id`: Referentie naar gebruiker
- `title`: Titel van het evenement
- `description`: Beschrijving (optioneel)
- `event_date`: Datum van het evenement
- `start_time`: Starttijd
- `end_time`: Eindtijd (optioneel)
- `location`: Locatie (optioneel)
- `color`: Kleur voor weergave
- `created_at`: Aanmaakdatum
- `updated_at`: Laatste update

## Toegevoegde bestanden

```
lib/calendar/
├── calendar_page.dart              # Hoofdpagina met kalender weergave
├── calendar_model.dart             # Data model voor evenementen
├── calendar_service.dart           # Service voor database operaties
└── create_calendar_event_page.dart # Pagina voor nieuw evenement

supabase_calendar_events.sql        # SQL script voor database setup
```

## Testen

1. Voer het SQL script uit in Supabase
2. Start de app
3. Navigeer naar de kalender tab
4. Maak een nieuw evenement aan
5. Controleer of het evenement zichtbaar is in de kalender
6. Test het verwijderen van je eigen evenement
