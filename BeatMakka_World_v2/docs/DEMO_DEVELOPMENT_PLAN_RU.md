# BeatMakka / Frequency Zero — World v2.0
## Технический план демо-района Needle Quay

**Версия:** World Design v2.0 · 24 октября 2026  
**Объект разработки:** один законченный playable vertical slice, а не публикация всего города.  
**Источники:** репозиторий `slafftrosheen/BeatMakka`, его `main` и проверенные описания Alpha 01 на 24.10.2026.  
**Статус этого документа:** новый проектный план. В нём **не утверждается**, что фургон, большая карта и новые парковки уже реализованы в Roblox.

> Основное решение: игроку принадлежит передвижной фургон-студия. Все районы — совместные пространства, но сохранения, открытые звуки, задания, внешность фургона и сюжетный прогресс принадлежат конкретному игроку. Никто не обязан собирать зрителей, покупать предметы или играть с другими, чтобы закончить историю района.

## 1. Краткое решение: что мы строим

**Внешняя игра:** Resonance City — город, где культуры не стало не после войны, а из-за долгого увлечения бесконечным потреблением готового контента. Люди разучились доводить свои проекты до конца, чинить общие места, слушать друг друга и делать музыку сами. Это системная проблема среды и привычек, **не обвинение детей** и не морализаторство. Город жив, не является постапокалиптическими руинами. В нём по-прежнему есть дороги, дома и жители, но витрины закрыты, концертные площадки пустуют и радиосеть почти не передаёт человеческие выступления.

**Цель игрока:** найти звуки, собрать собственные ритмы, возвращать общественные пространства, помогать людям и вновь запускать городские концерты. Игрок впервые получает старый **LoopVan-01** и помощь робота **Mica** (существующий H04). Студия в фургоне заменяет постоянный домашний record shop; существующий магазин/мастерская H06 остаётся **общественной точкой**, а не вторым персональным домом.

**Город:** 11 видимых на старте силуэтов районов, из которых Needle Quay доступен; остальные закрыты «туманом сигнала». Уже доступные базовые жанровые наборы не отбираются только потому, что соответствующий район закрыт. Открытие районов даёт сюжет, уникальные environmental sounds, площадки, модификации и музыкальные приёмы.

**Демо Needle Quay:** связанный маршрут через четыре подготовленные концертные парковки — Dockside Exchange, Repair Alley, Vinyl Market, Breakwater Steps — и финальный клуб The Lantern Room. На каждой парковке есть собственная простая проблема сообщества, самостоятельный короткий соло-путь и возможность добровольного выступления для других игроков. Финальный концерт использует имеющийся шестистадийный chapter encounter.

**Завершённое демо:** новый игрок без подсказок разработчика может прибыть в гавань, получить первые звуки, создать несколько шагов, сохранить бит, проехать/переместиться между четырьмя остановками, провести мини-концерты, войти в клуб, завершить главу, выйти и вернуться без потери прогресса. Социальное участие улучшает эмоцию, но не является обязательным сюжетным gate.

## 2. Зафиксированная исходная база — НЕ реализовать повторно

| Уже существующее в репозитории | Текущее подтверждение и граница |
|---|---|
| Фиксированные 16 пэдов 4×4, 16 шагов, 60–180 BPM, четыре паттерна A–D | Реальные контрактные/Studio проверки; физический multitouch, latency и контроллер требуют отдельной приёмки. |
| Шесть shelf-позиций, версия сохранённых снимков, dirty/saving/restore | Параллельные записи, старые схемы и конфликты проверены в mock/session, **не** в реальной private DataStore. |
| Mica, три находки I01/I02/I03, короткие миссии | Локальные сетевые/многопользовательские проверки есть; исходные звуки не имеют подтверждённого hosted-playback. |
| Courtyard, I05 podium, opt-in snapshot listening, малая концертная очередь | #14 закрыта после 26 проверок на трёх клиентах; **это не настоящий совместный jam** с одновременным редактированием дорожек. |
| Шестистадийный сюжетный концерт и реакция толпы | Логическая последовательность работает, но финальное NPC-art, понятность для новичка, реальная облачная долговечность — открыты. |
| Две персональные workshop bays, четыре finishes `quay/chalk/coral/afterhours`, sign/decor | 20 проверок на трёх клиентах прошли; клиенты видят свои права. Room art и cloud rejoin ещё не приняты. |
| Модульный мир, 74 canonical package IDs, source/optimized GLB candidates | Mapping источников есть, но многие артисты/rigs ещё **не** импортированы постоянно в Studio. Не смешивать DCC-clean и runtime-verified. |
| Десять жанровых китов ×16 и исходный банк на 16 пэдов | Оформлены 160 производных WAV и исходные копии; только **100** жанровых аудио-ID сконфигурированы, **60** ждут загрузки. Исходные 24 (19+4 UI+ambience) ещё ждут cloud import. |

**Источники истины:** [общая Alpha 01 issue](https://github.com/slafftrosheen/BeatMakka/issues/1), [проверка открытых задач](https://github.com/slafftrosheen/BeatMakka/blob/main/docs/PENDING_VERIFICATION_2026-10-24.md), [файлы 11 банков](https://github.com/slafftrosheen/BeatMakka/blob/main/docs/STYLE_STARTER_PACKS.md), [материалы](https://github.com/slafftrosheen/BeatMakka/blob/main/docs/MATERIAL_CUSTOMIZATION.md) и [схема всех 74 пакетов](https://github.com/slafftrosheen/BeatMakka/blob/main/docs/IMPLEMENTATION_COVERAGE.md).

### Отдельные ограничения для релиза

1. Студийный `PlaceId=0/UniverseId=0` и локальное session storage **не подтверждают** работу опубликованной приватной experience. Обязателен отдельный испытательный экземпляр и реальные exit/rejoin receipts.
2. Владелец аудио, permissions, moderation, asset IDs и слуховая приёмка должны быть зарегистрированы. Успешный muted cursor не подтверждает то, что аудитория действительно слышит сэмплы.
3. Нативный импорт постоянных GLB/rigs, сохранение/reopen и артефакты Roblox Studio — отдельный gate. Placeholder и EditableMesh inspection не эквивалентны production mesh.
4. Roblox `AudioRecorder` по проверке проекта от 23 октября был не включён. **Запись микрофона и сохранение живого детского аудио не запланированы.** Виртуальный рекордер назначает только разрешённые авторские/лицензированные звуки игрового мира.
5. Для пользовательских архивов жанров указанное пользователем freeware-право сохранено в манифестах, но не является независимой проверкой лицензии на распространение отдельных сэмплов. До коммерческой публикации права нужно подтвердить.

## 3. Каноническая география и музыкальные районы

Изменение карты не требует одновременно создавать 11 геометрических районов в Roblox. В демо рендерится только `NQ`; остальные присутствуют в **data-driven registry** и UI как заблокированные силуэты. Все названия ниже — новая арт-дирекция, не готовые Place/asset IDs.

| № | DistrictID | Район | Стилевой банк | Отличительный мир / образовательная тема |
|---:|---|---|---|---|
|01|`NQ`|**Needle Quay** / Старая гавань|Original starter|Порт, дерево, металл, вода; ритм, инструмент и труд по общему делу. **Первое демо.**|
|02|`VC`|Velvet Canals / Бархатные каналы|Trip Hop|Дождевые каналы, старые кинобудки, тихие кафе; слушать нюансы и делать паузу.|
|03|`MS`|Motion Square / Площадь движения|Dance|Танцевальная площадь и павильоны; повтор, структура, энергия, уважение к партнёру.|
|04|`BA`|Broken Amp Row / Улица старых усилителей|Grunge|Гаражи и студии; ошибаться, пробовать, находить собственный характер.|
|05|`HS`|Hyperspan / Высотная магистраль|Hard Trance|Эстакады и световые линии; темп, повтор, концентрация и переходы.|
|06|`RB`|Rhythm Borough / Ритм-квартал|Hip Hop|Муралы, дворы, сцены; рифма, семплинг, культурное самовыражение.|
|07|`IF`|Iron Bell Works / Железные мастерские|Industrial|Механизмы, кузницы, башни; физика звука, порядок и безопасность.|
|08|`SA`|Starlight Arcade / Аркада звёздного света|Pop|Кино, витрины, аркады; мелодия, простая форма, эмоции.|
|09|`SS`|Sunward Strand / Солнечный берег|Reggae|Пляж, набережные, свободные площадки; offbeat, слушание и сотрудничество.|
|10|`CW`|Circuit Ward / Схемный район|Techno|Лаборатории и трансформаторы; последовательности, алгоритмы и циклы.|
|11|`AH`|Aurora Heights / Высоты Авроры|Trance|Склоны, обсерватория, вечернее небо; длинная музыкальная форма и изменение темы.|

**Правило визуала:** любой район читается как часть одного города — матовый окрашенный металл, сливочный пластик, дерево, камень, chunky bevels, локальное свечение amber и аккуратный coral. Жанр меняет географию/силуэты/акценты/ритм света, но **не** превращает проект в 11 несовместимых игр.

### Правила начальной карты

- `Locked` — видны только название/контур/характерный силуэт, внутри тёмная заливка, замок, отсутствует возможность телепорта.
- `SignalFound` — появляется фрагмент радиоволны, короткая музыкальная открытка, но новая игровая зона пока недоступна. Предпочтительно доступно после финала NQ.
- `Unlocked` — сервер подтверждает открытие и разрешает перемещение; загрузка/стриминг запускаются только для района, в который игрок реально входит.
- `Restored` — личная глава завершена, локальные признаки жизни и выступления видны игроку; в общем хабе можно показывать нейтральную версию среды, чтобы чужой прогресс не менял твою историю.
- Нет «социального налога»: не требуется пять посетителей, число лайков, донат, публичный чат, непрерывное присутствие в игре или оплата.

## 4. Фургон LOOPVAN-01: не косметика, а главный интерфейс мира

### Четыре режима в одном объекте

| Режим | Что видит игрок | Правила |
|---|---|---|
| **Travel** | Карта района, доступные парковки и анимация переезда | Для демо **переход между фиксированными точками с мягким fade** вместо физической управляемой машины. Не нужен новый сетевой vehicle solver. |
| **Home** | Небольшая персональная внутренняя студия: MK-I, shelf, образцы/коллекция, декор | Вход по кнопке, доступ владельцу; посетители только по явному приглашению в будущем. В первом демо допускается отдельно инстанцируемый интерьер в том же Place, но только если он не ломает isolation. |
| **Sample Lab** | Прослушать → сравнить → назначить на пэд; визуал волны/ритма/огибающей | Начать с preauthored permitted samples. Физический микрофон, произвольный WAV upload и сохранение нового звука с клиента отсутствуют. |
| **Stage** | Разложенная сцена, выступление, дворовая реакция и очередь слушателей | Reuse `ListeningSession` и `StageQueue`, без второй аудиосистемы. При входе других игроков только opt-in. |

### Предложенная конструкция как art target, не техническое ТЗ на существующую модель

- Внешние габариты концепта: **22×9×10 studs**. Передвижение — stop-to-stop, статическое позиционирование и короткий монтаж/сворачивание. Габариты уточнить в Roblox с камерами.
- Площадка стоянки: целевой clearance **28×18 studs**, минимум 6 studs непрерывного свободного маршрута до сцены и основных prompts; проверить на реальном аватаре.
- Откидная сцена, выдвижной тент и радиомачта — отдельные именованные rigid targets; без тяжёлой физики, подвесок и R15-ригования корпуса.
- Материалы: `FZ_MaterialAtlas_v1`, подготовленная четвёрка отделок. Старые ключи `quay/chalk/coral/afterhours` сохраняются как **варианты фургона**, а не переименовываются в невалидные строки.
- Графика: символ музыкальной дорожки/пластинки, накладной декор; UI и игровые команды не выпекаются в текстуру. Владелец может менять заранее одобренные вывески и позиции декора, не писать произвольный текст.

### Миграция record shop → van (без потери текущей функциональности)

`H06` и существующие две workshop bays нельзя просто удалить: они участвуют в `WorldBuilder`, `Rooms`, Mica, station ownership, сохранениях и тестах. Выполнить через **адаптер**:

1. Зафиксировать текущие schema 1/2 fixtures и имена `room`, `finish`, `sign`, `decor`, `StationId`, `RoomStationId`. Прежде чем менять код, воспроизвести сейчас проходящие Contracts/Milestone/Rooms и 3-client checks.
2. `H06` оставить общественным record shop / sound library / repair location. **Убрать из лора роль постоянного дома**, не убирать функциональные I01–I05 или музыкальные станции.
3. Завести `VanService` с сессионными `parkingId`, `isDeployed`, `ownerUserId`, `lifecycleVersion` и серверным разрешением размещения. Не сохранять world position как ownership.
4. Добавить `van` в профиль отдельным, строго валидируемым объектом (finish/sign/decor/unlocks). Для старых профилей маппить `room`-косметику в `van` один раз, **сохранять исходные поля до миграционного acceptance**. Никакой повторной выдачи награды/вещи только по словам клиента.
5. Выбрать явно стратегию схемы (вероятнее `schema=3`) с миграцией, downgrade/rollback protection. Не писать старым сервером несовместимую схему. Нужен staging DataStore и реальный rejoin-тест #10 перед развёртыванием.
6. Декор старой публичной мастерской либо остаётся локальным каталожным демонстрационным набором, либо становится нейтральным. **Содержимое beat shelf не переносится в другой DataStore**: это те же четыре A–D, шесть сохранённых проектов, discoveries и progress.
7. Потребители косметики используют `AppearanceCatalog` и `VanAppearanceRenderer` (новые модули), а не делают неограниченное сканирование модели по именам. Без сдвига 16 пэдов и input targets.

## 5. Четыре парковки Needle Quay: компактная постановка

Каждая точка содержит: `ParkingAnchor`, `VehicleSlot`, `NpcEncounter`, один понятный `QuestRecipe`, `SampleDiscovery` (может быть повторно используемым звуком), `MiniStage`, локальную аудиторию NPC и персональную `RestorationView`. **Парковка открывается не количеством зрителей, а проверенным действием в квесте.**

### P1 · Dockside Exchange — Портовый обмен

**Сцена:** старый причал и погрузочная площадка. Работники хотят запустить грузовой ритм: сигнальный знак, деревянные ящики, небольшой погрузочный механизм. **NPC:** Тори, смотрительница причала (рабочее имя). **Задача:** помочь расставить инструменты по назначению, найти знак I01 `metal_hit`, выстроить простой четырёхдольный цикл и сыграть его хотя бы один такт. **Навык:** порядок, забота о рабочем месте, регулярность. **Музыкальный результат:** металлический акцент поверх kick/hat. **Восстановление:** открывается киоск и слышна первая местная радиопередача. **Co-op:** игроки могут обменяться короткими ответными фразами, но один участник проходит сам.

### P2 · Repair Alley — Переулок мастерских

**Сцена:** вентиляция и ремонтная мастерская. **NPC:** механик Иво (рабочее имя). **Задача:** собрать простую причинно-следственную цепочку «источник → удар → вибрация → звук», найти I02 `vent_thump`, сравнить тембр лёгкого/тяжёлого удара, добавить вариацию к исходному паттерну. **Навык:** эксперименты и доведение до конца, без школьного теста. **Музыкальный результат:** новый low-percussion слой. **Восстановление:** оживает мастерская, её лампы реагируют на бит. **Co-op:** один играет ритм, другой выбирает контрастный ответ (только после отдельного реализованного jam; в демо — поочерёдно через queue).

### P3 · Vinyl Market — Виниловый рынок

**Сцена:** уличный рынок пластинок, местный обмен творческими работами. **NPC:** продавщица Ная (рабочее имя). **Задача:** разложить коллекцию по группам «ритм / бас / мелодия», собрать понятную комбинацию на 16 пэдов и сохранить A/B-версию без потери исходника. Игрок слышит небольшой Trip Hop-мотив как **превью соседнего Velvet Canals**, не обязанный открывать весь район. **Навык:** классификация, взаимопомощь, авторство. **Восстановление:** открывается магазин пластинок. **Co-op:** короткий добровольный back-to-back мини-концерт; не онлайн-рейтинги.

### P4 · Breakwater Steps — Ступени волнореза

**Сцена:** вода, огни маяка и подсказки Мики. **NPC:** Mica с уже каноническим I03 `robot_chirp`. **Задача:** отличить фон/пульс/мелодический сигнал; построить «вопрос-ответ» между двумя паттернами, выдержать паузу и закончить мини-сет. **Навык:** внимательное слушание и терпение. **Музыкальный результат:** роботический короткий отклик, вариация с паузами. **Восстановление:** загорается локальный ретранслятор, появляется финальная подсказка клуба.

### Концерт главы · The Lantern Room

**Антагонист-конфликт:** управляющий клуба **Хранитель Паузы** (не злодей): он боится снова подвести людей и не верит, что дети способны подготовить настоящее выступление. Его нужно не победить громкостью, а **показать подготовленный собственный сет и поддержку местных жителей**. Форма: 6 фаз существующего chapter concert (подготовка, ритм, бас, вариация, участие жителей, финальный подъём) с возможностью разные музыкальные решения. Прежний механизм учитывает персональные сохранённые действия, а не точное совпадение с чужим треком. В конце клуб открывается, район становится `Restored`, радиосеть передаёт первый сигнал в другие районы. Локальная NPC-аудитория работает даже при одном игроке. Социальный концерт — опциональное продолжение.

## 6. Музыкальная система: 11 банков и развитие без paywall

**11 банков = 1 Original starter (16 базовых пэдов) + 10 стилей × 16 = 176 музыкальных слотов.** Число слотов — не число разрешённых/загруженных звуков Roblox. `Original starter` также содержит отдельные discovery-сэмплы, UI cues и ambience — всего подготовлено 24 оригинальных аудиофайла, но не все они отображаются как музыкальные пэды.

**Точный реестр:** Trip Hop, Dance, Grunge, Hard Trance, Hip Hop, Industrial, Pop, Reggae, Techno, Trance. В оригинальном репо частоты/ключи: Trip Hop 90 Am; Dance 140 Am; Grunge 90 Dm; Hard Trance 140 Am; Hip Hop 90 Am; Industrial 140 Am; Pop 90 D major; Reggae 90 Am; Techno 140 Am; Trance 140 Am. Эти BPM — темпы демонстрации паков, **выбор стиля не должен переписывать BPM игрока**.

### Три источника доступных звуков

1. **Starter inventory:** минимум рабочий kick/snare/hat/bass из подготовленного и действительно допущенного набора; жанры представлены сразу через безопасные доступные базовые примеры, но нельзя заставить клиента проигрывать пока не загруженный звук. Демоверсия не должна зависеть от 60 pending genre uploads. Концепт «все основы открыты» не означает «все 176 файлов доступны в Roblox прямо сейчас».
2. **World discovery:** I01/I02/I03 и новые авторские environmental samples принадлежат объектам мира. Виртуальный «рекордер» даёт `Preview → Collect → Assign`, а не микрофонный PCM; записывать личную речь или требовать внешнюю загрузку нельзя.
3. **Sound Lab / Synth basics:** очень ограниченные демонстрации source waveform, огибающей (attack/decay) и частоты; **в первой версии используем заранее подготовленные варианты с известными Audio IDs**. Если Roblox API позволяет применить EQ/gain/PlaybackSpeed к существующему Sound, интерфейс честно показывает, что это изменение воспроизведения, а не создание нового WAV. Настоящий осциллятор/экспорт только после отдельного технического research.

Новые rewards **добавляются** в personal unlocked catalog, не заменяют существующий style-kit mapping, старые saved patterns или canonical discovery IDs. Предусмотреть `sampleVersion`, `sourceKitId`, `grantedByMission`, `licenseState` и отказ, если hosted asset не доступен.

### Звуковая безопасность / rights

Использовать реальные `rbxassetid` только с проверенным владельцем, moderation и grant именно тестовой experience. Никаких guessed IDs. Повторная загрузка при недостоверном исходе запрещена; прослушивание затуханий/onset/pops/clipping/headroom в полных паттернах. Полученные из архивов «freeware» файлы требуют отдельного коммерческого/libraries-redistribution review. Загруженные 100 genre IDs не подтверждают 24 оригинала и остальные 60.

## 7. Мультиплеер: один город, разные истории

- **Сервер** контролирует право парковки, размещение фургона, доступ к личным данным, выдачу находок, сохранение/версию и общие stage-session события.
- **Клиент** рендерит персональную степень восстановления, играет собственное audio, показывает карту, выполняет безопасный preview и поддерживает mute/leave. Простые shared props реплицируются без переноса всех личных прогресс-эффектов на других игроков.
- **Точки парковки** физически общие. Если слот занят, игрок может подождать или использовать реплицируемый личный визуал парковки в заранее определённом соседнем сокете. Нельзя телепортировать чужой фургон или занять чужое место через client-supplied OwnerId.
- **Слушание** только после opt-in. Существующие `ListeningSession`/`StageQueue` переиспользуются; snapshot share ≠ live independent tracks. Функцию jam двух грувбоксов (#15) оставить после демо или реализовать как явно отделённый эксперимент. Не обещать 3–5 одновременных музыкантов до замеров.
- **Аудитория** безопасна для соло: NPC, локальное освещение, статический fallback Effects OFF. Отсутствие других игроков не может заблокировать главы или начисление reward.
- **Детская безопасность:** пользовательские аудиозаписи/произвольные названия/соц-рейтинг не нужны; использовать каталожные тексты и Roblox moderation/permissions, не выводить по умолчанию голосовой чат.

## 8. Предлагаемая архитектура Luau (новые модули)

Пути ниже — **предлагаемые изменения**, не заявления о наличии файлов.

| Новый модуль | Назначение | Должен переиспользовать |
|---|---|---|
| `src/shared/DistrictRegistry.luau` | 11 неизменяемых ID/стилей, unlocked states, metadata | `data/assets.json`, `src/shared/SampleCatalog.luau` |
| `src/shared/ParkingContracts.luau` | схемы серверных команд/ответов, диапазоны, ограничения | существующие `MusicService` remote validation |
| `src/shared/QuestRecipes.luau` | 4 остановки и stepwise rule graph, задания независимо от presentation | `src/shared/FirstPerformanceQuest.luau` |
| `src/server/VanService.luau` | claims, parking ownership, teleport-to-stop, teardown | `src/server/MusicService.luau`, `WorldBuilder` |
| `src/server/WorldProgressService.luau` | personal unlocks, restoration/mission rewards, versioning | `src/server/ProfileStore.luau` |
| `src/server/ParkingSession.luau` | 4 stage anchors с одному общему protocol | `src/server/ListeningSession.luau`, `StageQueue` |
| `src/client/CityMapView.luau` | map/fog/status/no open-place fake | существующий Theme/UI navigation |
| `src/client/VanView.luau` | interior/decor/navigation home UX | `src/client/WorkshopView.luau`, `BeatBookView`, cosmetic catalog |
| `src/client/SoundLabView.luau` | source preview/assignment/EQ concept | `src/client/AudioEngine.luau` |
| `src/client/PersonalRestoration.luau` | visual state per user w/ Effects OFF | `src/client/Restoration.luau`, `WorldFeedback.luau` |

**Не создавать второй** sound transport, editable beat book, save namespace, Mica quest или portable MPC UI. Простейший правильный путь — переназначать существующую MK-I `StationId` на выбранную точку фургона и сохранять единый аудиодвижок. Различать `ParkingId`, `VanId`, `StationId`, `RoomStationId` явно, чтобы не повторить баг collisions идентификаторов.

### Модель данных и команды — эскиз контракта

```luau
-- Concept contract; not copied from current production.
type DistrictState = "Locked" | "SignalFound" | "Unlocked" | "Restored"
type VanAppearance = {
    finish: "quay" | "chalk" | "coral" | "afterhours",
    signId: string, -- catalog-validated only
    decorIds: {string}, -- catalog-validated and bounded
}
type WorldProfileV3 = {
    schema: 3,
    -- all existing A-D, shelf 1..6, quests, discoveries and revisions retained
    van: VanAppearance,
    districtStates: {[string]: DistrictState},
    parkingCompletions: {[string]: boolean},
    unlockedSampleIds: {string},
}
-- Client submits only wanted parking ID. Server resolves actor, range,
-- quest state, lifecycle and any reservation. No client OwnerId/coords.
-- ParkRequest( parkingId: string, expectedVersion: number )
-- ConcertJoin( stageId: string )
-- SampleCollect( discoveryId: string )
```

**Atomicity:** ставить unlock/quest reward только при подтверждённом server-authoritative saved objective и удачном `ProfileStore` commit. Пока cloud write не прошёл, UI обязан говорить «сеанс / не сохранено» и не присваивать долговечную награду. На disconnect нужна idempotent release любых reservations.

## 9. Производственный конвейер моделей и материалов

Новый пакет — концептуальные `V01`–`V09`, **не существующие canonical IDs**: V01 van body, V02 fold-out stage, V03 awning, V04 cabin interior, V05 radio mast, V06 parking anchors (4 sockets), V07 club external, V08 club interior, V09 radio map terminals. Нельзя без миграции присваивать им `H01…H06` или менять значения I01..I05. Каждый новый asset оформлять в register с dimensions, pivot, material slots, collision proxy, LOD, texture budget, owner, status, hashes и Studio import receipt.

**Reuse по приоритету:**

- `H01` MK-I, `H02` динамики, `H03` винил, `H04` Mica, `H05` фонари; `H06` магазин — оставить.
- `M01–M18` — каркас архитектуры, навесы, лестницы, ограждения, пандусы, роллеты, вывески.
- `P01–P16` — рабочая мебель, стулья, crate, полки, кабели, фонари, plant и vent.
- `I01–I05` — discovery/meta/podium канонические; на каждой остановке ставить ссылки или sockets, а не клонировать ID с новыми значениями.
- `W01–W04` — courtyard, waterfront, skyline, bridge backdrop; `T01–T04` материалы, `G01–G04` графика, `A01–A05` реакции, `F01–F04` свет/FX, `U01–U04` UI, `S01–S04` звук.

**Формальная лесенка:** `candidate → DCC-clean → art-approved → Studio-imported → runtime-verified`. Наличие GLB или изображения в артбуке не повышает стадию. Общая существующая палитра `quay/chalk/coral/afterhours`; 1024/512 и layout `FZ_MaterialAtlas_v1`, 4×4 atlas 16 slots; H01 остаётся в 6×1.25×4 studs / ≤4500 assembled triangles. Новая модель фургона получает **свой** обоснованный triangle budget после реального профилирования, не наследует лимит H01.

**Карта — UI и география:** приложенная SVG/PNG представляет художественную схему. Не использовать pixel coordinates плаката как Roblox `Vector3` или floor plan. Дороги физического района и реальный масштаб строятся отдельным whitebox и утверждаются по фактическому проходу/камерам.

## 10. Девять последовательных рабочих батчей для Codex

Это **batched coding**: сначала связанный пакет изменений → локальные статические проверки → один Play/Studio интеграционный заход → фиксы → итоговая сборка. **Не делать build после каждой мелкой правки.** Никаких платных генераций, публикаций или CI; новую private experience использовать только по уже подтверждённым полномочиям и доступной поддерживаемой процедуре.

### B0 · Freeze baseline / контракты и миграционный протокол (P0)

**Объём:** inventory current `main`, сохранить IDs/data/quest regressions, сравнить карты H06/workshops/stages; оформить status matrix всех текущих assets и паков, зафиксировать неразрушающее migration decision. **Изменяемое:** только docs/tests и план интерфейсов. **Tests:** Selene, StyLua, Rojo, existing 46 server groups+5 client suites (если они доступны в текущем Place), content-binding checks. **Done:** зафиксированный baseline без изменения gameplay, compatibility table, список реально импортированных MeshParts, известные blockers #5/#9/#10.

### B1 · District registry + стартовая закрытая карта (P0)

**Объём:** implement registry и `CityMapView`, server opens NQ only; 10 silhouettes locked; region IDs stable; state test and UI in phone/tablet/desktop. **Code:** `DistrictRegistry.luau`, `WorldProgressService.luau` scaffold, `CityMapView.luau`, `WorldBuilder` map anchor. **Done:** карта показывает 11 районов; попытка войти в Locked отвергается сервером; доступ к ранее выбранному звуку не блокируется картой; цвета согласованы с artbook.

### B2 · LoopVan vertical slice + legacy room adapter (P0)

**Объём:** один 3D van proxy, 4 подготовленных parking sockets, личный интерьер, вход/выход, привязка существующей MK-I, аппаратный transport без дублирования; migration dry run cosmetics. **Code:** `VanService`, `VanView`, `WorldBuilder`, profile migration fixtures, ownership tests. **Done:** два игрока обладают разными van instances, не меняют друг друга, не блокируют existing H06, возвращаются к своим A–D/beat shelf, disconnect cleanup idempotent. Реальный cloud persistence — отдельно в B7.

### B3 · Parking anchors + малая сцена (P0)

**Объём:** P1–P4 только как anchors, stage deployment/collapse, limit one active mini-performance per anchor with queue policy; reuse `ListeningSession`/`StageQueue`. **Code:** `ParkingContracts`, `ParkingSession`, stage UI adapter. **Done:** no mandatory listeners, join/mute/leave работают; чужой Session не захватывается, stale action reject, разрыв связи очищает очередь. Three-client Studio integration с 2 performers + listener; latency claims пока не делаем.

### B4 · P1/P2 playable mission chain + virtual sound capture (P0)

**Объём:** перенести существующие I01/I02 в постановочные сцены, quest receipts только после сохранённого бита, source preview and collect, teaching hint 1–2 actions. **Code:** `QuestRecipes`, `WorldProgressService`, `SampleCatalog` adapter, `SoundLabView` minimal. **Done:** один новый игрок создаёт A/B и показывает две находки; незаслуженные reward и client forged sample blocked; Mica quest не потерял eligibility; hearing/effects-off fallback.

### B5 · P3/P4 + личная реставрация (P1)

**Объём:** Vinyl Market, Breakwater, I03, variations/call-response, четыре читаемых локальных состояния, 4 mini concerts with replay; no penalty for leaving. **Code:** `PersonalRestoration` using existing `Restoration`/`WorldFeedback`, locale strings. **Done:** соло четырёх точек ≤ приблизительно 35–50 минут первый проход (цель UX, не измеренный факт); skip/rejoin не теряет earned progress; другой игрок не получает твои stage effects.

### B6 · Finale “The Lantern Room” / радиосигнал (P1)

**Объём:** взять существующий six-phase `ChapterConcert` и привязать его к новому клубу после четырёх parking completions. Конфликт с Хранителем Паузы, NPC crowd/local light, gentle tutorial. **Done:** любой непустой творческий сет с освоенными действиями может закончить главу; существует intro/timeout/leave/rejoin/replay; no popularity gate; исходный Mica courtyard quest and separate voluntary stage regressions pass.

### B7 · Import, private hosted audio, DataStore и визуальная приёмка (release gate)

**Объём:** durable import van/master/club/shelf, UV/pivot/collision/rig receipts, 24 original sounds + remaining styles when quota allows; moderation/grants; new private experience, `PlaceId/UniverseId`, schema-3 cloud migration/rollback; реальный exit/rejoin. **Done:** actual reports and owner records, 14 original image bindings preserved; mesh survives Studio reopen; no profile loss; original musical moments **audible**. **Невыполнимость отдельных upload операций не разрешает фальшивое закрытие** — в отчёте ставить blocked.

### B8 · Real-player playtest, accessibility, perf, demo sign-off (release gate)

**Объём:** 3 независимых новичка (ориентир 7–12 лет и взрослый), хотя бы один реальный touch device + desktop, поездки, stage, sound discovery, rejoin; mobile landscape/portrait UI, FPS/memory/audio input and safe mix. **Done:** реальные сценарии и наблюдения, устранённые critical blockers, пользователь понимает свои музыкальные действия и результат; доступен реверс version migration; чеклист acceptance подписан. Не маркировать демо `ship-ready` раньше этого.

## 11. Обязательная матрица тестирования и критериев

| Сценарий | Автоматические проверки | Человек / устройство |
|---|---|---|
| 11 districts / fog | correct IDs, locked action denied, no hidden world load | карта читается на телефоне, выбор района понятен |
| Van owner / parking | ID/range/death/leave ownership, idempotent cleanup, 2–3 clients | камера, выход, транспорт не мешает touch controls |
| Save & schema migration | schema1→2→3, future schema protected, conflicting/reordered saves, dirty remains | реальный cloud exit/rejoin в private experience |
| 4 story checkpoints | early/duplicate mission action blocked, rewards saved exactly once | ребёнок понимает причинно-следственную связь |
| Sampler/audio | transport state, 16 pads, 4 slots, shelf, Stop/mute/teardown, 600 hits regression | timing/feel/sound balance на устройстве, не muted cursor |
| Mini stages | queue cap/expire, owner only, opt-in, range disconnect | другой игрок может уйти в один клик |
| Finale | six phases, gameplay earned save, no audience required, Effects OFF | читаемая реакция толпы и клуба, эмоциональное завершение |
| Art / meshes | source hashes, pivots, atlas layout, native imported geometry, NoCollide | close/far/dusk look, Studio save and reopen |
| Privacy/rights | no untrusted mic/WAV path; catalog text only; asset grants | kid safety and terms review, rights provenance signed |

**Предлагаемые UX/performance targets для B8, не измеренные показатели:** не менее 30 FPS как минимально приемлемый целевой уровень на согласованном среднем мобильном устройстве с low-quality fallback; touch targets ≥44 logical px; все основные действия доступны без горизонтального скролла 4×4; audio timing/latency измерять на конкретных устройствах, бюджет фиксировать по результатам базового теста, а не объявлять «sample-accurate».

**Regression gate каждого батча:** если изменён один из `AudioEngine`, `ProfileStore`, `ListeningSession`, `MusicService`, `WorkshopView`, `WorldBuilder`, требуется повторный запуск соответствующих старых контрактов. Снимки доказательств всегда помечать источником: source / Studio fixture / real clients / published private cloud / human/device. Не заменять последнее первым.

## 12. Визуальные пакеты для производства

Собрать реестр работ на основе 74 existing IDs и нового `V01–V09` концепта. Минимальный first-demo art acceptance: видимый van shell и открывающийся тент, простая interior, четыре чётких парковочных модуля, четыре NPC silhouettes/expressions, портовый набор вывесок, The Lantern Room фасад/сцена, town-state light before/after, карту в двух состояниях. Анимации без процедурных physics: body lights, cone pulses, Mica head motion, stationary audience emotes, van awning rigid transforms. Ресайкл 4 текущих finishes; не заказывать 11 отдельных стилевых библиотек 3D для первого демо.

**Один источник истины:** `docs/district_register.json` (в этом пакете) + actual `data/assets.json` репозитория. SVG/PNG — дизайн-референс, а не поставка игрового `WorldBuilder`.

## 13. Риски и решения до первого большого coding batch

| Риск | Влияние | Решение |
|---|---|---|
| Cloud ID=0, session-only | невозможно доказать сохранение сюжета | обязательный private test B7; не делать production rollout вслепую |
| Original sounds не загружены | сцены проходят логически, но не слышно игру | `AudioReadiness` gate; первую приёмку проводить с реально доступными IDs; очередь/лимиты проверять актуально |
| Жанровые архивы без издательского текста лицензии | IP риск для сэмплера | получить source/rightsholder explicit permission или заменить на авторские CC0/синтез |
| Permanent meshes не импортированы | стык артбука и игры не подтверждён | native import/reopen receipts, fallback зафиксирован |
| Фургон физически управляется | усложнение сетевой физики/collision | **не делать** free-drive до vertical slice; fixed-location transitions |
| Игроки мешают сюжетному прогрессу | социальный griefing | server personal story isolation, no crowd gate, bounded queue, private stage UI |
| Сложность для новичков | потеря музыкального фокуса | одно действие/один звук/одна цель за раз, нельзя читать стену текста |
| Проект разрастается до 11 районов | демо не доходит до playable finish | создавать картографический registry и 1 finished district, остальное только silhouettes |

## 14. Итоговая Definition of Done для демо

**Нужно одновременно:** (1) первый игрок может играть в первый момент с реальным звуком; (2) фургон и четыре парковки работают без потери текущего инструментального ядра; (3) все парковки имеют осмысленные задания и выступление; (4) финал клуба завершает только NQ, карта показывает будущие районы; (5) работа в одиночку полностью достаточна; (6) посещающие игроки не меняют чужую музыку/прогресс; (7) звук, meshes и cloud сохранения реально приняты; (8) mobile/keyboard, teardown и культурно-возрастная понятность проверены; (9) один полированный проход визуально соответствует утверждённому style board.

**Открытые решения, допускающие быстрое продолжение:** финальное маркетинговое название Resonance City vs BeatMakka можно заменить без смены `DistrictID`; имена четырёх новых NPC рабочие; настоящие 3D габариты van подтвердить в whitebox. **Не открытые для произвольного изменения:** 11 точных банков, 16 pad layout, текущие sample/discovery IDs, четыре сохранённых паттерна и шесть shelf, приватность progress, отсутствие обязательного co-op, общий визуальный язык.

---

**Файлы пакета:** `../maps/BeatMakka_City_Map_Initial_Locked.png`, `../maps/BeatMakka_City_Map_District_Master.png`, `../maps/BeatMakka_Needle_Quay_Demo_Map.png`, `../maps/BeatMakka_LoopVan_Concept.png`, `district_register.json` и `../BeatMakka_World_Artbook_v2_RU.pdf`. Все эти файлы проектные; описания прежних пройденных тестов взяты из документов репозитория, а не выполнены заново при создании артбука.
