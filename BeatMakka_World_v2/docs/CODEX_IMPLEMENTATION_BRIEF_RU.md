# BeatMakka World v2.0 — стартовый инженерный batch для Codex

**Запускать после согласования арт-дирекции и документа** `DEMO_DEVELOPMENT_PLAN_RU.md`. Это не существующая issue и не разрешение на paid/publish/upload.

## Цель batch `WORLD2-B0+B1`

Внести в `slafftrosheen/BeatMakka` минимальную **неразрушающую** поддержку карты `Resonance City`: ровно 11 зарегистрированных районов, на старте Needle Quay `Unlocked`, остальные десять `Locked`; экран карты в существующем theme, responsive phone/tablet/desktop; серверный отказ на попытку перемещения в закрытый район; 100% сохранение существующей музыки/слотов/звуковых IDs/Mica/команд/сохранений и всех старых тестов. **Не строить фургон, улицы и 11 миров в этом batch.**

## Перед любыми изменениями

1. Прочесть `README.md`, `AGENTS.md`, `CODEX_START_HERE.md`, `default.project.json`, `src/client/init.client.luau`, `src/client/WorkshopView.luau`, `src/server/WorldBuilder.luau`, `src/server/MusicService.luau`, `src/server/ProfileStore.luau`, `src/shared/BeatBook.luau`, `src/shared/SampleCatalog.luau`, `docs/STYLE_STARTER_PACKS.md`, `docs/PENDING_VERIFICATION_2026-10-24.md` и актуальные issues #1/#3/#5/#6/#8/#9/#10/#11/#12/#13/#15.
2. Сверить точно текущий `origin/main`, не полагаться на названия из этого PDF как на уже созданные Luau-файлы.
3. Сверить реальные 10 style kits и original starter, `data/content-ids.json`, 100 существующих жанровых ID и 14 image IDs. Ни один ID не перезаписывать.
4. Сохранить baseline snapshot и список пройденных контрактных тестов.

## Пакет архитектуры

- `src/shared/DistrictRegistry.luau`: закрытый каталог с ключами NQ/VC/MS/BA/HS/RB/IF/SA/SS/CW/AH, названием, стилевым ключом, unlock prerequisites, art tokens, состояниями. Данные из приложенного `district_register.json` — только дизайн-источник; не считать иллюстративные SVG координаты Roblox world positions.
- `src/server/WorldProgressService.luau` (первый минимальный срез): validate district ID, default first-zone permissions, hard-reject player-supplied access grants and arbitrary teleport destination. Пока нет approved cloud migration, прогресс карты не переносить в production ProfileStore без отдельного gate.
- `src/client/CityMapView.luau`: карта 11 контуров, замки 02–11, открытый NQ, tooltip только по доступному каталогу, закрытая кнопка Travel на заблокированном секторе, явный server-status, разные формы UI на портретном телефоне / коротком landscape / tablet / desktop.
- `src/client/init.client.luau`: одно понятное место открытия/закрытия карты, учёт focus и CoreGui movement controls, без дублированных кнопок и мёртвых модулей.
- `tests/WorldMap.spec.luau` (новый): registry exact count, missing/unknown IDs, client-forged unlock rejects, Locked state consistency, no sneaky teleport, portrait/landscape and input lifecycle.

## Non-negotiables

- Не менять 16 pad targets и 16 steps, 60–180 BPM, A–D, шестиместную shelf, Mica/FirstPerformanceQuest, I01–I05, существующий StageQueue/ListeningSession, material atlas `FZ_MaterialAtlas_v1`, имена cosmetics `quay/chalk/coral/afterhours`, 14 image IDs и current genre IDs.
- Не превращать 10 locked районов в требование для доступа к ранее сохранённым звукам: `regionUnlocked` и `kitAccess` — разные сущности.
- Не вводить внешний child microphone recording, upload PCM, платный контент, произвольные социальные чаты, донат и рейтинги.
- Отказаться от несуществующих native mesh IDs, от placeholder как финального арта, от безусловных сетевых аудио обещаний.

## Coding cadence

**Работать крупным связным батчем**: сперва реализовать registry/server/UI/tests, затем один проход `stylua`, `selene`, `rojo build`, offline binding checks; после этого при разрешённой доступной Studio MCP сделать focused runtime + regression. Не выполнять полный Studio build после каждого переименования/комментария. Сохранять failed receipts и финальный видимый screenshot, обнулять QA fixtures и возвращать Studio в Edit. Следовать AGENTS.md на commit/push и любые cloud actions.

## Acceptance

- 11 названий/банков в точном соответствии с новым реестром и исходниками.
- Начальный вид: один активный NQ / 10 приглушённых замков.
- Любой закрытый district rejects teleport/restore access server-side.
- Никакого изменения содержимого личной библиотеки или чужой сессии.
- Существующие тесты и build не регрессировали.
- Понятная source/runtime evidence matrix + compatibility report. Блокеры физического touch, cloud и hosted audio не скрывать.

**Следующий batch после успешного B0+B1:** `WORLD2-B2` — `VanService` + старый `room` compatibility adapter с подготовленными тестами. Не объединять schema migration в B1 без private DataStore acceptance.
