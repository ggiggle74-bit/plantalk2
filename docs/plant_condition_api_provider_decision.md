# Plantalk plant-condition API provider decision

Decision date: 2026-06-20

Sources reviewed:

- https://www.kindwise.com/plant-health
- https://www.kindwise.com/crop-health
- https://www.kindwise.com/pricing
- https://www.kindwise.com/faq
- https://www.kindwise.com/handbook
- https://github.com/flowerchecker/plant-id-examples
- https://github.com/flowerchecker/plant-id-examples/blob/master/response_health_assessment.json

## Decision

Select Kindwise plant.health API v3 as the first real condition-analysis provider for the Plantalk MVP.

Keep the existing boundaries:

- plant_identification:
  Pl@ntNet through the existing Supabase proxy

- plant_analysis:
  Kindwise plant.health through a separate future Supabase Edge Function

Do not combine plant identification and health assessment in the first integration.

Use plant.health in health-only mode so the app does not spend another provider call duplicating the existing Pl@ntNet identification slot.

## Why plant.health fits Plantalk

Officially documented facts:

- plant.health is intended for general plants, including indoor plants and ornamentals.
- plant.health has broader houseplant relevance than crop.health.
- plant.health covers 548 health classes including abiotic disorders, pests, fungal diseases, bacterial diseases, viral diseases, and non-harmful look-alikes.
- plant.health supports Korean localized disease content.
- plant.health provides an `is_healthy` result and ranked disease suggestions.
- plant.health can return localized names, descriptions, classifications, common names, and treatment information.
- Health assessment costs one credit.
- New accounts currently receive 100 trial credits.
- The current entry pricing starts at €0.05 per request for 1,000 credits.
- Provider documentation recommends presenting more than one possible cause because plant-health diagnosis is inherently ambiguous.
- Provider guidance recommends close, clear photos of the affected area and approximately 1-2 MP images.

## Why crop.health is not the first provider

Officially documented facts:

- crop.health is optimized for selected edible crops and agriculture.
- Its currently documented scope is 23 crops.
- crop.health has useful crop-specific fields such as severity and symptoms, but those do not compensate for weaker houseplant coverage in the current Plantalk MVP.

Mark crop.health as a possible later provider for a separate edible-plant or gardening mode.

## Alternatives deliberately deferred

- self-hosted/custom disease model
- crop.health
- generic multimodal LLM vision diagnosis

A custom model requires dataset collection, evaluation, hosting, monitoring, and medical/horticultural safety work.

crop.health is too crop-specific for the current Plantalk MVP.

A general LLM must not be treated as the authoritative visual plant-health classifier.

## Security decision

The future provider API key must:

- be stored only as a Supabase Edge Function secret
- never be stored in Flutter source
- never be sent directly from Flutter Web
- never be logged
- never be returned to the client

Proposed future secret name:

`KINDWISE_PLANT_HEALTH_API_KEY`

Proposed future Edge Function name:

`plant-health-assess`

The Flutter app should call only the Supabase Edge Function.

## Cost-control decision

For the first integration:

- use health-only mode
- do not request plant identification from Kindwise
- request only details needed by the adapter
- do not request similar images
- keep one status check equal to one provider credit
- do not automatically call the API from normal chat
- call it only from an explicit user status-check photo flow

## Provider acceptance gates

Implementation must not begin until these are checked:

- [ ] Kindwise account created
- [ ] plant.health API key issued
- [ ] commercial use and terms reviewed
- [ ] Korean response manually verified
- [ ] health-only request verified
- [ ] disease_level=general behavior verified
- [ ] Supabase public photo URL accepted by the provider, or base64 fallback confirmed
- [ ] healthy response captured and sanitized
- [ ] watering-related response captured and sanitized
- [ ] pest or fungal response captured and sanitized
- [ ] poor-image or uncertain response captured and sanitized
- [ ] credit consumption verified in the provider dashboard
- [ ] no raw provider payload persistence confirmed

## Next implementation phases

- F-1B:
  sanitized fixture and pure plant.health response parser

- F-1C:
  plant.health adapter and ExternalPlantAnalysisResult mapping

- F-1D:
  Supabase Edge Function proxy

- F-1E:
  runtime factory wiring and fallback

- F-1F:
  real-photo manual validation
