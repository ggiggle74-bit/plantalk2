\# Camera C API Candidate Decision



\## Current decision



Do not integrate any external API yet.



Primary registration camera flow must remain protected.



Plantalk should use two separate API roles in the future:



1\. `plant\_identification`

2\. `plant\_analysis`



These two roles must not be mixed.



\## API role split



\### 1. Primary camera API: plant\_identification



Purpose:

\- identify plant species/name during first registration

\- return plant name candidates

\- support plant identity confirmation

\- help the user create a plant profile



Used in:

\- primary registration camera flow



Expected flow:

\- photo select/capture

\- plant identification API returns candidates

\- user selects the correct plant or manually enters it

\- user gives the plant a nickname

\- plant is created

\- representative photo is saved

\- chat starts



Important rule:

\- API must not auto-confirm plant identity

\- user confirmation is required before plant creation



Possible candidates:

\- Plant.id plant identification

\- Pl@ntNet single-species identification



Expected future output:

\- display\_name

\- scientific\_name

\- common\_names

\- confidence

\- source

\- candidate\_rank



Status:

\- Deferred

\- Do not touch current primary registration flow yet



\## 2. Secondary camera API: plant\_analysis / plant\_health



Purpose:

\- analyze an existing plant's condition

\- detect health / pest / leaf damage / light / water signals

\- generate condition\_check memory



Used in:

\- secondary condition-check camera flow



Expected flow:

\- existing plant selected

\- condition-check photo select/capture

\- plant\_photos record is created

\- plant\_analysis boundary receives image input

\- API adapter returns raw analysis

\- normalizer converts it into NormalizedPlantEvent

\- ConditionCheckMemoryPayloadBridge creates memory payload

\- plant\_memories stores condition\_check

\- dialogue context uses condition memory



Primary candidate:

\- Kindwise plant.health



Fallback / experimental candidates:

\- Gemini Vision

\- OpenAI Vision

\- Pl@ntNet disease identification



\## Preferred first future integration candidate



Kindwise plant.health for the secondary condition-check flow.



Reason:

\- built for plant health and disease diagnosis

\- better fit for condition-check photos

\- easier to normalize into Plantalk event buckets

\- does not require touching the primary registration flow



\## Current Plantalk normalized event buckets



\- normal

\- needs\_water

\- low\_light

\- pest\_risk

\- leaf\_damage



\## Dialogue context mapping



\- needs\_water -> water\_needed

\- normal -> general

\- low\_light -> health\_watch

\- pest\_risk -> health\_watch

\- leaf\_damage -> health\_watch



\## Hard constraints



Do not:

\- add HTTP client yet

\- add API keys yet

\- change Supabase schema

\- rewrite main.dart

\- touch primary registration camera flow

\- replace plant representative image from condition-check photos

\- store raw API event types directly in plant\_memories



Condition-check photos should continue to be stored as plant\_photos only.



Representative plant image remains plants.photo\_url.



Condition memory remains plant\_memories.



\## Architecture principle



Plantalk should not use one universal API path for everything.



Primary registration needs plant identity candidates.



Secondary condition-check needs plant condition events.



Therefore:



\- `plant\_identification` is for plant species/name candidates

\- `plant\_analysis` is for condition/health analysis



API output must always pass through a boundary and normalizer before it reaches app memory or dialogue context.

