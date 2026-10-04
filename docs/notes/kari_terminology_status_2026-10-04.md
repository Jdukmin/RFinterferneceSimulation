# KARI (Im Won-gyu et al.) terminology — status (2026-10-04)

**Request:** adopt the terminology of the KARI papers of Dr. Im Won-gyu (임원규) for *interferer* and
*victim* (간섭원 / 피간섭원 equivalents). **Status: not confirmed.** The tooling could not retrieve the
text of those papers, so no term has been attributed to them beyond what is already recorded.

## What is attested (quoted in this repository from the full texts read in earlier phases)

| Phrase | Source | Where recorded |
|--------|--------|----------------|
| "이들 안테나간 RF 간섭 분석을 기초로" — *on the basis of RF interference analysis between these antennas* | 이선익·임원규, SASE 2025 spring (RC-KARI-03) | `docs/reference.md` R5, RPT-P6-02/06 |
| "위성 구조체의 FOV 간섭에 의한 S 대역 안테나의 방사 특성 영향성 분석" | 임원규 외, KSAS 2015 spring pp.832-835 (title) | `docs/reference.md` |

Only the phrases **안테나간 RF 간섭** and **FOV 간섭** are attested. The papers' words for the
interfering and the interfered side are **not recorded** anywhere in the repository.

## What was searched this session (no match)

Public search and fetch (KCI, DBpia, KISTI ScienceON, IPNT, KOSCHI) returned either titles/authors
only or papers by **other** authors: e.g. an S-band RNSS receiver interference study (Inha Univ.), a
COMS Ka-band payload auto-compatibility analysis (Park/Lee/Baek) and a KARI "위성용 안테나 관련 기술"
report (Lee et al.; Im is *not* an author). None is attributed to Dr. Im and none is used as a source.
The three Im papers themselves are not retrievable from public pages by the available tools.

## What the reports use meanwhile

`data/spacecraft/simplified_spacecraft_v1/rfc_terms.csv` holds the labels the level reports print
(간섭원 / 피간섭원, 수신 레벨, 허용 간섭 레벨, 마진, …) with `status = PROVISIONAL_STANDARD_EMC`
(common Korean EMC wording) and the two attested phrases marked `KARI_PAPER_ATTESTED`. Report
headers say the terminology is not yet confirmed. Adopting the papers' words is a **data change in
that CSV**; no code depends on the wording.

## What is needed to close this

One of: the PDF (or text) of the 2025 SASE paper and/or the 2015 and 2023 KSAS papers; or the list of
the papers' terms for interference source, interfered receiver, coupling, received level and
rejection. Then update `rfc_terms.csv` (`status = KARI_PAPER_ATTESTED`, fill `source`).
