# Kindwise plant.health to Plantalk adapter mapping

Decision date: 2026-06-20

Sources reviewed:

- https://www.kindwise.com/plant-health
- https://www.kindwise.com/crop-health
- https://www.kindwise.com/pricing
- https://www.kindwise.com/faq
- https://www.kindwise.com/handbook
- https://github.com/flowerchecker/plant-id-examples
- https://github.com/flowerchecker/plant-id-examples/blob/master/response_health_assessment.json

## Provisional request contract

Official example endpoint:

`POST https://api.plant.id/v3/identification`

Future request policy:

Headers:

- `Content-Type: application/json`
- `Api-Key: server-side secret`

Request intent:

- `health: only`
- `language: ko`
- `disease_level: general`
- `similar_images: false`

Image policy:

- first attempt: the remote Supabase condition-photo URL in `images[]`
- fallback if live verification fails: Edge Function downloads the image and sends base64
- Flutter must not send the Kindwise request directly

Requested details should be limited to fields needed for mapping and UI:

- `local_name`
- `classification`
- `common_names`
- `description`
- `treatment`

The exact placement and serialization of `language`, `details`, `disease_level`, and `health` requires confirmation against the current official API reference before F-1D.

## Observed response contract

Official sample shape:

Top-level:

- `access_token`
- `model_version`
- `input`
- `result`
- `status`
- `created`
- `completed`

Health:

- `result.is_healthy.binary`
- `result.is_healthy.probability`
- `result.is_healthy.threshold`

Disease candidates:

- `result.disease.suggestions[]`

Candidate fields:

- `id`
- `name`
- `probability`
- `source`
- `redundant`
- `details.local_name`
- `details.description`
- `details.classification`
- `details.common_names`
- `details.treatment`
- `details.entity_id`
- `details.language`

## Plantalk result mapping

- `access_token`
  -> `ExternalPlantAnalysisResult.providerResultId`

- provider key
  -> `"kindwise_plant_health"`

- analysis type
  -> `PlantAnalysisTypes.conditionCheck`

- `suggestion.probability`
  -> `ExternalPlantConditionEventHint.confidence`

- sanitized Korean summary
  -> `ExternalPlantConditionEventHint.note`

- provider result timestamp, when available
  -> `ExternalPlantAnalysisResult.createdAt`

- provider result
  -> `isMock: false`

Do not store the full provider response in `rawPayload` or `metadata`.

## Critical healthy gate

If `result.is_healthy.binary == true`:

- emit one `health_ok` event
- confidence is `result.is_healthy.probability`
- do not emit low-probability disease suggestions as actionable events
- do not allow a 3% or 10% disease suggestion to outrank a healthy result in `PlantConditionRepresentativeEventSelector`

This rule is required because the provider can return ranked disease suggestions even when `is_healthy.binary` is true.

If `result.is_healthy.binary == false`:

- inspect disease suggestions
- map valid suggestions to PlantAnalysis event types
- preserve up to three useful mapped candidates for the current representative selector
- if no suggestion can be mapped safely, emit `condition_uncertain`

If `is_healthy` is absent or malformed:

- emit `condition_uncertain`
- do not infer health from an empty disease list

## Provisional provider-class mapping

This table is provisional until real Korean fixtures are captured.

| Provider evidence | PlantAnalysisEventTypes value | Notes |
| --- | --- | --- |
| water deficiency / underwatering / drought-related water shortage | `water_needed` | Conservative water-shortage mapping. |
| water excess / overwatering / uneven watering | `overwater_suspected` | Keep separate from water shortage. |
| insufficient light / light deficiency / etiolation | `light_needed` | Requires verified fixture wording. |
| sunburn / excessive sunlight / high-light stress | `too_much_sun_suspected` | Requires verified fixture wording. |
| Animalia / Insecta / mites / visible pest classes | `pest_suspected` | Includes visible pest classes from provider classification/name evidence. |
| fungal / bacterial / viral disease classes | `disease_suspected` | Do not over-specify disease type in the first chat reply. |
| nutrient deficiency / soil-related issue | `soil_check_needed` | Includes soil-related abiotic issue when no more specific event applies. |
| root crowding or explicit repotting recommendation | `repotting_suggested` | Requires explicit provider evidence. |
| temperature, frost, cold, or heat stress | `temperature_stress_suspected` | Requires verified fixture wording. |
| humidity-related stress | `humidity_issue_suspected` | Requires verified fixture wording. |
| explicitly positive growth or new leaf signal | `growth_positive` or `new_leaf_observed` | Choose the more specific event when fixture evidence is explicit. |
| flowering signal | `flowering_observed` | Requires explicit provider evidence. |
| mechanical damage, generic abiotic, senescence, unknown parent classes, or ambiguous unsupported classes | `condition_uncertain` | Use unless a more specific verified child class exists. |

## Message policy

Do not put full treatment instructions directly into the first chat reply.

For the first integration:

- use `details.local_name` as the main localized label when available
- use cautious app-authored wording
- do not present diagnosis as certain
- preserve provider description and treatment only for a later detailed result UI
- do not automatically recommend pesticides or chemicals in chat
- do not expose raw Latin/provider class names when a Korean local name exists

## Suggestion filtering questions requiring live verification

Unresolved:

- exact meaning and correct handling of `suggestion.redundant`
- whether `disease_level=general` eliminates parent/child duplicates
- whether Korean `local_name`, `description`, and `treatment` coverage is sufficient
- whether `is_healthy.binary` should be trusted without an app-level threshold
- whether top three suggestions are stable enough for the current selector
- whether a low-confidence unhealthy result should become `condition_uncertain`
- whether public Supabase Storage URLs are fetched reliably
- exact timeout and maximum image size
- provider error and quota response shapes

## Sanitized fixture policy

Future fixtures may retain only:

- `is_healthy` binary/probability/threshold
- `access_token` replaced with a fake value
- `model_version`
- disease candidate `id`
- `name`
- `probability`
- `redundant`
- `local_name`
- `classification`
- `common_names`
- minimal description/treatment examples needed by parser tests
- `status`

Fixtures must remove:

- real API keys
- user identifiers
- real plant IDs
- original uploaded-image URLs
- exact storage URLs
- full raw responses not needed by tests
- personal metadata
- precise location data
