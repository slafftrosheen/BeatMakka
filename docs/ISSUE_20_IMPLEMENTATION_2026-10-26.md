# Issue 20 — companion MVP и отдельные DCC-кандидаты

Base и текущий HEAD: **8e8b91f6a5472eb6200599e60932e45a8c9ea56b**. Fetch/fast-forward подтвердил актуальность main до изменений. Batch остаётся локальным и не закоммичен. Issue #20 остаётся открытой.

## Что реализовано

CompanionCatalog/Progress/Service добавляют выбор none/alissia/nikolas, безопасное optional поле companion в schema 2, отдельный limiter, server-owned проекцию подсказок и существующую очередь сохранений. Подсказка учитывает последний действительный stop/парковку и активную Quay/legacy-ветку. Точный уровень запрашивается явно, а текущая задача сбрасывает градацию. Клиент не отправляет награды, координаты, sample IDs или чужой player ID.

CompanionView встроен в существующий журнал. Alone — default; у игрока один локальный follower, скрываемые подсказки, свободная смена выбора. Follower не имеет Humanoid/физических столкновений/звука и не участвует в музыкальном clock. Он скрыт в MK-I и интерьере мастерской; код также содержит guards для Stage/Listening/Jam/ChapterConcert. Generation tokens, respawn root refresh, grounding и ограниченный retry защищают lifecycle.

ProfileStore сохраняет companion вместе с beats, chapter и Quay. Существующая revision/conflict защита не заменена. Restore сохраняет текущий preference и учитывает его при dirty-state. Cloud и legacy fixture acceptance отдельно не заявляются.

## Новые реальные assets

| ID | LOD0 / LOD1 / LOD2 tris | W × D × H studs | Rig / atlas |
|---|---:|---:|---|
| NQ-CMP-ALISSIA | 4088 / 1834 / 598 | 2.665 × 1.558 × 4.153 | 16 joints, 512² |
| NQ-CMP-NIKOLAS | 3436 / 1538 / 496 | 2.394 × 1.169 × 3.846 | 16 joints, 512² |

У каждого — Blender, проверенный GLB, десять фактических source clips, три уровня локальных mesh-файлов, front/side/back/3⁄4, emote-позы, силуэт и props. Source atlases packed в Blender. Это оригинальные стилизованные кандидаты по тексту issue; семейные фотографии, реальные голоса и внешние генераторы не использовались. H04/Mica и существующие NPC IDs не менялись.

**ArtApproved=false.** Сегментная one-bone привязка не объявляется непрерывным skin или финальным лицевым rig. Лицевая анимация не изготовлена. Состояние DCC-кандидата сохраняется, несмотря на наблюдаемый локальный import/playback прототипа.

## Проверено фактически

- Финальный StyLua/Selene batch: 0 errors, 0 warnings, 0 parse errors. Rojo local build успешен; 89 source scripts синхронизированы в выделенную Studio. Загружено 67/67 local art definitions.
- Реальные кнопки выбора и hint toggle работали в существующем журнале; уровни 1→2→3 отображались по запросу. После поездки к P2 context стал NQ-Q04, вместо устаревшего Dockside hint.
- Неверные ID, вложенные flags и extra payload не изменили choice, editVersion, Pattern или Quay. Из 100 burst-запросов выбора принято пять изменений preference; Stop обработан, beat и quest progress не изменились.
- Alone оставил ноль follower-моделей; повторный выбор — одну. У всех 15 частей collision/touch/query отключены, Sound descendants отсутствуют. После Roamer travel и respawn остался один корректно расположенный follower.
- Follower скрывался в MK-I и оставался скрытым после Release внутри интерьера, затем возвращался после QuayReturn. Effects OFF оставлял его видимым без idle head motion, с действительным текстом подсказки.
- Session Beat Shelf save/Restore вернул сохранённый шаг, убрал последующее несохранённое изменение, сохранил Nikolas и дал подтверждённую restore-реакцию wave. Dirty-state стал false.

Эти проверки — ограниченная Studio-инспекция, не новый test suite и не полная QA. Не проведены: физические phone/tablet/gamepad, 2–3 независимых клиента, schema1/2 load fixtures, async cloud conflict, полный Q00–Q12/концерт, точность transport timing и streaming transitions. Guards остальных performance modes просмотрены по исходникам, но отдельно не воспроизведены. Старое предупреждение asset type mismatch для 203785492 осталось; новых companion runtime errors не наблюдалось.

## Передача

- docs/BeatMakka_Companions_Artbook_v2_CANDIDATE_RU.pdf — семь страниц.
- docs/COMPANION_ARTBOOK_RU.md и docs/COMPANION_DEV_HANDOFF_RU.md — арт-дирекция, история, матрица и контракт.
- data/companion-production.v1.json и assets/production/needle-quay/companions/model-manifest.json — размеры, hashes, реальный stage.
- docs/evidence/issue-20-companions — static inspection, runtime observations, UI и оба follower captures.
- output/needle-quay-demo/NeedleQuay-Companions.zip — локальное демо с launcher и 814 checksum-verified companion files.

Никаких Roblox uploads/publishing, Tripo spend, новых dependencies или CI. Перед окончательной приёмкой нужны художественный review, face/animation refinement по выбранному направлению и согласованная отдельная проверка оставшихся acceptance gates.
